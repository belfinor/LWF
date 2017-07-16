## @file
#  @brief Реализация класса LWF::Queue::Job
#  @author Mikhail Kirillov


## @class LWF::Queue::Job
#  @brief Класс задания в очереди
package LWF::Queue::Job;


$VERSION = '1.001';
$DATE    = '2016-09-29';


use strict;
use warnings;
use utf8;
use LWF::Logger;
use base 'LWF::DBO';


__PACKAGE__->table( 'queue' );


__PACKAGE__->pkeys( 'id' );


__PACKAGE__->columns( qw(
  id
  processor
  subqueue
  data
  create_time
  next_try
  counter
  finish_time
) );



## @method self finish()
#  Метод пометки команды как выполненной
#  @return self
sub finish
{
    my $self = shift;
    $self->update( finish_time => \"NOW()" );
    return $self;
}


## @method self start()
#  Метод пометки начала выполнения
sub start
{
    my $self = shift;
    $self->update( next_try => \"NOW() + INTERVAL '15 MINUTE'", counter => $self->counter + 1 );
    $self->sql->commit;
    return $self;
}


## @method void process()
#  Метод выполнения обработки
#  @return void
sub process
{
    my $self = shift;
    
    LWF::Logger->new( $LWF::Logger::EVENT )->info( "run job id=" . $self->id );
    
    $self->start;
    
    my $processor = $self->processor;

    eval "require $processor;";
    
    if( $@ )
    {
        my $val = $@;
        LWF::Logger->new( $LWF::Logger::EVENT )->error( ref($val) ? $val->log_string : $val );
        return;
    }

    my $val = 0;

    eval { $val = $processor->process( $self ); };

    if( $@ )
    {
        $val = $@;
        LWF::Logger->new( $LWF::Logger::EVENT )->error( ref($val) ? $val->log_string : $val );
        $self->sql->rollback; 
        return;
    }
    elsif( !$val ) {
        $self->sql->rollback; 
        return;
    }

    $self->finish;
    $self->sql->commit;
    
    return;
}


1;

