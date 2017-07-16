## @file
#  @brief Реализация класса LWF::Server::Session
#  @author Mikhail Kirillov


## @class LWF::Server::Session
#  @brief Класс сессии
package LWF::Server::Session;


# пакеты
use strict;
use warnings;
use LWF::Interface::Redis;
use base 'LWF';


# переменные
my $NEXT_ID = $ENV{LWF_PROJECT} . '.sesions.next_id';
my $CACHE = LWF::Interface::Redis->new;
my $TTL = 28800;


# генерация методов доступа
__PACKAGE__->make_accessors(
    id => '+id',
);


## @method obj new(key1=>va1,key2=>val2,...)
#  Метод открытия новое сессии
sub new {
    my ( $class, @args ) = @_;
    
    my $self = $class->SUPER::new();

    $self->id( $CACHE->incr( $NEXT_ID ) );

    push @args, 'id', $self->id;

    $self->set( @args );
    $CACHE->expire( $self->_redis_key, $TTL );
    
    return $self;
}


## @method obj get(id)
#  Метод получения сессии по идентификатору
#  @param id - идентификатор сессии
#  @return obj
sub get {
    my ( $class, $id ) = @_;

    if( $CACHE->exists( $class->_redis_key( $id ) ) ) {
        my $self = $class->SUPER::new();
        $self->id( $id );
        return $self;
    }

    return;
}


## @method void set(key1=>val1,key2=>val2,...)
#  Метод задания параметров сессии
#  @retunr void
sub set {
    my $self = shift;
    $self->{data} = undef;
    $self->{rights} = undef;
    $CACHE->hmset( $self->_redis_key, @_ );
    return;
}


## @method hashref data()
#  Метод поулчения данных сессия в виде ссылки на хэш
#  @return ссылка на хэш
sub data {
    my $self = shift;
    $self->{data} = $CACHE->hgetall( $self->_redis_key ) unless $self->{data};
    return $self->{data};
}


## @method hashref rights()
#  Метод получения прав
#  @return ссылка на хэш
sub rights {
    my $self = shift;
    
    unless( $self->{rights} ) {
        my $rights = $self->data->{rights} || '';
        my %h = map { $_ => 1 } $rights =~ /(\S+)/sg;
        $self->{rights} = \%h;
    }

    return $self->{rights};
}


## @method string _redis_key([id=$self->id])
#  Метод поулчения имени ключа редиса, в котором сессия
#  @return string
sub _redis_key {
    my ( $self, $id ) = @_;
    return $ENV{LWF_PROJECT} . '.sessions.' . ( $id || $self->id );
}


1;
