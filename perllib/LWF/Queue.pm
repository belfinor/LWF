## @file
#  @brief Релаизация класса LWF::Queue
#  @author Mikhail Kirillov


## @class LWF::Queue
#  @brief Класс работ с очередью
package LWF::Queue;


# пакеты
use strict;
use warnings;
use LWF::PID;
use LWF::Queue::Dispatcher;
use LWF::Queue::Worker;
use LWF::Exception::Runtime;
use LWF::Logger;
use LWF::Interface::Redis;
use vars qw( $LOGGER $WORKERS $Q_DISPATCHER $Q_WORKER);

# глобальные переменные
$WORKERS = 2;
$LOGGER = LWF::Logger->new('queue.log');
$Q_WORKER = $ENV{LWF_PROJECT} . '.queue.';
$Q_DISPATCHER = $ENV{LWF_PROJECT} . '.queue.dispatcher';


## @method void run()
#  Метод запуска очереди
#  @return void
sub run
{
    my $self = shift;
    
    eval { $self->proc; };

    $self->_log_error( 0, $@ ) if $@;
    
    return;
}


## @method void proc()
#  Метод реализующий жизненный цикл очереди
#  @return void
sub proc
{
    my $self = shift;
    
    # проверка запуска
    LWF::PID->init( 'var/temp/queue.pid' );
    
    $self->clean;
    
    $LOGGER->info( "run queue" );
    
    foreach my $num ( 1 .. $WORKERS )
    {
        my $id = fork;
        
        unless( $id )
        {
            if( defined($id) )
            {
                $LOGGER->info( "run worker $num pid=$$" );
                eval { LWF::Queue::Worker->process( $num ); };
                $self->_log_error( 0, $@ ) if $@;
                $LOGGER->info( "stop worker $num pid=$$" );
                exit 0;
            }
            else
            {
                $LOGGER->error( "create worker error" );
                exit 1;
            }
        }
    }

    $LOGGER->info( "run dispatcher pid=$$" );
    eval { LWF::Queue::Dispatcher->process( $WORKERS ); };
    
    $self->_log_error( 0, $@ ) if $@;
    
    $LOGGER->info( "stop dispatcher pid=$$" );
    
    LWF::PID->finish;
    
    $LOGGER->info( "stop queue" );
    
    return;
}


## @method void _log_error(worker,error)
#  Метод логирования ошибки
#  @param worker - номер воркера, если 0, то диспетчер
#  @param errror - объект ошибки
#  @return void
sub _log_error
{
    my ( $self, $worker, $error ) = @_;
    
    if( ref($error) )
    {
        $error = $error->log_string;
    }
    
    $LOGGER->error( $error );
    
    return;
}


## @method void stop()
#  Метод отправки команды на остановку очереди
#  @return void
sub stop
{
    my $self = shift;
    
    my $redis = LWF::Interface::Redis->new;
    $redis->rpush( $Q_DISPATCHER, 'stop' );
    
    return;
}


## @method void clean()
#  метод выполнения очистки
#  @return void
sub clean
{
    my $redis = LWF::Interface::Redis->new;
    
    $redis->del( $Q_DISPATCHER );
    
    foreach ( 1 .. $WORKERS )
    {
        $redis->del( $Q_WORKER . $_ );
    }
    
    $redis->quit;
    
    return;
}


1;
