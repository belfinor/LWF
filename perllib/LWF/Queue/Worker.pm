## @file
#  @brief Реализация класса LWF::Queue::Worker
#  @author Mikhail Kirillov


## @class LWF::Queue::Worker
#  @brief Класс воркера очереди
package LWF::Queue::Worker;


# подключемые модули
use strict;
use warnings;
use LWF::Interface::Redis;
use LWF::Interface::Sql;
use LWF::DBO;
use LWF::Queue;


## @method void process(num)
#  Обработчик
#  @param num - номер очереди на вход
#  @return void
sub process
{
    my ( $self, $num ) = @_;
    
    my $sql = LWF::Interface::Sql->new;
    my $redis = LWF::Interface::Redis->new;
    
    LWF::DBO->sql( $sql );

    my $queue = $LWF::Queue::Q_WORKER . $num;
    my $callback = $LWF::Queue::Q_DISPATCHER;
    
    while( 1 )
    {
        my $id = $redis->blpop( $queue, 1 ) or next;
        
        $id = $id->[1];
        
        last if $id eq 'stop';
        
        my $cmd = LWF::DBO->get( 'LWF::Queue::Job', id => $id );
        
        $cmd->process;
        
        $redis->rpush( $callback, $num );
    }
    
    return;
}


1;
