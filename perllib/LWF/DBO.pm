## @file
#  @brief Реализация классa LWF::DBO
#  @author Mikhail Kirillov


## @class LWF::DBO
#  @brief Базовый класс для моделей
#  @see LWF
#  @see LWF::Interface::Sql
package LWF::DBO;


# используемые модули
use strict;
use utf8;
use POSIX qw(strftime);
use LWF::Exception::DB;
use base 'LWF';


# зaкешированный конфиг
our $SQL;


## @method obj sql(obj)
#  Метод получения/задания интерфейса с базой
#  @param obj - LWF::Interface::Sql
#  @return LWF::Interface::Sql
sub sql
{
    my ( $self, $sql ) = @_;
    $SQL = $sql if $sql;
    return $SQL;
}


## @method string prefix()
#  @return префикс к именам моделей
sub prefix
{
    return '';
}


## @method void columns(list)
#  Иницилизируем список аксепторов для полей таблиц/результатов выполнения запросов
#  @code
#  __PACKAGE__->columns( qw(field1 field12 ...) );
#  @endcode
#  Здесь field1, ..., fieldN - список параметров переданных в качестве параметров функции
sub columns
{
    # строим хэш
    my ( $package, @list )  = @_;
    my %p = map { $_ => "data/$_" } @list;

    $package->make_accessors( %p );

    return;
}


## @method void table(name)
#  Метод создания аксессора доступа, возвращающего имя таблицы
#  @param name - имя таблицы
sub table
{
    my ( $package, $table ) = @_;
    no strict 'refs';
    *{$package.'::table'} = sub { "$table" };
    return;
}


## @method void pkeys(pkeys)
#  Метод создания аксессора доступа к имени поля первичного ключа
#  Если приватных ключей больше одного, то будет возвращен массив
#  @param pkeys - массив первичных ключей
sub pkeys
{
    my ( $package, @pkeys ) = @_;

    my $pkey = join( ';', @pkeys );

    no strict 'refs';
    *{$package.'::pkeys'} = sub { split( ';', "$pkey" ) };
    return;
}


## @method obj new(hashref)
#  Конструктор
#  @return объект
sub new
{
    my $class = shift;
    
    my $self = $class->SUPER::new( @_ );
    $self->{data} = {};
    
    return $self;
}


## @method ( query, args ) _make_where( params )
#  Метод генерации параметров запроса
#  @param params - ссылка на массив ключей и параметров
#  @return query - запрос, args - ссылка на массив параметров
sub _make_where
{
	my ( $self, $params ) = @_;

	my $query = '';
	my $i = 0;
	my @args;

	for( my $i = 0 ; $i < scalar(@{$params}) ; $i += 2 )
	{
		# добавляем условие
		my ( $k, $v ) = ( $params->[$i], $params->[$i+1] );

		if( $k =~ /^_(.+)$/ )
		{
			$k = uc $1;			

			if( $k eq 'ORDER' )
			{
				$query .= ' ORDER BY ' . ( ref($v) && ref($v) eq 'ARRAY' ? join(',',@{$v}) : $v );
			}
			elsif( $k eq 'LIMIT' )
			{
				$query .= " LIMIT $v";
			}
			elsif( $k eq 'OFFSET' )
			{
				$query .= " OFFSET $v";
			}
			else
			{
				LWF::Exception::DB->new( "Unsupported derective" );
			}

			next;
		}
		else
		{
			$query .= $i ? ' AND ' : ' WHERE ';
		}

		if( defined($v) )
		{
			if( ref($v) )
			{
				if( ref($v) eq 'SCALAR' )
				{
					$query .=  '(' . $k . ' ' . $$v . ')';
				}
				elsif( ref($v) eq 'ARRAY' )
				{
					$query .= "$k IN (" . join( ',', map { '?' } @{$v} ) . ')';
					push @args, @{$v};
				}
				else
				{
					LWF::Exception::DB->new( "Unsupported value type" );
				}

				next;
			}
			else
			{
				$query .= "$k = ?";
				push @args, $v;
			}
		}
		else
		{
			$query .= "( $k IS NULL )";
		}		
	}

	return $query, \@args;
}


## @method obj _get( k1 => v1, k2 => v2 )
#  Метод получения объекта одного объекта по переданным параметрам, если они есть
#  @param k1, ..., kn, v1, ..., vn - ключи и значение, ключи могут повторяться. Значения могут быть undef, константой, ссылкой на строку и ссылкой на массив
#  @return объект соответствующей модели, если она есть
sub _get
{
    my $class = shift;

    my ( $query, $args ) = $class->_make_where( \@_ );

    $query = 'SELECT * FROM ' . $class->table .  $query;

    my $hash = $class->sql->select_hash( $query, @{$args} );

    return $class->_bless_result( $hash );
}


