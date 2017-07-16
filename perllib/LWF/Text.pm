## @file
#  @brief Реализация класса LWF::Text
#  @author Mikhail Kirillov


## @class LWF::Text
#  @brief Базовый класс для работы с текстами
package LWF::Text;


# пакеты
use strict;
use warnings;
use utf8;


## @method string trim(src)
#  Метод удаления пробелов вначеле, вконце строки. а также замены последовательности пробелов на одиночные пробелы
#  @param src - исходная строка
#  @return преобразованная строка
sub trim {
	my ( $self, $str ) = @_;
	
	return unless defined $str;
	
	$str =~ s/^\s+//sg;
	$str =~ s/\s+$//sg;
	$str =~ s/\s+/ /sg;
	
	return $str;
}


## @method int to_int(str,default)
#  Метод преобразования строки в целое число
#  @param str - исходная строка
#  @param default - значение по умолчанию, если иходное значение невалидное
#  @return число
sub to_int {
    my ( $self, $str, $default ) = @_;

    $default = 0 unless defined($default);

    return $default unless defined($str) || ref($str);

    $str = $self->trim($str);

    return $default if $str eq '' || $str =~ /\D/;

    return $str + 0;
}


1;
