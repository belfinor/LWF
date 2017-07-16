## @file
#  @brief Реализация парсера XML поверх libxml
#  @author Mikhail Kirillov


## @class LWF::XML::Reader
#  @brief Класса XML парсера на базе XML::LibXML
package LWF::XML::Reader;


# бибдиотеки
use XML::LibXML;
use base 'LWF';


# методы доступа
__PACKAGE__->make_accessors(
	node   => 'node',
	errstr => 'errstr',
);


## @method object new(xml)
#  Метод выполнения инициализации
#  @param xml - разбираемый XML
#  @return в случае успеха созданный объект
sub new
{
	my ( $class, $xml ) = @_;
	
	$xml ||= '';
	$xml =~ s/^\s*//s;
	$xml =~ s/\s*$//s;
	
	return if $xml eq '';
	
	my $doc = undef; 
	
	eval { $doc = XML::LibXML->load_xml( string => $xml ); };
	
	return if $@;
	
	return bless { node => $doc }, $class;
}


## @memthod string _xml_trim(source)
#  Метод удаления лишних пробелов из строки
#  @param source - исходная строка
#  @return преобразованная строка
sub _xml_trim
{
	my ( $self, $str ) = @_;
	
	$str =~ s/^\s+//s;
	$str =~ s/\s+$//s;
	$str =~ s/\s+/ /gs;
	
	return $str;
}


## @method string get_value(xpath)
#  Метод получения значения по указаному пути в структуре, если оно есть
#  @param xpath - путь в структуре
#  @return если есть значение, то оно
sub get_value
{
	my ( $self, $xpath ) = @_;
	
	my @nodes = $self->node->findnodes($xpath);

	if( scalar( @nodes ) )
	{
		my $node = $nodes[0];
		my $text = $node->textContent || '';
		return $self->_xml_trim($text);
	}
	
	return;
}


## @method arrayref get_value_array(xpath)
#  Метод получения массива значений по пути в структуре
#  @param xpath - путь в структуре
#  @return ссыдка на массив, в худшем случае на пустой
sub get_value_array
{
	my ( $self, $xpath ) = @_;
	
	my @nodes = $self->node->findnodes($xpath);
	
	if( scalar(@nodes) )
	{
		return [ map { $self->_xml_trim($_->textContent || '') } @nodes ];
	}
	
	return [];
}


## @method xml get_xml(xpath)
#  Возвращение строки с XML записью указанной ноды
#  @param xpath - путь к ноде
#  @return строка с XML, если найдена
sub get_xml
{
	my ( $self, $xpath ) = @_;
	
	my @nodes = $self->node->findnodes($xpath);

	if( scalar( @nodes ) )
	{
		my $node = $nodes[0];
		my $text = $node->toString;
		return $text;
	}
	
	return;
}


## @method arrayref get_xml_array(xpath)
#  Метод получения массива XML записей для нод по указанному адресу
#  @param xpath - расположение нод
#  @return ссылка на массив cтрок с XML содержимым
sub get_xml_array
{
	my ( $self, $xpath ) = @_;
	
	my @nodes = $self->node->findnodes($xpath);
	
	if( scalar(@nodes) )
	{
		return [ map { $_->toString  } @nodes ];
	}
	
	return [];
}


## @method arrayref nodes(xpath)
#  Метод выдергивания nod по xpath
#  @param xpath - имя ноды
#  @return ссылка на массив нод
sub nodes
{
	my ( $self, $xpath ) = @_;
	
	my @nodes = $self->node->findnodes($xpath);
	
	return [ map { bless( { node => $_ }, 'LWF::XML::Reader' ) } @nodes ];
}


## @method bool validate(schema)
#  Метод верификации документа схемой
#  @param schema - XSD схема
#  @return истина, если все ок
sub validate
{
	my ( $self, $schema ) = @_;
	
	$file = $ENV{LWF_HOME} . '/data/xsd/' . $schema;
	my $schema = XML::LibXML::Schema->new( location => $file );
	
	$@ = undef;
	
	eval { $schema->validate( $self->node ); };
	
	$self->{errstr} = $@;
	
	return $@ ? 0 : 1;
}


## @method hashref to_hash()
#  Метод формирования perl-вой структуры на основе XML без атрибутов
#  @return ссылка на хэш
sub to_hash
{
	my $self = shift;
	
	my $node = ( $self->node->findnodes( './*' ) )[0];
	
	return { $node->nodeName => $self->_process_xml_node( $node ) };
}


## @method hashref process_xml_nod(node,name,hash)
#  Метод обработки ноды XML на текущем уровне вложенности. Рекурсивный метод
#  @param node - объект XML::LibXML::Node
#  @param name - полдное имя новы с учетом вложенности
#  @param hash - хэш значений на текузем уровне
#  @return void
sub _process_xml_node
{
	my ( $self, $node ) = @_;
	
	my $tag = $node->nodeName;
	my @nodes = $node->findnodes( './*' );
	
	if( scalar( @nodes ) )
	{
		my $hash = {};
		
		foreach ( @nodes )
		{
			my $nn = $_->nodeName;
			
			if( defined($hash->{$nn}) )
			{
				if( ref($hash->{$nn}) && ref($hash->{$nn}) eq 'ARRAY' )
				{
					push @{$hash->{$nn}}, $self->_process_xml_node( $_ );
				}
				else
				{
					$hash->{$nn} = [ $hash->{$nn}, $self->_process_xml_node( $_ ) ];
				}
			}
			else
			{
				$hash->{$nn} = $self->_process_xml_node( $_ );
			}
		}
		
		return $hash;
	}
	else
	{
		return $self->_xml_trim( $node->findvalue( './text()' ) );
	}
	
	return;
}


1;