## @method obj get_from(class, k1 => v1, k2 => v2, ... )
#  Метод поиска экземпляра класса
#  @param class модели без LWF::DBO::
#  @param ki - имя ключа
#  @param vj - значение
#  @return объект класса, если найден
sub get
{
    my $self = shift;
    my $class = shift;

    $class = $self->prefix . $class;

    eval "require $class;";
    die $@ if $@;

    return $class->_get( @_ );
}


## @method list search( class, k1 => v1, k2 => v2, ... )
#  Метод поиска объектов из класса
#  @param class - класс результат
#  @param ki - ключ в таблице
#  @param vj - значение результата
#  @return ссылка на массив объектов
sub search
{
    my $self = shift;
    my $class = shift;
    
    $class = $self->prefix . $class;
    
    eval "require $class;";
    die $@ if $@;

    return $class->_search( @_ );
}


## @method number _count( k1 => v1, k2 => v2, ... )
#  Метод получения числа объектов, которые будут получены в результате поиска
#  @param k1, ..., kn, v1, ..., vn - ключи и значение, ключи могут повторяться. Значения могут быть undef, константой, ссылкой на строку и ссылкой на массив
#  @return число
sub _count
{
    my $class = shift;

    my ( $query, $args ) = $class->_make_where( \@_ );

    $query = 'SELECT COUNT(1) FROM ' . $class->table .  $query;

    return $class->sql->select_value( $query, @{$args} );
}


## @method number count( class, k1 => v1, k2 => v2, ... )
#  Метод поиска числа объектов из класса, удовлетворяющих критерию поиска
#  @param class - класс результат
#  @param ki - ключ в таблице
#  @param vj - значение результата
#  @return число объектов
sub count
{
    my $self = shift;
    my $class = shift;

    $class = $self->prefix . $class;
    
    return $class->_count( @_ );
}


## @method list _search( k1 => v1, k2 => v2 )
#  Метод получения объекта одного объекта по переданным параметрам, если они есть
#  @param k1, ..., kn, v1, ..., vn - ключи и значение, ключи могут повторяться. Значения могут быть undef, константой, ссылкой на строку и ссылкой на массив
#  @return ссылка на массив объектов класса
sub _search
{
    my $class = shift;

    my ( $query, $args ) = $class->_make_where( \@_ );

    $query = 'SELECT * FROM ' . $class->table .  $query;

    my $array = $class->sql->select_list( $query, @{$args} );

    # выполянем каст моделей
    my @result;

    push @result , $class->_bless_result( $_ ) foreach @{$array}; 

    return \@result;
}


## @method obj bless_to(class,obj)
#  Метод приведения полученного хэша к объекту этого класса
#  @return объект или undef
sub bless_to
{
    my ( $self, $class, $obj ) = @_;
    
    $class = $self->prefix . $class;
    
    return $obj ? bless( {
        data => $obj 
        }, $class ) : undef;
}



## @method obj _bless_result(obj)
#  Метод приведения полученного хэша к объекту этого класса
#  @return объект или undef
sub _bless_result
{
    my ( $class, $obj ) = @_;

    return $obj ? bless( {
        data => $obj 
        }, $class ) : undef;
}


## @method void delete()
#  Метод удаления объекта
#  @return void
sub delete
{
    my $self = shift;
    
    my @args;
    my $query = 'DELETE FROM ' . $self->table . ' WHERE ';
    my $i = 0;

    foreach my $k ( $self->pkeys )
    {
        $query .= ' AND ' if $i;

        $query .= "$k = ?";
        push @args, $self->$k;

        $i++;
    }
    
    $self->sql->execute( $query, @args );
    return;
}


## @method void update( v1 => k1, v2 => k2, ... ,  )
#  Метод выполнения обновления данных
#  @param change - изменяемые поля
#  @param where - условию, плюс _offset и _limit
#  @return void
sub update
{
    my ( $self, @params ) = @_;

    my $query = 'UPDATE ' . $self->table . ' SET ';
    my @args;

    for( my $i = 0 ; $i < scalar(@params) ; $i += 2 )
    {
        $query .= ', ' if $i;

        my ( $k, $v ) = ( $params[$i], $params[$i+1] );

        if( ref($v) )
        {
            $query .= $k . ' = (' . $$v . ')';
        }
        else
        {
            $query .= $k . ' = ?';
            push @args, $params[$i+1];
        }
    }

    $query .= ' WHERE ';
    my $i = 0;

    foreach my $k ( $self->pkeys )
    {
        $query .= ' AND ' if $i;

        $query .= "$k = ?";
        push @args, $self->$k;

        $i++;
    }

    $query .= ' RETURNING *';

    $self->{data} = $self->sql->select_hash( $query, @args );
    
    return $self;
}


