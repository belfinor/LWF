## @file
#  @brief Реализация класса LWF::Exception::Runtime
#  @author Mikhail Kirillov


## @class LWF::Exception::Runtime
#  @brief Класс исключения вызванного ошибкой времени выполнения
package LWF::Exception::Runtime;


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
