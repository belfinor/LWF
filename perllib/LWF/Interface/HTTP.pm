## @file
#  @brief Реализация класса FM::Interface::HTTP
#  @author Mikhail Kirillov


## @class LWF::Interface::HTTP
#  Базовый класс для HTTP-шных интерфейсов
package LWF::Interface::HTTP;


# используемые модули
use strict;
use IO::Socket::SSL;
use LWP::UserAgent;
use Time::HiRes;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;
use base 'LWF';


# разрешим использовать самоподписанные SSL сертификаты
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

IO::Socket::SSL::set_ctx_defaults(
	SSL_verifycn_scheme => 'WWW',
	SSL_verify_mode => 0,
);


# глобальные переменные
my @AGENTS = (
    'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36',
    'Opera/9.80 (Windows NT 6.1; WOW64; U; ru) Presto/2.10.289 Version/12.00',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 YaBrowser/13.10.1500.9323 Safari/537.36',
);


my $COOKIES = HTTP::Cookies->new;



## @method string make_agent_name()
#  Метод получения случайного имени клиентского агента
#  @return string
sub make_agent_name {
    return $AGENTS[ time % scalar(@AGENTS) ];
}


## @method string make_request_id()
#  Метод генерации идентификатор запроса, если он не передан
#  @return string
sub make_request_id {
    return ( Time::HiRes::gettimeofday =~ /(\d+\.?\d{0,3})/ )[0] . '.' . rand(32000) . '.' . $$;
}


## @method res request(hashref)
#  Метод отправки HTTP запроса
#  @param hashref - ссылка на хэш параметров
#  \li agent - имя агента
#  \li credentials - реквизиты доступа, ссылка на массив [netlock,real,]login,password
#  \li url - адрес
#  \li method - метод
#  \li headers - заголовки
#  \li content - тело запроса
#  \li timeout - таймаут, если нет 10 секунд
#  \li use_cookies - использовать куки
#  \li use_request_id - флаг использования идентификатора запроса
#  @return HTTP::Response или ничего
sub request {
    my ( $self, $p ) = @_;
    
    $p ||= {};
    
    my $ua = LWP::UserAgent->new;
    
    $ua->agent( $p->{agent} || $self->make_agent_name );
    $ua->cookie_jar( $COOKIES ) if $p->{use_cookies};
    $ua->credentials( @{$p->{credentials}} ) if $p->{credentials};
    $ua->timeout( $p->{timeout} || 10 );
    
    my $req = HTTP::Request->new( $p->{method} => $p->{url} );
    
    $req->content( $p->{content} ) if $p->{content} && $p->{method} =~ /^(POST|PUT)$/;
    
    $p->{headers} ||= {};
    $req->header( $_ => $p->{headers}{$_} ) foreach ( keys %{$p->{headers}} );
    $req->header( 'x-request-id' => $self->make_request_id ) if $p->{use_request_id};
    $req->content_type( $p->{headers}{'Content-Type'} ) if $p->{headers}{'Content-Type'};
    
    my $res = undef;
    eval { $res = $ua->request($req); };
    
    return $res;
}


## @method hashref cookies()
#  Метод поулчения доступа к текущим кукам
#  @return ссылка на хэш
sub cookies {
    return $COOKIES->{COOKIES};
}


1;
