## @file
#  @brief Реализация класса LWF::Config::Sql
#  @author Mikhail Kirillov


## @class LWF::Config::Sql
#  @brief Конфигурация подключения к базе данных
#  @see   LWF::Config
package LWF::Config::Sql;


use strict;
use warnings;
use utf8;
use base 'LWF::Config';


# Методы доступа к данным конфига
__PACKAGE__->make_accessors(

	# настройки подключения в базе данных
	db_connect                 => 'setting/connect',
	db_user                    => 'setting/user',
	db_passwd                  => 'setting/password',
	
);


## @method obj new()
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @return объект FM::Config::Sql
sub new
{
	my $class = shift;
	return $class->SUPER::new( 'etc/sql.yaml' );
}


1;

