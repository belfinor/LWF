## @file
#  @brief Реализация класса LWF::Server::Response::JSON
#  @athor Mikhail Kirillov


## @class LWF::Server::Response::JSON
#  @brief Класс ответов в формате JSON
package LWF::Server::Response::JSON;


# пакеты
use strict;
use warnings;
use JSON;
use LWF::Exception::IO;
use base 'LWF::Server::Response';


## @method int send( data )
#  Метод отпарвки ответа
#  @param data - ссылка на данные
#  @return число
sub send
{
    my ( $self, $p ) = @_;

    $self->set_content_type( 'application/json; charset=utf-8' );
    
    $self->set_content( to_json($p) );
    
    return $self->SUPER::send;
}


## @method void send_default()
#  Метод топравки ответа по умолчанию
#  @return число
sub send_default
{
    my $self = shift;
    
    if( LWF::ErrorSet->has_errors )
    {
        my $args = { errors => LWF::ErrorSet->get_errors, status => 'fail' };
        
        $self->set_code( LWF::ErrorSet->get_http_code );
        
        return $self->send( $args );
    }
    
    return $self->send( { status => 'success' } );
}


1;
