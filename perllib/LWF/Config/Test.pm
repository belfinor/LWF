## @file
#  @brief Реализация класса LWF::Config::Test
#  @author Mikhail Kirillov


## @class LWF::Config::Test
#  @brief Конфигурация для тестов
#  @see   LWF::Config
package LWF::Config::Test;


use strict;
use warnings;
use utf8;
use base 'LWF::Config';


# Методы доступа к данным конфига
__PACKAGE__->make_accessors(

    # настройки подключения в базе данных
    protocol              => 'setting/protocol',
    host                  => 'setting/host',
    port                  => 'setting/port',
    
);


## @method obj new()
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @return объект FM::Config::Sql
sub new
{
    my $class = shift;
    return $class->SUPER::new( 'etc/test.yaml' );
}


1;

