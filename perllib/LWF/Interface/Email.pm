## @file
#  @brief Реализация класса LWF::Interface::Email
#  @author Mikhail Kirillov


## @class LWF::Interface::Email
#  @brief Класс интерфейса c сервером почты
#  @see LWF::Interface
package LWF::Interface::Email;


use strict;
use warnings;
use utf8;
no warnings qw(redefine);
use Net::SMTP::SSL;
use LWF::Config::Email;
use LWF::Exception::Runtime;
use LWF::Logger;
use base 'LWF::Interface';


# методы доступа
__PACKAGE__->make_accessors( 
    logger => '+logger',
);


## @method void new(hashref)
#  Перегрузка метода выполнения инициализации. Подставляем актуальный для конфиг
#  @param hashref - хэш параметров
#  @return void
sub new
{
    my ( $class, $p ) = @_;
 
    $p ||= { config => LWF::Config::Email->new };
    $p->{config} ||= LWF::Config::Email->new;
       
    my $self = $class->SUPER::new( $p );
  
    $self->logger( LWF::Logger->new( $self->config->log ) ) if $self->config->log;
  
    return $self;
}


## @method bool send_mail(hashref)
#  Метод отправки почты
#  @param hashref - ссылка на хэш параметров
#  \li to - получатель
#  \li subject - тема
#  \li body - тело
#  @return истина, если все ок
sub send_mail
{
    my ( $self, $p ) = @_;

    eval {
    
        my $smtp = Net::SMTP::SSL->new( $self->config->host, Port => $self->config->port, Debug => 0 );
        $smtp->auth( $self->config->login, $self->config->password); 
        $smtp->mail( $self->config->sender. "\n");
        $smtp->to( $p->{to} . "\n");
        $smtp->data();
        $smtp->datasend("From: " . $self->config->sender  . "\n");
        $smtp->datasend("To: " . $p->{to} . "\n");
        $smtp->datasend("Subject: " . $p->{subject} . "\n");
        $smtp->datasend("Content-Type: text/html; charset=utf-8\n");
        $smtp->datasend( "\n");
        $smtp->datasend( $p->{body} );
        $smtp->dataend();
        $smtp->quit;
    };

    LWF::Logger->new( $LWF::Logger::EVENT )->error( "send mail to: $p->{to} subject: $p->{subject} error: $@" ) if $@;

    $self->logger->info( "send mail to: $p->{to} subject: $p->{subject} status:" . ( $@ ? 'failed' : 'success' ) ) if $self->logger;

    return $@ ? 0 : 1;
}


1;