## @method obj _create( k1 => v1, k2 => v2, ... )
#  Метод добавления элемента текущего типа
#  @param ki - поле элемента
#  @param vj - значение поля, либо значение, либо ссылка на строку с выражением либо undef для null
#  @return object типа класса
sub _create
{
	my ( $class, %p ) = @_;
	
	my $query = 'INSERT INTO ' . $class->table . '(';
	my $values = ') VALUES (';
	my $i = 0;
	
	my @args;
	
	foreach my $k ( keys %p )
	{
		my $v = $p{$k};
		
		if( $i )
		{
			$query .= ',';
			$values .= ',';
		}
		
		$query .= $k;
		
		if( !defined($v) || ( defined($v) && !ref($v) ) )
		{
			if( defined($v) )
			{
				$values .= '?';
				push @args, $v;
			}
			else
			{
				$values .= 'NULL';
			}
		}
		else
		{
			$values .= '(' . $$v . ')';
		}
		
		$i++;
	}
	
	$query .= $values . ') RETURNING *';
	
	return $class->_bless_result( $class->sql->select_hash( $query, @args ) );
}


## @method obj create( class, k1 => v1, k2 => v2, ... )
#  Метод добавления элемента указанного класса
#  @param ki - поле элемента
#  @param vj - значение поля, либо значение, либо ссылка на строку с выражением либо undef для null
#  @return object типа класса
sub create
{
    my $self = shift;
    my $class = shift;
    
    $class = $self->prefix . $class;

    eval "require $class;";
    die $@ if $@;
    
    return $class->_create( @_ );
}


## @method arrayref has_many(class,method,k1=>v1,k2=>v2,...)
#  Метод создания метода получения расширения данных
#  @param method - имя создаваеого метода
#  @param class  - класс объектов результатов без LWF::DBO::
#  @param ki     - исходных объектов
#  @param vj     - если строка, то поле текущего класса, если ссылка на строку, то поставляем поли следом за ним контент строки
#  @return сслыка на массив 
sub has_many {
    my $package = shift;
    my $class  = shift;
    
    $class = $package->prefix . $class;

    eval "require $class;";
    die $@ if $@;
    
    my $method = shift;
    my @params = @_;

    no strict 'refs';

    return if defined *{$package.'::'.$method};

    *{$package.'::'.$method} = sub {
        
        my $self = shift;

        my @args;

        for( my $i = 0 ; $i < scalar( @params ) ; $i += 2 ) {
            push @args, $params[$i];

            my $v = $params[$i+1];

            push @args, ( ( defined($v) && !ref($v) && $params[$i] !~ /^_/ ) ? $self->$v : $v );
        }

        $class->_search( @args );
    };

    return;
}


## @method obj belongs( class,method,k1=>v1,k2=>v2,...)
#  Метод создания метода получения расширения данных
#  @param method - имя создаваеого метода
#  @param class  - класс объектов результатов без LWF::DBO::
#  @param ki     - исходных объектов
#  @param vj     - если строка, то поле текущего класса, если ссылка на строку, то поставляем поли следом за ним контент строки
#  @return объект класса, если найден
sub belongs {
    my $package = shift;
    my $class  = shift;
    
    $class = $package->prefix . $class;

    eval "require $class;";
    die $@ if $@;
    
    my $method = shift;
    my @params = @_;

    no strict 'refs';

    return if defined *{$package.'::'.$method};

    *{$package.'::'.$method} = sub {
        
        my $self = shift;

        return $self->{$method} if defined $self->{$method};
        
        my @args;
        my $cache = 0;

        for( my $i = 0 ; $i < scalar( @params ) ; $i += 2 ) {
            if( $params[$i] eq '_cache' ) {
                $cache = 1;
                next;
            }
        
            push @args, $params[$i];

            my $v = $params[$i+1];

            push @args, ( ( defined($v) && !ref($v) && $params[$i] !~ /^_/ ) ? $self->$v : $v );
        }
        
        my $obj = $class->_get( @args );
        $self->{$method} = $obj if $cache;
        
        $obj;
    };

    return;
}


## @method arrayref select_list(class, query, args)
#  Метод выполнения выборки списка элементов
#  @param  query - запрос на выборку элементов
#  @param  class - класс модели объекта из результирующего спсика (префикс LWF::DBO:: не нужен)
#  @params args  - список параметров запроса
#  @return ссылка список объектов класса class
sub select_list
{
    my ( $self, $class, $query, @args ) = @_;

    # получаем результирующий список

    my $list = $self->sql->select_list( $query, @args );

    # выполянем каст моделей
    my @result;

    $class = $self->prefix . $class;

    eval "require $class;";
    die $@ if $@;

    push @result, $class->_bless_result( $_ ) foreach @{$list};
    
    return \@result;
}


## @method object select_single(class, query, args)
#  Метод порлучения единичного объекта заданного класса
#  @param  class - класс возвращаемого объекта (префикс LWF::DBO:: не нужен)
#  @param  query - выборка на получения объекта
#  @param  args  - массив аргументов
#  @return в случае успеха объект указанного типа
sub select_single
{
    my ( $self, $class, $query, @args ) = @_;

    # получаем объект
    my $obj = $self->sql->select_hash( $query, @args );

    # выполняем динамик каст и возвращаем объект
    $class = $self->prefix . $class;

    eval "require $class;";
    die $@ if $@;

    return $class->_bless_result( $obj );
}


1;
