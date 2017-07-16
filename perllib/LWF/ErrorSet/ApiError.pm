## @file
#  @brief Релаизация класса LWF::ErrorSet::ApiError
#  @author Mikhail Kirillov


## @class LWF::ErrorSet::ApiError
#  @brief Класс ошибки API
package LWF::ErrorSet::ApiError;


# пакеты
use strict;
use warnings;
use base 'LWF';


# методы доступа
__PACKAGE__->make_accessors(
  code => '+code',
  scode => '+scode',
  message => '+message',
);



## @method obj new(hash)
#  Конструктор
#  @param hash - хэш параметров
#  \li code - код
#  \li message - сообщение
#  \li scode - символический код
#  @return obj
sub new {
    my ( $class, %p ) = @_;

    my $self = $class->SUPER::new();

    $self->code( $p{code} );
    $self->scode( $p{scode} );
    $self->message( $p{message} );

    return $self;
}


## @method hashref to_hash()
#  Метод получения хэш представления ошибки
#  return ссылка на хэш { code => -32000, message => 'Server error', scode => 'server_error' }
sub to_hash {
    my $self = shift;
    return { code => $self->code, message => $self->message, scode => $self->scode };
}


1;

