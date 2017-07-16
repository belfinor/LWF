## @file
#  @brief Реализация класса LWF::Config::Redis
#  @author Mikhail Kirillov


## @class LWF::Config::Redis
#  @brief Класс для работы с конфигурационным файлом редис
#  @see LWF::Config
package LWF::Config::Redis;


use strict;
use warnings;
use utf8;
use YAML::Tiny;
use base 'LWF::Config';


# Методы доступа к данным конфига
__PACKAGE__->make_accessors(

	host           => 'setting/host',            # хост
	port           => 'setting/port',            # порт
	default_ttl    => 'setting/default_ttl',     # TTL по умолчанию
);


## @method obj new(filename)
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @param filename - имя конфигурационного файла, если не задано, то используется дефолтный
#  @return obj - объект Common::Config
sub new
{
	my $class = shift;
	return $class->SUPER::new( 'etc/redis.yaml' );
}


1;

