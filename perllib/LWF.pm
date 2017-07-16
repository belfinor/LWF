## @file
#  Реализация класса LWF


## @class LWF
#  @brief Базовый класс для все объектов
#  Базовый класс для всех объектов
package LWF;


# используемый модули
use strict;
use warnings;
use Data::Dumper;
use POSIX ":sys_wait_h";


# добавляем обработчи на завершение дочерних процессов, чтобы избежать defunct-ов
$SIG{CHLD} = \&REAPER;


## @method void REAPER(void)
#  Метод вызывается по сигналу от потомка и маркирует процессы как завершенные иначе будет море зомби и тормоза на сервере
#  @return void
sub REAPER
{
	my $stiff;
	while ( ($stiff = waitpid(-1, WNOHANG) ) > 0) {}
	$SIG{CHLD} = \&REAPER;
}


## @method void make_accessors(hash)
#  Создание методов доступа к полям объекта
#  глубина вложенности занчения в хэше объекта произволная (в качестве разделителя используетс я '/' )
#  В потомке должен присутствовать вызов
#  \code
#  __PACKAGE__->make_accessors(
#     'sql'                  =>  'sql',
#     'webserverType'        =>  'data/webserver_type',    
#     'idRS'                 =>  '+data/rs_id'
#  );   
#  \endcode
#  @param hash - хэш значение метод => поле. Если поле начинается с +, то оно перезаписываемое
sub make_accessors
{
    my ( $class, %p ) = @_;

    no strict 'refs';

    foreach my $key ( keys %p )
    {
        next if defined *{$class.'::'.$key};

        my $val = $p{$key};
        my ( $is_rw ) = $val =~ s/^\+//;
        my @params = split( '/', $val );
        my $size = scalar(@params);

        *{$class.'::'.$key} = $is_rw ? sub
        {
            my ($self,$new_val) = @_;

            foreach my $i ( 1 .. $size )
            {
                my $item = $params[$i-1];
                $self->{$item} = $new_val if $i == $size && defined($new_val);
                $self = $self->{$item};
            }

            return $self;
         }
        : sub
        {
            my $self = shift;
            $self = $self->{$_} foreach (@params);
            return $self;
        };
    }

    use strict 'refs';
}


## @method object new(hashref)
#  Конструктор объекта
#  @param hash - хэш параметров
#  @return дочерний объект
sub new
{
	my ( $class, $p ) = @_;
	
	# создание объектов с базовым для всех объектов наполнение
	my $self  = bless {
	}, $class;
	
	return $self;
}


## @method string dump()
#  Метод получения дампа объекта
#  @return строка с дампом
sub dump
{
	my $self = shift;
	return Dumper( $self );
}


1;
