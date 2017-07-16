## @file
#  @brief Реализация класса LWF::Server::Request
#  @author Mikhail Kirillov


## @class LWF::Server::Request
#  @brief Класс запроса
package LWF::Server::Request;


# зависимости
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);
use LWF::Exception::IO;
use APR::Table;
use Apache2::RequestRec (); 
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::Const -compile => ':common';
use URI::Escape; 
use Digest::CRC qw(crc32);
use Encode qw(decode_utf8);
use JSON;
use base 'LWF';


# глобагые данные
my %DATA;
my $SEQ = $$;


## @method void init(r)
#  Метод выполнения инициализации
#  @return void
sub init
{
    my ( $self, $r ) = @_;
    
    LWF::Exception::IO->( "Apache::Request object excpected" ) unless defined($r);
    
    %DATA = ();
    
    $DATA{r} = $r;
    $DATA{method} = $r->method;
    $DATA{uri} = $r->uri;
    
    $self->headers;
    $self->content;
    
    return;
}


## @method hashref headers()
#  Метод получения ссылки на хэш заголовков запроса
#  @return ссылка на хэш (заголовок => значение)
sub headers
{
    return $DATA{headers} if $DATA{headers};
    
    my $in = $DATA{r}->headers_in;
    my %h;
    
    foreach my $k ( keys %{$in} )
    {
        my $kn = lc $k;
        $h{$kn} = $in->{$k};
    }
    
    $DATA{headers} = \%h;
    
    return \%h;
}


## @method hashref cookies()
#  Метод получения въодных кук
#  @return ссылка на хэш
sub cookies
{
    my $self = shift;
    
    return $DATA{cookies} if $DATA{cookies};
    
    my $d = $self->headers->{cookie} || '';
    my ( @pairs ) = $d =~ /([^;\s+]+)/sg;

    my %h;

    foreach my $p ( @pairs )
    {
        my ( $k, $v ) = split( /=/, $p, 2 );

        $h{$k} = uri_unescape($v);
    }
    
    $DATA{cookies} = \%h;
    return $DATA{cookies};
}


## @method string method()
#  Метод получения метода запроса
#  @return string
sub method
{
    return $DATA{method};
}


## @method string uri()
#  Метод получения адреса запроса
#  @return строка
sub uri
{
    return $DATA{uri};
}


## @method obj r()
#  Метод получения объекта Apache::Request
#  @return строка
sub r
{
    return $DATA{r};
}


## @method string full_url()
#  Метод получения полного урл с параметрами
#  @return string
sub full_url
{
    return $DATA{uri} . ( $DATA{r}->args || '' );
}


## @method string content()
#  Метод получения тела запроса
#  @return тело запроса
sub content
{
    my $self = shift;
    
    unless( defined $DATA{content} )
    {
        $self->_read_content if $DATA{method} =~ /^(POST|PUT)$/;
    }
    
    return $DATA{content};
}


## @method obj content_json()
#  Метод поулчения контента в виде json
#  @return объект
sub content_json
{
   my $self = shift;

   my $content = $self->content or return;

   my $json;

   eval { $json = decode_json( $content ); };

   return if !$json || $@;

   return $json;
}


## @method data content()
#  Метод получения данных запроса
#  @return данные запроса
sub _read_content
{
    my $self = shift;
    
    my $buffer = '';
    $DATA{content} = '';
    
    while( $DATA{r}->read( $buffer, 4096 ) ) 
    {
        $DATA{content} .= $buffer;
    }

    Encode::decode_utf8( $DATA{content} );
    
    return $DATA{content};
}


## @method string request_id()
#  Метод получения идентификатора запроса
#  @return string
sub request_id
{
    $DATA{headers} ||= {};
    $DATA{headers}->{'x-request-id'} ||= strftime( '%Y%m%d%H%M%S.' . $$ . '.' . $SEQ++ . '.' . rand(32000), localtime );
    return $DATA{headers}->{'x-request-id'};
}


## @method string request_hash()
#  Метод получения хеш-кода запроса
#  @return строка
sub request_hash
{
    my $self = shift;
    $DATA{request_hash} ||= sprintf("%08X",crc32($self->request_id));
    return $DATA{request_hash};
}


## @method string remote_addr()
#  Метод получения IP адреса
#  @return void
sub remote_addr
{
    return $DATA{headers} && $DATA{headers}->{'x-real-ip'} || '127.0.0.1';
}


## @method string lang()
#  Метод получения кода языка
#  @return строка (ru или en)
sub lang {
    my $lng = $DATA{headers} && ( $DATA{headers}->{'accept-language'} || '' ) || '';
    return $lng =~ /ru\-RU/i ? 'ru' : 'en';
}


## @method hashref _decode_args(content)
#  Метод декодирования парамтеров
#  @param content - строка параметров
#  @return hashref (ключ имя парамтера, значение - значение).
sub _decode_args
{
    my( $self, $data ) = @_;
    
    my (@pairs) = split /[&?]/, $data || '';
    my ($param,$value);
    
    my $hash = {};
    
    foreach ( @pairs )
    {
        my ( $param, $value ) = split( '=', $_, 2 );
        $hash->{$param} = decode_utf8(uri_unescape($value));
        $hash->{$param} =~ tr/+/ /;
    }

    return $hash;
}


## @method hashref get()
#  Метод получения GET параметров
#  @return hashref
sub get_args
{
    my $self = shift;
    $DATA{get_args} = $self->_decode_args( $DATA{r}->args ) unless $DATA{get_args};
    return $DATA{get_args};
}


## @method hashref post()
#  Метод извлечения параметров из POST запроса
#  @return ссылка на хэш параметров
sub post_args
{
    my $self = shift;
    $DATA{post_args} = $self->_decode_args( $self->content ) unless $DATA{post_args};
    return $DATA{post_args};
}


1;
