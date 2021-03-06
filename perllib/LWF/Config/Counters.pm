## @file
#  @brief Реализация класса LWF::Config::Counters
#  @author Mikhail Kirillov


## @class LWF::Config::Counters
#  @brief Класс для работы с конфигурационным файлом счетчиков
#  @see LWF::Config
package LWF::Config::Counters;


$VERSION = '1.000';
$DATE    = '2016-10-17';


use strict;
use warnings;
use utf8;
use YAML::Tiny;
use base 'LWF::Config';


# Методы доступа к данным конфига
__PACKAGE__->make_accessors(

	host           => 'setting/host',            # хост
	port           => 'setting/port',            # порт
);


## @method obj new(filename)
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @param filename - имя конфигурационного файла, если не задано, то используется дефолтный
#  @return obj - объект Common::Config
sub new
{
	my $class = shift;
	return $class->SUPER::new( 'etc/counters.yaml' );
}


1;

