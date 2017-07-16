## @file 
#  @brief Реализация класса LWF::Interface
#  @author Mikhal Kirillov


## @class LWF::Interface
#  @brief Базовый класс для интерфейсов взаимодействия
#  @details На данный момент не имеет никакой нагрузки но может оказаться полезным в дальнейшем
#  @see LWF
package LWF::Interface;


use strict;
use LWF::Exception::Interface;
use base 'LWF';


# создание методов доступа
__PACKAGE__->make_accessors(
    config => '+config',
);


## @method void _init(hashref)
#  Метод выполнения базовой инициализации для всех интерфейсов
#  @param hashref - хэш параметров
#  \li config - конфиг
#  @return obj
sub new
{
    my ( $class, $p ) = @_;
    
    my $self = $class->SUPER::new($p);
    
    LWF::Exception::Interface->new( "config object expected" ) unless $p->{config};
    
    $self->config( $p->{config} );
    return $self;
}


1;

