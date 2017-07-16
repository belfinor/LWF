#  @file
#  @brief Реализация класса LWF::Logger
#  @author Mikhail Kirillov


## @class LWF::Logger
#  Базовый класса логера, построенный на базе Log::Handler
#  @see Log::Handler
package LWF::Logger;


use strict;
use warnings;
use utf8;
use Log::Handler;
use POSIX qw(strftime);
use LWF::Server::Request;
use base 'LWF';
use vars qw( $EVENT );


# создание методов доступа
__PACKAGE__->make_accessors(
    file => 'file',
);


# кеш объектов
my %CACHE = ();
$EVENT = 'event.log';


## @method object new(file)
#  Конструктор объекта, на вход принимает массив файлов
#  @param files - массив файлов, в которые логер будет писать данные
#  @return объект LWF::Logger
sub new
{
    my ( $class, $file ) = @_;
    
    $file = $ENV{LWF_HOME} . '/logs/' . $file if $file !~ /^\//;
    
    my $log = $CACHE{$file};
    return $log if $log;
    
    $log = Log::Handler->new();
    
    $log->add( file => {
        timeformat     => '%Y-%m-%d %H:%M:%S',
        message_layout => '%m',
        maxlevel       => "debug",
        minlevel       => "emergency",
        die_on_errors  => 0,
        debug_trace    => 0,
        debug_mode     => 2,
        debug_skip     => 0,
        filename       => $file,
        filelock       => 1,
        fileopen       => 1,
        reopen         => 1,
        autoflush      => 1,
        utf8           => 1,
    } );
    
    # создаем непосредственно логер
    my $self = bless {
        file  => $file,
        obj   => $log,
    }, $class;
    
    $CACHE{$file} = $self;
    
    return $self;
}


## @method void _log(level, message) 
#  Метод выполнения логирования
#  @param level - уровень (info,warn,erro)
#  @message
sub _log
{
    my ( $self, $level, $message ) = @_;

    my $hash = LWF::Server::Request->request_hash;

    my $prefix = strftime( "%Y-%m-%d %H:%M:%S|$hash|$level] " , localtime );

    foreach my $str ( split( /\r?\n/, $message ) )
    {
        $self->{obj}->info( $prefix . $str );
    }
}


## @method void info(texts)
#  Метод логировнаия сообщения на уровне INFO
#  @param texts - массив текстов, которые должны быть залогированы
#  @return void
sub info
{
    my $self = shift;
    $self->_log( 'info', $_ ) foreach @_;
    return;
}


## @method void error(texts)
#  Метод логирования сообщений на уровне ошибки
#  @param texts - список текстовых строк (НЕ ССЫЛКА НА МАССИВ!)
#  @return void
sub error
{
    my $self = shift;
    $self->_log( 'erro', $_ ) foreach @_;
    return;
}


## @method void warn(texts)
#  Метод логирования сообщений на уровне предупреждения
#  @param texts - список текстовых строк (НЕ ССЫЛКА НА МАССИВ!)
#  @return void
sub warn
{
    my $self = shift;
    $self->_log( 'warn', $_ ) foreach @_;
    return;
}


1;

