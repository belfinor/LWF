## @file
#  @brief Реализация класса LWF::Interface::Counters
#  @author Mikhail Kirillov


## @class LWF::Interface::Counters
#  @brief Класс интерфейса со счетчиками
#  @see LWF::Interface
package LWF::Interface::Counters;


$VERSION = '1.002';
$DATE    = '2016-10-19';


use strict;
use warnings;
use utf8;
no warnings qw(redefine);
use IO::Socket::INET;
use LWF::Config::Counters;
use base 'LWF';


# данные
my $config = LWF::Config::Counters->new;
my $sock  = undef;
my $last_time = 0;
my $period = 5;


## @method bool tcp_connect()
#  Метод установки соединения, если его нет
#  @return true, если есть соединение
sub tcp_connect {
    my $self = shift;

    return 1 if $sock;

    return if time < $last_time + $period;

    eval {
        $sock = IO::Socket::INET->new( PeerAddr => $config->host, PeerPort => $config->port, Proto => 'tcp', Timeout => 2 );
    };

    $last_time = time;

    return $sock ? 1 : 0;
}


## @method string prefix()
#  Метод получения префикса
#  @return string
sub prefix {
    return $ENV{LWF_DEV} ? 'dev:' : 'prod:';
}


## @method (cnt,exists) get(counter,key)
#  Метод получения счетчика
sub get {
    
    my ( $self, @args ) = @_;

    return (0,0) unless $self->tcp_connect();

    my $cmd = join( ' ', 'get', $self->prefix() . $args[0], ( $args[1] ? ( $args[1] ) : () ) );
    my $res;

    eval {
        print $sock $cmd . "\n";
        $res = <$sock>;
    };

    if( $@ || !$res ) {
        $sock = undef;
        return (0,0);
    }

    my @data = $res =~ /(\d+)/g;

    unless( scalar(@data) ) {
        $sock = undef;
        return (0,0);
    }

    return @data;
}

## @method (cnt,exists) inc(counter,key)
#  Метод инкремента счетчика
sub inc {
    
    my ( $self, @args ) = @_;
    
    return (0,0) unless $self->tcp_connect();

    my $cmd = join( ' ', 'inc', $self->prefix() . $args[0], ( $args[1] ? ( $args[1] ) : () ) );
    my $res;

    eval {
        print $sock $cmd . "\n";
        $res = <$sock>;
    };

    if( $@ || !$res ) {
        $sock = undef;
        return (0,0);
    }

    my @data = $res =~ /(\d+)/g;

    unless( scalar(@data) ) {
        $sock = undef;
        return (0,0);
    }

    return @data;
}


## @method (cnt,exists) dec(counter,key)
#  Метод инкремента счетчика
sub dec {
    
    my ( $self, @args ) = @_;
    
    return (0,0) unless $self->tcp_connect();

    my $cmd = join( ' ', 'dec', $self->prefix() . $args[0], ( $args[1] ? ( $args[1] ) : () ) );
    my $res;

    eval {
        print $sock $cmd . "\n";
        $res = <$sock>;
    };

    if( $@ || !$res ) {
        $sock = undef;
        return (0,0);
    }

    my @data = $res =~ /(\d+)/g;

    unless( scalar(@data) ) {
        $sock = undef;
        return (0,0);
    }

    return @data;
}


1;
