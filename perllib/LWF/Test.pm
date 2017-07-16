## @file
#  @brief Реализация класса LWF::Test
#  @author Mikhail Kirillov


## @class LWF::Test
#  @brief Класс выполнения теста
package LWF::Test;


# пакеты
use strict;
use warnings;
use utf8;
use LWF::DBO;
use LWF::Logger;
use LWF::ErrorSet;
use LWF::Config::Test;
use LWF::Interface::HTTP;
use LWF::Interface::Sql;
use LWF::Exception::Runtime;
use LWF::Exception::Interface;


# выполнения иницилизации переменных
my $SQL = LWF::Interface::Sql->new or LWF::Exception::Runtime->new( "create sql interface error" );
my $LOG = LWF::Logger->new( $LWF::Logger::EVENT );
my $CFG = LWF::Config::Test->new;


# выполнения инициализации классов
LWF::DBO->sql( $SQL );
LWF::ErrorSet->init;


## @method void test(func)
#  Метод запуска теста
#  @return void
sub test {
    my ( $self, $func ) = @_;
    
    $self->init();
    $func->();
    
    return;
}


## @method obj request(hashref)
#  Метод отпарвки HTTP запроса к тестовому серверу
#  @param hashref - ссылка на хэш параметров, аналогичных LWF::Interface::HTTP 
#  (URL можно писать в виде /test, вместо http://test.ru/test)
#  @return HTTP::Response или undef
sub request {
    my ( $self, $p ) = @_;
    
    my $url = $p->{url} or LWF::Exception::Interface->new( "no url");
    
    if( $url !~ m!https?://! ) {
        $url = '/' . $url if $url !~ m!^/!;
        $url = $self->config->protocol . '://' . $self->config->host . ( $self->config->port ? ':' . $self->config->port : '' ) . $url;
        $p->{url} = $url;
    }
    
    return LWF::Interface::HTTP->request( $p );
}


## @method void init()
#  Метод выполнения инициализации, характерной для проекта
#  @return void
sub init {
    my $self = shift;
}


## @method obj sql()
#  Получения доступа к интерфейсу с базой данных
#  @return LWF::Interface::Sql
sub sql {
    return $SQL;
}


## @method obj logger()
#  Метод полуечния доступа к логгеру
#  @return LWF::Logger
sub logger {
    return $LOG;
}


## @method obj config()
#  Метод получения лобъекта конфигурации
#  @return obj
sub config {
    return $CFG;
}


1;
