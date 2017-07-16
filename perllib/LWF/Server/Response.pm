## @file
#  @brief Релаизация класса LWF::Server::Response


## @class LWF::Server::Response
#  @brief Реализация класса ответа сервера
package LWF::Server::Response;


# пакеты
use strict;
use warnings;
use utf8;
use LWF::Exception::IO;
use APR::Table;
use Apache2::RequestRec (); 
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::Const -compile => ':common';
use POSIX qw(strftime);
use LWF::Server::Request;
use CGI::Cookie;


# переменные
my %DATA = ();


## @method void init(r)
#  Метод выполнения иницилизации
#  @return void
sub init {
    my ( $self, $r ) = @_;

    LWF::Exception::IO->( "Apache::Request object excpected" ) unless defined($r);

    %DATA = ( 
        r => $r,
        apache_code => Apache2::Const::OK,
        content_type => 'text/plain',
        cookies => [],
        headers => {
            'x-request-id' => LWF::Server::Request->request_id,
        },
        http_code => 200,
        is_send => 0,
    );

    $DATA{content} = undef;
    
    return;
}


## @method void _send_headers()
#  Метод отправки загловков и куков, которые указаны в хеше headers без Content-Type
#  @return void
sub _send_headers {
    my $self = shift;

    my $r = $DATA{r};
    my $headers = $DATA{headers};
    
    $r->status( $DATA{http_code} );
    $r->content_type( $DATA{content_type} );
    
    # куки
    $r->err_headers_out->add( 'Set-Cookie' => $_ ) foreach ( @{$DATA{cookies}} );
    
    # заголовки
    $r->headers_out->set( $_ => $headers->{$_} ) foreach ( keys %{$headers} );
    
    return;
}


## @method void set_headers(hashref)
#  Метод добавления HTTP заголовков
#  @param hash - ключ имя, значение - значение
#  @return void
sub set_headers {
    my ( $self, $p ) = @_;
    
    my $headers = $DATA{headers};
    
    $headers->{$_} = $p->{$_} foreach ( keys %$p );
    
    return $self;
}


## @method void set_cookie(hashref)
#  Метод установки куки
#  @param hashref - ссылка на хэш параметров
#  \li name - имя куки
#  \li value - значение
#  \li path - путь
#  \li expires - срок окончания действия (+3M), может отсутсвовать
#  @return void
sub set_cookie {
    my ( $self, $p ) = @_;
    
    my @args = ( -name => $p->{name}, -value => $p->{value} );
    push @args, '-expires', $p->{expires} if $p->{expires};
    push @args, ( '-path' => $p->{path} ? $p->{path} : '/' );
    
    push @{$DATA{cookies}},  CGI::Cookie->new( @args );
    
    return $self;
}


## @method void set_content(code)
#  Метод задания тела ответа
#  @return void
sub set_content {
    my ( $self, $content ) = @_;
    $DATA{content} = $content;
    return $self;
}


## @method void set_content_type(str)
#  Метод задания типа ответа
#  @return void
sub set_content_type {
    my ( $self, $content_type ) = @_;
    $DATA{content_type} = $content_type;
    return $self;
}


## @method void set_code(code)
#  Метод задания HTTP кода ответа
#  @return void
sub set_code {
    my ( $self, $code ) = @_;
    $DATA{http_code} = $code;
    return $self;
}


## @method void send()
#  Метод отправки ответа
#  @return void
sub send {
    my $self = shift;
    
    return $DATA{apache_code} if $DATA{is_send};

    $self->_send_headers;
    
    if( defined( $DATA{content} ) )
    {
        $DATA{r}->write( $DATA{content} );
    }
    
    $DATA{is_send} = 1;
    
    my $headers = $DATA{r}->as_string;
    
    $headers = ( split( /\n.?\n/, $headers ) )[1];
    
    $DATA{logger}->info( "------------------\n" . $headers . "\n\n" . ( $self->log_content ? $DATA{content} || '' : "content skipped\n" ) ) if $DATA{logger};
    
    return $DATA{apache_code};
}


## @method void redirect(url)
#  Метод отправки редиректа
#  @param url - адрес редиректа
#  @return void
sub redirect {
    my ( $self, $url ) = @_;
    
    return $DATA{apache_code} if $DATA{is_send};
    
    $DATA{http_code} = Apache2::Const::REDIRECT;
    $DATA{apache_code} = Apache2::Const::REDIRECT;
    
    $self->set_headers( { Location => $url } );
    
    $self->_send_headers;
    
    $DATA{is_send} = 1;
    
    return $DATA{apache_code};
}


## @method bool is_send()
#  Получения флага бала ли отправка данных
sub is_send {
    return $DATA{is_send};
}


## @method int get_apache_code()
#  Метод возврата кода для апача
#  @return int
sub get_apache_code {
    return $DATA{apache_code};
}


## @method void set_logger(logegr)
#  Метод задания логгера
#  @param logger - объект логгера
#  @return void
sub set_logger {
    my ( $self, $logger ) = @_;
    $DATA{logger} = $logger;
    return;
}


## @method bool log_content()
#  Получения статуса логирования контекта
#  @return истина, если нужно логировать
sub log_content {
    return 1;
}


1;
