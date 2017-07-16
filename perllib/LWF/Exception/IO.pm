## @file
#  @brief Реализация класса LWF::Exception::IO
#  @author Mikhail Kirillov


## @class LWF::Exception::IO
#  @brief Класс исключения вызванного ошибкой операции ввода/вывода 
package LWF::Exception::IO;


use strict;
use base 'LWF::Exception';


## @method string log_string()
#  Метод формировани строки для записи в лог файл
#  @return строка с сообщение об ошибке
sub log_string
{
    my $self = shift;
    
    return __PACKAGE__ . ' ' . $self->data . "\nTRACE: " . $self->trace;
}


1;
