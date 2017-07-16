## @file
#  @brief Реализация класса LWF::Exception::Interface
#  @author Mikhail Kirillov


## @class LWF::Exception::Interface
#  @brief Класс исключения вызванного ошибкой операции с базой данных
package LWF::Exception::Interface;


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
