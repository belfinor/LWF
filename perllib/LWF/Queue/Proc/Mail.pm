## @file
#  @brief Реализация класса LWF::Queue::Proc::Mail
#  @author Mikhail Kirillov


## @class LWF::Queue::Proc::Mail
#  @brief Класс процессора отправки писем
package LWF::Queue::Proc::Mail;


# пакеты
use strict;
use warnings;
use JSON;
use Template;
use LWF::Exception::IO;
use LWF::Interface::Email;


## @method bool process(job)
#  Метод обработки задания на отправку письма
#  @param job - задание
#  @return истина, если все ок
sub process
{
    my ( $self, $job ) = @_;
    
    # генерация тела письма
    my $tmpl = Template->new(
        INCLUDE_PATH => $ENV{LWF_HOME} . '/templates',
        ENCODING => 'utf8',
        ABSOLUTE => 0,
        RELATIVE => 0,
    ) or LWF::Exception::IO->new( $Template::ERROR );

    my $data = from_json( $job->data );

    my $body;

    $tmpl->process( $data->{template}, $data->{params}, \$body ) or LWF::Exception::IO->new( $tmpl->error );

    # отправка письма
    my $email = LWF::Interface::Email->new;

    return $email->send_mail( { to => $data->{to}, subject => $data->{subject}, body => $body } );
}


1;

