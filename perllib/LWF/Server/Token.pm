## @file
#  @brief Реализация класса LWF::Server::Token
#  @author Mikhail Kirillov


## @class LWF::Server::Token
#  @brief Класс для работы с токеном
package LWF::Server::Token;


# пакеты
use strict;
use warnings;
use LWF::Code::Code65;
use Digest::SHA qw(sha512_base64);
use LWF::Interface::Redis;


# глобальные данные
my $PID = $$;
my $TTL = 28800;
my $SEQ = 1;


# подготовка
srand(time);


## @method string new(session_id)
#  Метод генерации токена
#  @param session_id - идентификатор сессии
#  @param src_id - идентификатор источника
#  @return строка токена
sub new {
    my ( $self, $session_id ) = @_;

    $session_id ||= 0;

    my $tm = time + $TTL;
    my $rnd = int(rand(10000));

    my $src = $self->_build_hash( time => $tm, pid => $PID, seq => $SEQ, session_id => $session_id, random => $rnd );
    
    my $res = LWF::Code::Code65->e_int32($tm) . LWF::Code::Code65->e_int16($PID) . LWF::Code::Code65->e_int16($SEQ) . LWF::Code::Code65->e_int16($rnd) . LWF::Code::Code65->e_int32($session_id);

    $SEQ = ( $SEQ + 1 ) % 0xffff;

    return $res . $src;
}


## @method session_id check(token,src_id)
#  Метод проверки токена
#  @param token - токен
#  @param src_id - идентификатор источника
#  @return идентификатор сессии, если все ок
sub check {
    my ( $self, $token ) = @_;

    return unless $token;

    my @vals = $token =~ /(.{6})(.{3})(.{3})(.{3})(.{6})(.+)/;

    return unless scalar(@vals);

    my $tm = LWF::Code::Code65->d_int32( $vals[0] );
    my $pid = LWF::Code::Code65->d_int16( $vals[1] );
    my $seq = LWF::Code::Code65->d_int16( $vals[2] );
    my $rnd = LWF::Code::Code65->d_int16( $vals[3] );
    my $session_id = LWF::Code::Code65->d_int32( $vals[4] );

    my $hash = $self->_build_hash( time => $tm, pid => $pid, seq => $seq, session_id => $session_id, random => $rnd );

    return $hash eq $vals[5] ? $session_id : undef;
}


## @method string _build_hash(hashref)
#  Метод вычисления контролной суммы
#  @param hashref - ссылка на хэш параметров
#  \li time - время (epoch)
#  \li pid - пид
#  \li seq - счетчик последовательности
#  \li random - случайное число
#  \li session_id - идентификатор сессии
#  @return строка суммы
sub _build_hash {
    my ( $self, %p ) = @_;

    my $src = join( '.', $p{time}, $p{pid}, $p{seq}, int($p{time} / 255), $p{session_id}, $p{random}, $self->key() , $ENV{LWF_PROJECT} );
    
    $src = sha512_base64( $src );
    $src =~ tr!+=/!-.:!;

    return $src;
}


## @method string key()
#  Метод получения специального ключа
#  @return string
sub key {
    return 'rRj0Wx5HBDZPV23SIc9.q7enQpFwkz8iKmCEf6-NuvUMhd';
}


1;
