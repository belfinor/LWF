## @file
#  @brief Реализация класса LWF::Server::Controller;
#  @author Mikhail Kirillov


## @class LWF::Server::Controller;
#  @brief Класс контроллера
package LWF::Server::Controller;


# пакеты
use strict;
use warnings;
use LWF::Interface::Sql;
use LWF::DBO;
use LWF::ErrorSet;
use LWF::Server::Response;
use LWF::Server::Response::HTML;
use LWF::Server::Response::JSON;
use LWF::Exception::Runtime;
use MIME::Base64 qw(encode_base64);


# глобальные данные
my $SQL = undef;
my $RESPONSE = 'LWF::Server::Response::HTML';
my $SEQ = 1;
my $REQUEST = 'LWF::Server::Request';
my $PARAMS;


## @method void call(method)
#  Точка входа
#  @return void
sub call
{
    my ( $self, $method, $params ) = @_;
    
    $PARAMS = $params || {};
    
    my $req = 'LWF::Server::Request';
    
    my $elog = LWF::Logger->new( $LWF::Logger::EVENT );
    
    # логируем запрос
    if( my $logger = $self->logger )
    {
        $logger->info( "------------------\n" . $req->remote_addr . ' ' . $req->method . ' ' . $req->full_url . "\n" . $req->r->as_string . "\n\n" . ( $req->content || '' ) );
        
        $elog->info( "apache " . $req->remote_addr . ' ' . $req->method . ' ' . $req->full_url );
        
        $RESPONSE->set_logger( $logger );
    }
    
    $SQL = LWF::Interface::Sql->new or LWF::Exception::Runtime->new( "create sql interface error" );
    
    LWF::DBO->sql( $SQL );
    LWF::ErrorSet->init;
    
    $self->response('default');
    
    $self->response->set_cookie( { name => 'uid', value => $self->make_uid, path => '/', expires => '+10y' } ) 
        unless $req->cookies->{uid};
    
    # проверка доступа
    eval { $self->check_access($method); };
    
    if( $@ || LWF::ErrorSet->has_errors )
    {
        $SQL->rollback;
        
        if( $@ )
        {
            LWF::ErrorSet->add_error( 'internal_error', { details => ref($@) ? $@->log_string : $@ } );
        }
    }
    else
    {
        # выполнение действий
        eval { $self->$method; };
    
        if( $@ || LWF::ErrorSet->has_errors )
        { 
            $SQL->rollback;
            
            if( $@ )
            {
                LWF::ErrorSet->add_error( 'internal_error', { details => ref($@) ? $@->log_string : $@ }  );
            }
        }
        else
        {
            $elog->info( 'apache success' );
            $SQL->commit;
        }
    }

    return $self->response->get_apache_code if $self->response->is_send;
    return $self->response->send_default;
}


## @method obj sql(sql)
#  Метод получения интерфейса к БД
#  @param sql - если залано, то новое значение
#  @return obj
sub sql
{
    my ( $self, $sql ) = @_;
    $SQL = $sql if defined $sql;
    return $SQL;
}


## @method class dbo()
#  Метод поулчения класса для доступа объектам дб
#  @return class
sub dbo
{
    return 'LWF::DBO';
}


## @method class errors()
#  Метод получения хранилища ошибок
#  @return class
sub errors
{
    return 'LWF::ErrorSet';
}


## @method class response(class)
#  Метод получения класс ответа
#  @param class - если задан, то это будет новый класс
#  @retrun class
sub response
{
    my ( $self, $class ) = @_;
    
    if( $class )
    {
        my %TAB = (
            json    => 'LWF::Server::Response::JSON',
            html    => 'LWF::Server::Response::HTML',
            default => 'LWF::Server::Response::HTML',
        );
        
        $RESPONSE = $TAB{ lc $class } || $TAB{default};
    }
    
    return $RESPONSE;
}


## @mehod class request()
#  Метод возврата класса для манипулирования данными запроса
#  @return class
sub request
{
    return $REQUEST;
}


## @method string make_uid()
#  Метод генерации иникального идентификатора пользователя
#  @return string
sub make_uid
{
    my $val = encode_base64( time . '.' . $$ . '.' . rand(32000) . '.' . $SEQ++ );
    $val =~ s/[\r\n]+$//;
    return $val;
}


## @method obj logger()
#  Метод получения логгера, если он есть для контроллера
#  @return obj
sub logger
{
    return;
}


## @method void check_access(method)
#  Метод проверки доступа. ОШибки доступа в LWF::ErrorSet
#  @return void
sub check_access
{
    return;
}


## @method hashref params()
#  Метод поулчения хэша параметров
#  @return ссылка на хэш
sub params {
    return $PARAMS;
}


1;
