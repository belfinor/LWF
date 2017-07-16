## @file
#  @brief Реализация класса LWF::Time
#  @author Mikhail Kirillov


## @class LWF::Time
#  @brief Класс работа с датой и временем
package LWF::Time;


$VERSION = '1.001';
$DATE    = '2016-12-11';


# пакеты
use strict;
use warnings;
use POSIX qw(strftime);


## @method string timestamp_to_rudate(tm)
#  Метод получения даты dd.mm.yyyy из yyyy-mm-dd hh:mm:ss . Если входные данные неверны, тогда undef
#  @param tm - timestamp
#  @return строка с датой
sub timestamp_to_rudate {
    my ( $self, $tm ) = @_;
    
    if( $tm =~ /^\s*(\d\d\d\d)\-(\d\d)\-(\d\d)\s+(\d\d\:\d\d\:\d\d)\s*$/s )
    {
        return "$3.$2.$1";
    }

    return;
}


## @method string timestamp_to_rutime(tm)
#  Метод получения времени dd.mm.yyyy hh:mm из yyyy-mm-dd hh:mm:ss . Если входные данные неверны, тогда undef
#  @param tm - timestamp
#  @return строка с датой
sub timestamp_to_rutime {
    my ( $self, $tm ) = @_;
    
    if( $tm =~ /^\s*(\d\d\d\d)\-(\d\d)\-(\d\d)\s+(\d\d\:\d\d)(\:\d\d)\s*$/s )
    {
        return "$3.$2.$1 $4";
    }

    return;
}


1;

