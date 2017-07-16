## @file
#  @brief Реализация класса LWF::ErrorSet
#  @author Mikhail Kirillov


## @class LWF::ErrorSet
#  @brief Класс хранилища ошибок
package LWF::ErrorSet;


# пакеты
use strict;
use warnings;
use YAML::Tiny;
use LWF::Exception::IO;
use LWF::Server::Request;
use LWF::Exception::Runtime;
use LWF::ErrorSet::ApiError;


# данные
my $FILE = $ENV{LWF_HOME} . '/data/errors.yaml';
my $ERRORS = ( YAML::Tiny->new->read( $FILE ) or LWF::Exception::IO->new("Load errors file error ${YAML::Tiny::errstr}" ) )->[0];
my @DATA;
my $CODE = 200;


## @method void init()
#  Метод выполнения инициализации
#  @return void
sub init {
    @DATA = ();
    $CODE = 200;
}


## @method bool has_errors()
#  Метод проверки есть ли ошибки
#  @return истина, если есть ошибки
sub has_errors {
    return scalar(@DATA);
}


## @method void add_error( code, hashref )
#  Метод добавления ошибки в сет
#  @param code - символьный код ошибки
#  @param hashref - ссылка на хеш параметров для сообщения об ошибке
#  @return void
sub add_error {
    my ( $self, $code, $p ) = @_;

    my $res = $ERRORS->{$code} or LWF::Exception::Runtime->new( "bad error code $code" );
    $p ||= {};

    # запись ошибки
    $CODE = $CODE > $res->{http_code} ? $CODE : $res->{http_code};

    my $lng = LWF::Server::Request->lang;
    my $item = { code => $code, text => $res->{$lng} };

    $item->{text} =~ s/\%$_\%/$p->{$_}/sg foreach keys %{$p};

    push @DATA, $item;

    # логирование ошибки
    my $str = $res->{log};
    $str =~ s/\%$_\%/$p->{$_}/sg foreach keys %{$p};
    $str = $code . ': ' . $str;
    my $elog = LWF::Logger->new( $LWF::Logger::EVENT );
    $res->{http_code} >= 500 ? $elog->error( $str ) : $elog->warn( $str );

    return;
}


## @method obj api_error( code, hashref )
#  Метод генерации объекта ошибки API
#  @param code - символьный код ошибки
#  @param hashref - ссылка на хэш параметров
#  @return объект LWF::ErrorSet::ApiError
sub api_error {
    my ( $self, $code, $p ) = @_;

    my $res = $ERRORS->{$code} or LWF::Exception::Runtime->new( "bad error code $code" );
    $p ||= {};

    $CODE = $CODE > $res->{http_code} ? $CODE : $res->{http_code};

    my $lng = LWF::Server::Request->lang;
    my $item = { code => $res->{code}, scode => $code, message => $res->{$lng} };

    $item->{message} =~ s/\%$_\%/$p->{$_}/sg foreach keys %{$p};

    return LWF::ErrorSet::ApiError->new( %$item );
}


## @method arrayref get_errors()
#  Метод получения ссылки на массив ошибок
#  @return ссылка на массив [ { code => 'object.not.found', text => 'Object not found' }, ... ]
sub get_errors {
    return \@DATA;
}


## @method int get_http_code()
#  Метод полуенчия HTTP кода ошибки или 200, если ее нет
#  @return int
sub get_http_code {
    return $CODE;
}


1;
