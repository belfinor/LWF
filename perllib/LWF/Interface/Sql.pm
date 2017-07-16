## @file
#  @brief Реализация класса LWF::Interface::Sql
#  @author Mikhail Kirillov


## @class LWF::Interface::Sql
#  @brief Класс интерфейса с базой данных
#  @details Класс реализует обертку вокруг объекта DBI. В случае возникновения ошибок генерируется исключение
#  @see LWF::Interface
package LWF::Interface::Sql;


use strict;
use warnings;
use utf8;
use DBI;
use LWF::Config::Sql;
use LWF::Exception::DB;
use base 'LWF::Interface';


# определим константу для записи исключения
use constant EXCEPTION => 'LWF::Exception::DB';


# создание акксессоров
__PACKAGE__->make_accessors(
    dbh    => 'dbh',
);


## @method obj new(hashref)
#  Инициализация объекта FM::Interface::DB. В случае ошибок генерируется исключение FM::Exception::DB
#  @param hash - хэш параметров
#  \li config - объект FM::Config::Main
#  @return void
sub new
{
    my ( $self, $p ) = @_;
    
    $p ||= { config => LWF::Config::Sql->new };
    $p->{config} = LWF::Config::Sql->new;
    
    $self = $self->SUPER::new($p);

    $self->{dbh}  = undef;
    
    my $config = $self->config;
    
    eval {
            $self->{dbh} = DBI->connect( $config->db_connect, $config->db_user, $config->db_passwd, {PrintError => 0, AutoCommit => 0, Warn => 0} );
    };

    # глобальная пакета
    EXCEPTION->new( $@ || $DBI::errstr ) unless $self->dbh;

    # включаем поддержку utf8
    $self->dbh->{pg_enable_utf8} = 1;
    return $self;
}


## @method void reconnect()
#  Метод выполнения переподключения к базе данных
#  @return void
sub reconnect
{
	my $self = shift;

	$self->dbh->disconnect;

	my $config = $self->config;
	$self->{dbh} = undef;

	eval {
			$self->{dbh} = DBI->connect( $config->db_connect, $config->db_user, $config->db_passwd, {PrintError => 0, AutoCommit => 0, Warn => 0} );
	};

	# глобальная пакета
	EXCEPTION->new( $@ || $DBI::errstr ) unless $self->dbh;

	# включаем поддержку utf8
	$self->dbh->{pg_enable_utf8} = 1;

	return;
}


## @method sth prepare(string)
#  @param string - смтрока с текстом запроса
#  @return дескриптор запроса
sub prepare
{
	my ($self, $query ) = @_;
	return $self->dbh->prepare($query);
}


## @method sth = execute($query, @args)
# Выполняет запрос. Параметром передается команда запроса с использованием плейсхолдеров и список переменных для подстановки.
# @param  $query - запрос
# @params @args  - список аргументов
# @return в случае успеха sth
sub execute
{
	my ($self, $query, @vars) = @_;
	my $sth = $self->dbh->prepare($query) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@vars) or EXCEPTION->new( $sth->errstr );
	return $sth;
}


## @method value select_value(query)
#  @param  query - запрос, который возвращает хотя бы один столбец
#  @return первое значение в столбце
sub select_value
{
	my ($self, $sql, @params) = @_;

	my $sth = $self->{dbh}->prepare($sql) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@params) or EXCEPTION->new( $sth->errstr );
	return ($sth->fetchrow_array)[0];
}


## @method id last_inserted_id(void)
#  @return идентфикатор последней добавленной записи
sub last_inserted_id
{
	my $self = shift;
	my $id = $self->select_value('SELECT lastval()');
	no warnings 'numeric';
	return $id+0;
}


## @method hashref select_hash(query,args)
#  @param query - текст запрсоа
#  @param args  - список аргументов запрса
#  @return ссылка на хэш с первой записью
sub select_hash
{
	my ($self, $sql, @params) = @_;
	my $sth = $self->{dbh}->prepare($sql) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@params) or EXCEPTION->new( $sth->errstr );
	return $sth->rows ? $sth->fetchrow_hashref : 0;
}


## @method arrayref select_list(query, args)
#  метод возвращает ссылку на список хэшей всех записей
#  @param query - запрос
#  @param args  - список аргументов
#  @return ссылка на массив хэшей всех записей
sub select_list
{
	my ($self, $sql, @params) = @_;
	my $row;
	my @result;

	my $sth = $self->dbh->prepare($sql) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@params) or EXCEPTION->new( $sth->errstr );
	push( @result, $row ) while ( $row = $sth->fetchrow_hashref() );
	return \@result;
}


## @method arrayref select_list_array(query,args)
#  Метод возвращает ссылку на массив массиов всех записей
#  @param query - запрос
#  @param args - список аргументов
#  @return ссылка на массив массивов
sub select_list_array
{
	my ($self, $sql, @params) = @_;
	my $row;
	my @result;

	my $sth = $self->dbh->prepare($sql) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@params) or EXCEPTION->new( $sth->errstr );

	push( @result, [@$row] ) while ( $row = $sth->fetchrow_arrayref );

	return \@result;
}


## @method arrayref select_column(query, args)
#  @param query - строка запроса
#  @param args  - список аргументов
#  @return ссылка на массив значений столбца
sub select_column
{
	my ($self, $sql, @params) = @_;
	my $row;
	my @result;

	my $sth = $self->dbh->prepare($sql) or EXCEPTION->new( $self->dbh->errstr );
	$sth->execute(@params) or EXCEPTION->new( $sth->errstr );

	push( @result, $row->[0] ) while ( $row = $sth->fetchrow_array );

	return \@result;
}


## @method void commit(void)
#  Метод фиксирования изменений сделанных в рамке транзакции
sub commit
{
	my $self = shift;
	$self->dbh->commit or EXCEPTION->new( $self->dbh->errstr );
	return;
}


## @method void rollback(void)
#  Метод отката транзакции
sub rollback
{
	my $self = shift;
	$self->dbh->rollback;
	return;
}


## @method void autocommit(val)
#  Метод азадния флага автокоммита
#  @return void
sub autocommit
{
	my ( $self, $flag ) = @_;

	$self->{dbh}{AutoCommit} = $flag ? 1 : 0;
	
	return;
}


## @method bool table_exists(name)
#  Метод проверки существует ли таблица
#  @param name - имя таблицы
#  @return истина, если таблица есть
sub table_exists
{
	my ( $self, $name ) = @_;
	
	my $query = q[SELECT COUNT(1) FROM information_schema.tables 
    where 
        table_catalog = CURRENT_CATALOG AND 
        table_schema = CURRENT_SCHEMA AND
        table_name = ?];

	return $self->select_value( $query, $name );
}


1;
