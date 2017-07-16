## @file
#  @brief Реализация класса LWF::Server::Response::HTML
#  @athor Mikhail Kirillov


## @class LWF::Server::Response::HTML
#  @brief Класс ответов в формате HTML
package LWF::Server::Response::HTML;


# пакеты
use strict;
use warnings;
use Template;
use LWF::Exception::IO;
use LWF::ErrorSet;
use base 'LWF::Server::Response';


## @method int send( template, args )
#  Метод отпарвки ответа сгенерированной страницы
#  @param template - имя шаблона
#  @param args - ссылка на массив параметров шалона
#  @return число
sub send
{
    my ( $self, $template, $p ) = @_;

    LWF::Exception::IO->new( "template not entered" ) unless defined($template);

    $p ||= {};
    
    $p->{time_label} = int( time / 10800 );

    my $tt = Template->new(
        INCLUDE_PATH => $ENV{LWF_HOME} . '/templates',
        ENCODING => 'utf8',
        ABSOLUTE => 0,
        RELATIVE => 0,
    ) or LWF::Exception::IO->new($Template::ERROR);
    
    $self->set_content_type( 'text/html; charset=utf-8' );
    
    my $content;
    $tt->process( $template, $p, \$content ) or LWF::Exception::IO->new( $tt->error );
    $self->set_content( $content );
    
    return $self->SUPER::send;
}


## @method void send_default()
#  Метод топравки ответа по умолчанию
#  @return число
sub send_default
{
    my $self = shift;
    
    my $args = {};
    my $tmpl = 'ok.tt2';
    
    if( LWF::ErrorSet->has_errors )
    {
        $args = { errors => LWF::ErrorSet->get_errors, status => 'fail' };
        
        $self->set_code( LWF::ErrorSet->get_http_code );
        
        $tmpl = 'error.tt2';
    }
    
    return $self->send( $tmpl, $args );
}


## @method bool log_content()
#  Запрет логировать контент
#  @return bool
sub log_content {
    return 0;
}


1;
