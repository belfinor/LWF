## @file
#  @brief Реализация класса LWF::Interface::Redis
#  @author Mikhail Kirillov


## @class LWF::Interface::Redis
#  @brief Класс интерфейса c Redis-ом
#  @see LWF::Interface
package LWF::Interface::Redis;


use strict;
use warnings;
use utf8;
no warnings qw(redefine);
use Redis;
use LWF::Config::Redis;
use base 'LWF';


# методы длоступа
__PACKAGE__->make_accessors(
    namespace => '+namespace',
);


# для кэширования переменных
my $_RDB  = undef;
my $_PING = time;
my $_INT = 3;


## @method void new(hashref)
#  Перегрузка метода выполнения инициализации. ПОдставляем актуальный для конфиг
#  @param hashref - хэш параметров
#  @return void
sub new {
    my ( $class, $p ) = @_;
        
    my $self = $class->SUPER::new;
    
    if( $_RDB )
    {
        if( time - $_PING > $_INT )
        {
            my $ping = 0;
            eval { $ping = $_RDB->ping };
        
            $_RDB = undef unless $ping;
            
            $_PING = time;
        }
    }
    
    unless( $_RDB )
    {
        my $server = $self->config->host . ':' . $self->config->port;
        
        eval { $_RDB = Redis->new( server => $server, debug => 0 ) };
        
        $_PING = time if $_RDB;
    }
    
    $self->namespace( $p->{namespace} || '' );
    
    return $self;
}


## @methdo obj config()
#  метод получения конфига
#  @retunr объект
sub config {
    return LWF::Config::Redis->new;
}


## @method void select( dbnum )
#  Метод выбора текущей бзы данных
#  @return void
sub select {
    my ( $self, $dbnum ) = @_;
    
    return unless $_RDB;
    
    eval { $_RDB->select( $dbnum ); };
    
    $_RDB = undef if $@;
    
    return;
}


