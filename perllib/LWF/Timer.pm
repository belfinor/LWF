## @file
#  @author Mikhail Kirillov
#  @brief Реализация класса LWF::Timer


## @class LWF::Timer
#  @brief Класс таймера
package LWF::Timer;


$VERSION = '1.001';
$DATE    = '2016-09-29';


# используемые пакеты
use strict;
use utf8;
use Time::HiRes;
use base 'LWF';


# определения структуры объекта
__PACKAGE__->make_accessors( 
    sec  => '+sec',
    msec => '+msec',
);


## @method obj new()
#  метод создания таймера
#  @return obj
sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new();
    
    my ( $s, $m ) = Time::HiRes::gettimeofday;
    
    $self->sec($s);
    $self->msec($m);
    
    return $self;
}


## @method double time()
#  метод получения времени с момента создания таймера с точностью до микросекунд
#  @return double 
sub time {
    my $self = shift;
    
    my $old = $self->sec * 1000000 + $self->msec;
    
    my ( $s1, $m1 ) = Time::HiRes::gettimeofday;
    
    my $new = $s1 * 1000000 + $m1;
    
    return ( $new - $old ) / 1000000.0;
}


## @method bool less()
#  Метод проверки, что еще не наступил указанный интервал времени
#  @return истина, если не наступил
sub less {
    my ( $self, $val ) = @_;
    return $self->time < $val;
}


1;

