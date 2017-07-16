## @file
#  @brief Реализация класса LWF::XML::Maker
#  @author Mikhail Kirillov


## @class LWF::XML::Maker
#  @brief Класс генератора XML
#  Генератор XML по набору связанных узлов дерева, позволяющий в значениях указывать XML, 
#  который можно не преобразоввывать.
package LWF::XML::Maker;


# используемые модули
use strict;
use utf8;
use base 'LWF';


# создание аксессоров
__PACKAGE__->make_accessors(
	name    => 'name',
	value   => 'value',
	attrs   => 'attrs',
	encoded => 'encoded',
	childs  => 'childs',
);


# определение флага отображения XML в красивом или нет виде
use vars qw( $PRETTY_VIEW );
$PRETTY_VIEW = 1;



## @method void new(hash)
#  Инициализатор объекта
#  @param hash - хэш входных параметров
#  \li name    - имя ноды
#  \li value   - значение ноды
#  \li attrs   - атрибуты
#  \li encoded - флаг того, что у зхначения уже экранированы специальные символы
#  \li childs  - ссылка на массив потомков
sub new
{
	my ( $class, %p ) = @_;

    my $self = $class->SUPER::new();

	$self->{name}    = $p{name};
	$self->{value}   = $p{value};
	$self->{attrs}   = $p{attrs};
	$self->{encoded} = $p{encoded};
	$self->{childs}  = $p{childs};

	return $self;
}


## @method void add_childs(list)
#  Метод добавления списка дочерних тегов
#  @param list - список дочерних тегов
sub add_childs
{
	my ( $self, @list ) = @_;
	
	$self->{value} = undef;
	
	if( scalar(@list) )
	{
		$self->{childs} = [] unless $self->{childs};
		$self->{value} = undef;
		push( @{$self->{childs}}, $_ ) foreach ( @list );
	}

	return;
}


## @method void set_encoded(is_set)
#  Метод выставления флага декодивроания
sub set_encoded
{
	my ( $self, $encoded ) = @_;
	$self->{encoded} = $encoded;
	return;
}


## @method void set_attrs(hashref)
#  Метод установки атрибутов для тега
#  @param hashref - ссылка на хэш атрибутов
sub set_attrs
{
	my ( $self, $attrs ) = @_;
	$self->{attrs} = $attrs;
	return;
}


## @method void set_value(value)
#  Метод установки значения тега при этом все дочерние узлы будут удалены
#  @param value - значение
sub set_value
{
	my ( $self, $value ) = @_;
	$self->{value} = $value;
	$self->{childs} = undef;
	return;
}


## @method string to_xml(level)
#  Метод выполняет преобразование ноды в XML
#  @param level - уровень отступов (если не задан 0)
#  @return строка с XML документом
sub to_xml
{
	my ( $self, $level ) = @_;
	$level ||= 0;
	
	my $func = $self->encoded ? '_echo' : '_encode_xml';
	
	my $result = ( $level && $PRETTY_VIEW ? ( '   ' x $level ) : '' ) . "<$self->{name}";
	
	# если есть атрибуты, то добавляем их
	if( my $attrs = $self->attrs )
	{
		# если атрибуты передаются без учета порядка
		if( ref( $attrs ) eq 'HASH' )
		{
			$result .= ' ' . join( ' ', map { $_ . '="' . $self->$func($attrs->{$_}) . '"' } sort keys %{$attrs} );
		}
		# если атрибуты передаются в строгом порядке
		elsif( ref( $attrs ) eq 'ARRAY' )
		{
			for( my $j = 0 ; $j < scalar( @{$attrs} ) ; $j += 2 )
			{
				$result .= ' ' . $attrs->[ $j ] . '="' . $self->$func( $attrs->[ $j + 1 ] ) . '"';
			}
		}
	}
	
	# если нет потомков, то закрываем тэг
	if( $self->is_empty )
	{
		$result .= " />" . ( $PRETTY_VIEW ? "\n" : '' );
		return $result;
	}
	
	# если есть потомки, то работаем с ними
	if( my $childs = $self->childs )
	{
		if( $PRETTY_VIEW )
		{
			$result .= ">\n";
			$result .= $_->to_xml($level+1) foreach ( @{$childs} );
			$result .= ( $level ? ( '   ' x $level ) : '' ) . "</$self->{name}>\n";
		}
		else
		{
			$result .= '>';
			$result .= $_->to_xml($level+1) foreach ( @{$childs} );
			$result .= "</$self->{name}>";
		}
		
		return $result;
	}
	
	# тут мы работаем со значением
	$result .= '>' . $self->$func($self->value) . '</' . $self->name . '>' . ( $PRETTY_VIEW ? "\n" : '' );
	return $result;
}


## @method xml_string _encode_xml(string)
#  метод декодирования входной строки в XML
#  @param string - произвольная строка
#  @return строка с экранирование специальных символов
sub _encode_xml
{
	my ( $self, $str ) = @_;

	$str ||= '' if !defined($str);

	$str =~ s/^\s*//;
	$str =~ s/\s*$//;
	$str =~ s/&/&amp;/gm;
	$str =~ s/'/&apos;/gm;
	$str =~ s/"/&quot;/gm;
	$str =~ s/</&lt;/gm;
	$str =~ s/>/&gt;/gm;

	return $str;
}


## @method string _echo(string)
#  Метод получает на вход строку и ее же возвращает
#  @param string входная срока
#  @return входная строка без изменений
sub _echo
{
	my ( $self, $str ) = @_;
	return defined($str) ? $str : '';
}


## @method bool is_empty(void)
#  Метод начичия значения или дочерних элементов
#  @return истина, если есть дочерние элементы
sub is_empty
{
	my $self = shift;
	
	return !defined($self->{value}) && !defined($self->{childs});
}


1;

