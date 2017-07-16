## @file
#  @brief Реализация класса LWF::Notify
#  @author Mikhail Kirillov


## @class LWF::Notify
#  @brief Класс отправки уведомлений
#  @details На самом деле класс только формиует команды на отравку ведомлений, а сами уведомления отправляются через очередь
package LWF::Notify;


# пакеты
use strict;
use warnings;
use JSON;
use LWF::DBO;
use LWF::Exception::Runtime;


## @method void email(tmpl, vars)
#  Метод отпарвки email-уведомления
#  @param tmpl - имя шалона письма
#  @param vars - переменные
#  \li to - получатель
#  \li subject - тема
#  \li ... - характерыне для письма переменные
#  @return void
sub email
{
    my ( $self, $tmpl, $vars ) = @_;

    $vars ||= {};

    LWF::Exception::Runtime->new( "expect 'to' param" ) unless $vars->{to};
    LWF::Exception::Runtime->new( "template not enetred" ) unless $tmpl;

    $vars->{template} = $tmpl;

    my $data = to_json( $vars );

    LWF::DBO->create( 'LWF::Queue::Job', processor => 'LWF::Queue::Proc::Mail', data => $data, subqueue => 'email' );

    return;
}


1;

