## @file
#  @brief Реализация класса LWF::Server::Controller::API
#  @author Mikhail Kirillov


## @class LWF::Server::Controller::API
#  @brief Контроллер запросов через JSON-RPC
package LWF::Server::Controller::API;


# пакеты
use strict;
use warnings;
use LWF::Server::Request;
use LWF::Logger;
use base 'LWF::Server::Controller';


## @method void call()
#  Точка входа
#  @return void
sub call
{
    my $self = shift;
    
    my $req = 'LWF::Server::Request';
    my $elog = LWF::Logger->new( $LWF::Logger::EVENT );
    
    # логируем запрос
    if( my $logger = $self->logger )
    {
        $logger->info( "------------------\n" . $req->remote_addr . ' ' . $req->method . ' ' . $req->full_url . "\n" . $req->r->as_string . "\n\n" . ( $req->content || '' ) );
        
        $elog->info( "apache " . $req->remote_addr . ' ' . $req->method . ' ' . $req->full_url );
        
        $self->response('json')->set_logger( $logger );
    }
    
    $self->sql( LWF::Interface::Sql->new or LWF::Exception::Runtime->new( "create sql interface error" ) );
    
    LWF::DBO->sql( $self->sql );
    LWF::ErrorSet->init;
    
    $self->response('json');
    $self->response->set_headers( { 'Pragma' => 'no-cache', 'Cache-Control' => 'no-cache' } );
    $self->response->set_cookie( { name => 'uid', value => $self->make_uid, path => '/', expires => '+10y' } ) unless $req->cookies->{uid};
    
    # выполнение действий
    eval { $self->process; };

    if( $@ || LWF::ErrorSet->has_errors )
    { 
        $self->sql->rollback;
        
        if( $@ )
        {
            LWF::ErrorSet->add_error( 'internal_error', { details => ref($@) ? $@->log_string : $@ }  );
        }
    }
    else
    {
        $elog->info( 'apache success' );
        $self->sql->commit;
    }

    return $self->response->get_apache_code if $self->response->is_send;
    return $self->response->send_default;
}


## @method void process()
#  Метод обработки запроса
#  @return void
sub process {
    my $self = shift;

    my $json = $self->request->content_json or return $self->errors->add_error( 'bad_request' );

    if( ref($json) eq 'ARRAY' ) {
        $self->response('json')->send( $self->__process_array( $json ) );
    }
    elsif( ref($json) eq 'HASH' ) {
        $self->response('json')->send( my $val = $self->__process_item( $json ) );
        exists($val->{error}) ? $self->sql->rollback : $self->sql->commit;
    }
    else {
        $self->response('json')->send( { jsonrpc => '2.0', error => LWF::ErrorSet->api_error( 'parse_error' )->to_hash } );
    }
    
    return;
}


## @method arrayref __process_array(arrayref)
#  Метод обработки массива команд
#  @param arrayref - ссылка на массив команд
#  @return ссылка на массив результатов
sub __process_array {
    my ( $self, $list ) = @_;

    my @res;

    foreach ( @$list ) {
        my $val = $self->__process_item( $_ );
        exists($val->{error}) ? $self->sql->rollback : $self->sql->commit;
        push @res, $val;
    }

    return \@res;
}


## @method hashref __process_item(cmd)
#  Метод обработки одной команды
#  @param cmd - ссылка на хэш команды
#  @return hashref - результата
sub __process_item {
    my ( $self, $item ) = @_;

    my $res = { jsonrpc => '2.0' };
    $res->{id} = $item->{id} if defined($item->{id});

    # ошибка в версии протокола
    if( !$item->{jsonrpc} || $item->{jsonrpc} ne '2.0' ) {
        $res->{error} = LWF::ErrorSet->api_error( 'parse_error' )->to_hash;
        return $res;
    }

    # метод не задан
    unless( $item->{method} ) {
        $res->{error} = LWF::ErrorSet->api_error( 'method_not_found' )->to_hash;
    }

    my $routing = $self->routing;

    if( my $call = $routing->{$item->{method}} ) {
        my ( $class, $method ) = $call =~ /^(.+)\:\:([^\:]+)$/;
        eval "require $class;";
        
        if( $@ ) {
            my $str = ref($@) =~ /LWF::Exception/ ? $@->log_string : $@;
            LWF::Logger->new( $LWF::Logger::EVENT )->error( $str ) if $self->logger;
            $res->{error} = LWF::ErrorSet->api_error( 'internal_error' )->to_hash;
            return $res;
        }

        my ( $ret, $err ) = ( undef, undef );

        eval { $ret = $class->$method( $item->{params} ) };

        if( $@ ) {
            my $str = ref($@) =~ /LWF::Exception/ ? $@->log_string : $@;
            LWF::Logger->new( $LWF::Logger::EVENT )->error( $str ) if $self->logger;
            $res->{error} = LWF::ErrorSet->api_error( 'internal_error' )->to_hash;
            return $res;
        }
        elsif( ref($ret) eq 'LWF::ErrorSet::ApiError' ) {
            $res->{error} = $ret->to_hash;
        }
        else {
            $res->{result} = $ret;
        }
    }
    else {
        $res->{error} = LWF::ErrorSet->api_error( 'method_not_found' )->to_hash;
    }

    return $res;
}


## @method hashref routing()
#  Метод получения таблицы роутинга
sub routing {
    return {};
}


1;