## @method void set( key, value, ttl )
#  Метод установки ключа и значения в кэш
#  @param key - ключ
#  @param value - значение
#  @param ttl - время жизни, если задано
#  @return void
sub set {
    my ( $self, $key, $value, $ttl ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    eval {
        $_RDB->set( $key, $value );
        $_RDB->expire( $key, $ttl ) if defined $ttl;
    };
    
    $_RDB = undef if $@;
    
    return;
}


## @method void expire( key, ttl )
#  Метод установки времени жизни ключа
#  @param key - ключ
#  @param ttl - время жизни в секундах
#  @return void
sub expire {
    my ( $self, $key, $ttl ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    eval {
        $_RDB->expire( $key, $ttl );
    };
    
    $_RDB = undef if $@;
    
    return;
}


## @method string get( key )
#  метод получения значения ключа, если такой есть
#  @param key - ключ
#  @return строка ключа, если ключ найден
sub get {
    my ( $self, $key ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    eval { $val = $_RDB->get( $key ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method string exists( key )
#  Метод проверки наличия ключа
#  @param key - ключ
#  @return истина, если есть
sub exists {
    my ( $self, $key ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    eval { $val = $_RDB->exists( $key ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method value llen( queue )
#  метод поулчения размера очереди
#  @param queue - ключ
#  @return строка ключа, если ключ найден
sub llen {
    my ( $self, $queue ) = @_;
    
    return unless $_RDB;
    
    $queue = $self->_real_name( $queue );
    
    my $val = undef;
    
    eval { $val = $_RDB->llen( $queue ); };
    
    $_RDB = undef if $@;
    
    return $val || 0;
}


## @method string del( key )
#  метод удаления ключа
#  @param key - ключ
#  @return строка ключа, если ключ найден
sub del {
    my ( $self, $key ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    
    eval { $val = $_RDB->del( $key ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method int incr(key)
#  Метод выполнения инкремента ключа и возврат значения
#  @param key - ключ
#  @return новое значение
sub incr {
    my ( $self, $key ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    eval { $val = $_RDB->incr( $key ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method int hmget(key,item1,item2,...)
#  Метод получения ключей хэша
#  @param key - ключ
#  @return новое значение
sub hmget {
    my ( $self, $key, @list ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    eval { $val = $_RDB->hmget( $key, @list ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method int hmset(key,item1=>va1,item2=>val2,...)
#  Метод получения ключей хэша
#  @param key - ключ
#  @return новое значение
sub hmset {
    my ( $self, $key, @list ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    eval { $val = $_RDB->hmset( $key, @list ); };
    $_RDB = undef if $@;
    
    return 1;
}


## @method hashref hgetall()
#  Метод получения хэша
#  @param key - ключ
#  @return ссылка на хэш
sub hgetall {
    my ( $self, $key ) = @_;
    
    return unless $_RDB;
    
    $key = $self->_real_name( $key );
    
    my $val = undef;

    eval { 
        my %h = @{$_RDB->hgetall( $key )}; 
        $val = \%h; 
    };
   
 
    $_RDB = undef if $@;
    
    return $val;
}


## @method int ttl(key)
#  метод поулчения TTL для ключа
#  @return число секунд
sub ttl
{
    my ( $self, $key ) = @_;
    
    return 0 unless $_RDB; 
    
    $key = $self->_real_name( $key );
    
    my $val = undef;
    
    eval { $val = $_RDB->ttl( $key ); };
    
    $_RDB = undef if $@;
    
    return $val;
}


## @method arrayref keys(pattern)
#  Метод получения списка ключей по шалону
#  @param patter - шаблон выборки ключей, наподобие space:*
#  @return ссылка на массив ключей
sub keys
{
    my ( $self, $pattern ) = @_;
    
    return [] unless $_RDB;
    
    my @list;
    
    $pattern = '*' unless defined $pattern;
    
    eval { @list = $_RDB->keys( $pattern ); };
    
    $_RDB = undef if $@;
    
    return \@list;
}



## @method bool rpush(queue,items)
#  Метод добавления в указанную очередь значений
#  @param queue - имя переменной очереди
#  @param items - список значений
#  @return истина, если все ок
sub rpush
{
    my ( $self, $queue, @list ) = @_;
    
    return unless $_RDB;
    
    $queue = $self->_real_name( $queue );
    
    eval { $_RDB->rpush( $queue, @list ); };
    
    if( $@ )
    {
        $_RDB = undef;
        return;
    }
    
    return 1;
}


## @method obj lindex(queue,pos)
#  Метод получения указанной команды в очереди
#  @param queue - очередь
#  @param pos - позиция
#  @return команда, если есть
sub lindex
{
    my ( $self, $queue ) = @_;
    
    return unless $_RDB;
    
    $queue = $self->_real_name( $queue );
    
    my $obj = undef;
    
    eval { $obj = $_RDB->lindex( $queue, 0 ); };
    
    if( $@ )
    {
        $_RDB = undef;
        return;
    }
    
    return $obj;
}


## @method obj lpop(queue)
#  Метод выталкивания первой команды слева из очереди
#  @param queue - очередь
#  @return команда, если есть
sub lpop
{
    my ( $self, $queue ) = @_;
    
    return unless $_RDB;
    
    $queue = $self->_real_name( $queue );
    
    my $obj = undef;
    
    eval { $obj = $_RDB->lpop( $queue ); };
    
    if( $@ )
    {
        $_RDB = undef;
        return;
    }
    
    return $obj;
}


## @method obj blpop(queue,timeout)
#  Метод выталкивания первой слева команды из очереди с блокировкой, если нет данных и не наступил таймаут
#  @param queue - очередь
#  @return команда, если есть
sub blpop
{
    my ( $self, $queue, $timeout ) = @_;
    
    return unless $_RDB;
    
    $queue = $self->_real_name( $queue );
    
    my $obj = undef;
    
    eval { $obj = $_RDB->blpop( $queue, $timeout || $_INT ) };
    
    if( $@ )
    {
        $_RDB = undef;
        return;
    }
    
    return $obj;
}


## @method string _real_name(name)
#  Метод получения полного имени ключа (с учетом пространства)
#  @param name - имя в пространстве
#  @return полное имя
sub _real_name
{
    my ( $self, $name ) = @_;
    return $self->namespace ? $self->namespace . '.' . $name : $name;
}


## @method void quit()
#  Отключение от сервера
#  @return void
sub quit
{
    my $self = shift;

    return unless $_RDB;

    eval { $_RDB->quit; };

    $_RDB = undef;
    return;
}


1;
