## @file
#  @brief Реализация класса LWF::Config::Email
#  @author Mikhail Kirillov


## @class LWF::Config::Email
#  @brief Класс для работы с конфигурационным файлом отправщика email
#  @see LWF::Config
package LWF::Config::Email;


use strict;
use warnings;
use utf8;
use YAML::Tiny;
use base 'LWF::Config';


# Методы доступа к данным конфига
__PACKAGE__->make_accessors(

	host           => 'setting/host',            # хост
	port           => 'setting/port',            # порт
        login          => 'setting/login',           # логин
        password       => 'setting/password',        # пароль
        sender         => 'setting/sender',          # отправитель
        log            => 'setting/log',             # лог-файл
);


## @method obj new(filename)
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @param filename - имя конфигурационного файла, если не задано, то используется дефолтный
#  @return obj - объект Common::Config
sub new
{
	my $class = shift;
	return $class->SUPER::new( 'etc/email.yaml' );
}


1;

