## @file
#  @brief Реализация класса LWF::Code::Code65
#  @author Mikhail Kirillov


## @class LWF::Code::Code65
#  @brief Класс кодированя 65-символами
package LWF::Code::Code65;



# пакеты
use strict;
use warnings;
use LWF::Exception::Runtime;


# данные пакета
my $SOLT = 'CWeS475-9VpgnZslc.F0wUD2thaz6TLxBQJANPd8jIor1m3yYXRiGKuvbqEHMfOk:';
my %ENCODE;
my %DECODE;
my $BASE = length($SOLT);


my $CNT = 0;


foreach ( split( '', $SOLT ) ) {
    ( $ENCODE{$CNT}, $DECODE{$_} ) = ( $_, $CNT );
    $CNT++;
}


## @method str e_int32(num)
#  Метод кодирования 32-битного числа
#  @param num - число
#  @return закодированное число
sub e_int32 {
    my ( $self, $val ) = @_;
    my $res = '';

    foreach ( 1 .. 6 ) {
        my $cur = $val % $BASE;
        $val = int($val / $BASE);
        $res = $ENCODE{$cur} . $res;
    }

    return $res;
}


## @method str e_int16(num)
#  Метод кодирования 16-битного числа
#  @param num - число
#  @return закодированное число
sub e_int16 {
    my ( $self, $val ) = @_;
    my $res = '';

    foreach ( 1 .. 3 ) {
        my $cur = $val % $BASE;
        $val = int($val / $BASE );
        $res = $ENCODE{$cur} . $res;
    }

    return $res;
}


## @method str e_int8(num)
#  Метод кодирования 8-битного числа
#  @param num - число
#  @return закодированное число
sub e_int8 {
    my ( $self, $val ) = @_;
    my $res = '';

    foreach ( 1 .. 2 ) {
        my $cur = $val % $BASE;
        $val = int($val / $BASE);
        $res = $ENCODE{$cur} . $res;
    }

    return $res;
}


## @method num d_int32(str)
#  Метод декодирования 32-битного числа из шестисимволной строки
#  @param str - строка из 6 символов
#  @return число
sub d_int32 {
    my ( $self, $val ) = @_;

    LWF::Exception::Runtime->new( 'invalid input: ' . ( defined($val) ? $val : 'undef' ) ) if !defined($val) || length($val) != 6;

    my $res = 0;

    foreach ( $val =~ /(.)/g ) {
        $res = $res * $BASE + $DECODE{$_};
    }

    return $res;
}


## @method num d_int16(str)
#  Метод декодирования 32-битного числа из шестисимволной строки
#  @param str - строка из 3 символов
#  @return число
sub d_int16 {
    my ( $self, $val ) = @_;

    LWF::Exception::Runtime->new( 'invalid input: ' . ( defined($val) ? $val : 'undef' ) ) if !defined($val) || length($val) != 3;

    my $res = 0;

    foreach ( $val =~ /(.)/g ) {
        $res = $res * $BASE + $DECODE{$_};
    }

    return $res;
}


## @method num d_int8(str)
#  Метод декодирования 8-битного числа из шестисимволной строки
#  @param str - строка из 2 символов
#  @return число
sub d_int8 {
    my ( $self, $val ) = @_;

    LWF::Exception::Runtime->new( 'invalid input: ' . ( defined($val) ? $val : 'undef' ) ) if !defined($val) || length($val) != 2;

    my $res = 0;

    foreach ( $val =~ /(.)/g ) {
        $res = $res * $BASE + $DECODE{$_};
    }

    return $res;
}


1;

