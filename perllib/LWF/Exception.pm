## @file
#  @brief Реализация класса LWF::Exception
#  @author Mikhail Kirillov


## @class LWF::Exception
#  @brief Базовый класс для всех исключений
package LWF::Exception;


# используемые пакеты
use strict;
use base 'LWF';


# создание аксепторов
__PACKAGE__->make_accessors(
    data  => 'data',            # данные
    trace => 'trace',           # строка со стеком вызовов
);


## @method void new(data)
#  Метод создает объект и выбрасывает его как искючение. первый переданный параметр передается в переменную data
#  Пример использования:
#  @code
#  new LWF::Exception( [ $var1, $var2 ] );
#  new LWF::Exception( "Connect error" );
#  @endcode
sub new
{
    my ( $class, $data ) = @_;

    my $self = { data => $data, trace => '' };

    my $i = 0;

    while( my($package, $filename, $line, $sub) = caller(1+$i++) )
    {
        $self->{trace} .= "Call level: $i; package: $package; filename: $filename; line: $line; sub: $sub; \n";
    }

    return die bless( $self, $class );
}


## @method string log_string()
#  Метод формирования строки для записи в лог файл, дочерний класс дожен перегрузить этот метод
#  @return строка для лога
sub log_string
{
    my $self = shift;
    my $class = ref $self;
    return "Exception $class: none data";
}


1;

