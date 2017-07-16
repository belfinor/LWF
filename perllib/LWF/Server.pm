## @file
#  @brief Реализация класса LWF::Server
#  @author Mikhail Kirillov

## @class LWF::Server
#  @brief Класс хендлера серверных запросов
package LWF::Server;


# пакеты
use strict;
use warnings;
use APR::Table;
use Apache2::RequestRec (); 
use Apache2::RequestIO ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Const -compile => ':common';
use LWF::Server::Request;
use LWF::Server::Response;
use LWF::Server::Router;
use LWF::Exception::Runtime;
use LWF::ErrorSet;
use LWF::Logger;
use Apache::DBI;


my $R = undef;


## @method void handler(r)
#  Точка входа
#  @param r - Apache::Request
#  @return void
sub handler
{
    $R = shift;
    
    $R->set_handlers( PerlCleanupHandler => \&cleanup );
    
    return LWF::Server->on_options_request if uc($R->method) eq 'OPTIONS';
    
    my $code;
    my $data;

    eval {
        
        LWF::Server::Request->init($R);
        LWF::Server::Response->init($R);
    
        LWF::ErrorSet->init;

        $data = LWF::Server::Router->process or return LWF::Server->unknown_request;
    };

    if( $@ )
    {
        warn ref($@) ? $@->log_string : $@;
        return Apache2::Const::SERVER_ERROR;
    }

    return LWF::Server->unknown_request unless $data;

    eval {
        my $controller = $data->{controller};
        my $method = $data->{method};
        my $params = $data->{params};

        eval "require $controller;";

        LWF::Exception::Runtime->new( $@ ) if $@;

        $code = $controller->call( $method, $params );
    };
    
    if( $@ )
    {
        warn ref($@) ? $@->log_string : $@;
        return Apache2::Const::SERVER_ERROR;
    }
    
    return $code;
}


## @method int process_options()
#  Метод обработки запроса OPTIONS. Если этот заголовок не обработать, то с jQuery нелзя будет использвоать CROSS-запросы.
#  @return code
sub on_options_request
{
    $R->status( 200 );
    $R->content_type( 'httpd/unix-directory' );
    $R->headers_out->set( 'Access-Control-Allow-Origin' => '*' );
    $R->headers_out->set( 'Access-Control-Allow-Headers' => 'accept, x-custom-parameter, content-type, x-request-id, authorization, accept-language, accept-charset, pragma, user-agent' );
    $R->headers_out->set( 'Access-Control-Allow-Methods' => 'GET, OPTIONS, POST, PUT, DELETE, HEAD' );
    
    return Apache2::Const::OK;
}


## @method void unknown_request()
#  Если появился неизвестный запрос, то возвращаем 404 и и логириуем его
#  @return void
sub unknown_request
{
    my ( $self, %p ) = @_;
    
    my $logger = LWF::Logger->new( $ENV{LWF_HOME} . '/logs/unknown.log' );
    $logger->info( $R->method . ' ' . $R->uri . "\n" . $R->as_string );
    
    return Apache2::Const::NOT_FOUND;
}


## @fn void cleanup(request)
#  Метод выполнения отката
#  @param request - объект запросов
sub cleanup
{
    Apache::DBI->cleanup;
}


1;
