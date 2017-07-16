## @file 
#  @brief Реализация класса LWF::Queue::Dispatcher
#  @author Mikhail Kirillov


## @class LWF::Queue::Dispatcher
#  @brief Класс диспетчера задач
package LWF::Queue::Dispatcher;


# пакеты
use strict;
use warnings;
use LWF::Interface::Sql;
use LWF::Interface::Redis;
use List::Util qw(shuffle);
use LWF::Queue;


## @method void process(workers)
#  Обработчик
#  @param workers - число воркеров
#  @return void
sub process
{
    my ( $self, $workers ) = @_;
    
    my $sql = LWF::Interface::Sql->new;
    $sql->autocommit(1);
    my $redis = LWF::Interface::Redis->new;

    my $used = 0;
    my @vals = map { 0 } ( 1 .. $workers );

    while(1)
    {
        my $has_action = 0;
        
        # извлекаем следующие команды, если они есть и отправляем их воркерам
        if( $used < $workers )
        {
            my $query = q[
            SELECT q.id
            FROM queue q
            LEFT JOIN queue qh ON ( qh.id < q.id ) AND 
                                  ( qh.finish_time IS NULL ) AND 
                                  COALESCE( ( q.subqueue = qh.subqueue )::BOOLEAN, false )
            WHERE 
                ( q.finish_time IS NULL ) AND 
                ( q.next_try <= NOW() ) AND 
                ( q.id NOT IN (] . join( ',', @vals ) . q[) ) AND
                ( qh.id IS NULL )
            ORDER BY q.id
            LIMIT ] . ( $workers - $used );

            foreach my $id ( map { $_->{id} } @{$sql->select_list( $query )} )
            {
                if( my $num = $self->reg_id( \@vals, $id ) ) {
                    $redis->rpush( $LWF::Queue::Q_WORKER . $num, $id );
                    $has_action = 1;
                    $used++;
                }
            }
        }

        # ожидаем ответа
        if( my $val = $redis->lpop( $LWF::Queue::Q_DISPATCHER ) )
        {
            if( $val eq 'stop' )
            {
                $redis->rpush( $LWF::Queue::Q_WORKER . $_, 'stop' ) foreach ( 1 .. $workers );
                last;
            }

            $used--;
            $vals[$val-1] = 0;
            $has_action = 1;
        }

        # если нет действий, тогда пропуск
        sleep 2 if !$has_action;
    }
    
    $sql->autocommit(0);
    
    return;
}


## @method int reg_id(arayref,id)
#  Метод регистрации выполняющийся команды
#  @param arrayref - ссылка на массив команд
#  @param id - идентификатор команды
#  @return номер очереди
sub reg_id
{
    my ( $self, $vals, $id ) = @_;
    
    my @nums = ( 0 .. scalar(@{$vals}) - 1 );
    
    foreach my $i ( shuffle @nums )
    {
        if( $vals->[$i] == 0 )
        {
            $vals->[$i] = $id;
            return $i + 1;
        }
    }
    
    return;
}


1;
