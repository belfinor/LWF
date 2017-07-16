## @file 
#  @brief Реализация класса LWF::Server::Router
#  @author Mikhail Kirillov


## @class LWF::Server::Router
#  Класс роутера запросов
package LWF::Server::Router;


# используемые пакеты
use strict;
use warnings;
use utf8;
use Encode;
use YAML::Tiny;
use URI::Escape;
use LWF::Server::Request;
use LWF::Exception::IO;


# дерево вызовов
my $FILE = $ENV{LWF_HOME} . '/data/router.yaml';
my $TREE = ( YAML::Tiny->new->read( $FILE ) or LWF::Exception::IO->new("Load router error ${YAML::Tiny::errstr}" ) )->[0];


## @method void process(void)
#  Метод выполнения разбора урала и передача обработки в нужный метод нужного контроллера
#  @return void
sub process
{
    my $class = shift;

    my $uri    = LWF::Server::Request->uri;
    my $method = LWF::Server::Request->method;
    my %param_data;
    my $level  = $TREE;
    
    return undef if $method !~ /^(GET|POST|PUT|DELETE|HEAD)$/;
    
    $uri =~ s/\/+/\//g;
    $uri =~ s/\/$//;
    $uri = Encode::decode_utf8(uri_unescape($uri));
    
    my $controller = undef;
    my $tail = undef;
    
    $controller = $level->{_controller} if $level->{_controller};
    
    if( $level->{_tail} )
    {
        $tail = $level->{_tail};
        $param_data{$tail} = [];
    }

    
    # проход по всем узлам урлам и влидация контекта
    while( $uri =~ s!^/([^/]+)!! ) 
    {
        my $item = $1;
        
        # если мы в  режиме хвоста, то просто кладем данные в массив
        if( $tail )
        {
            push @{$param_data{$tail}}, $item;
            next;
        }
        
        my $branch = undef;

        # поиск подходящего узла на уровне
        foreach my $rule ( keys %{$level} )
        {
            next if $rule eq '_default' || $rule eq '_param';

            if( $rule =~ /^~/ ) 
            {
                next unless "~$item" =~ /^$rule$/;
                my $param_name = $level->{$rule}{'_param'};
                $param_data{$param_name} = $item if $param_name;
            } 
            else 
            {
                next unless $item eq lc($rule);
            }

            $branch = $rule;
            last;
        }

        return undef unless $branch;
        
        $level = $level->{$branch};
        $controller = $level->{_controller} if $level->{_controller};
        
        # если мы находим инструкцию _jump, то выполняем переход на определение блока
        if( $level->{_jump} )
        {
            $level = $TREE->{ $level->{_jump} } or return;
            next;
        }
        
        # если на этом этапе включился режим отработки хвоста
        if( $level->{_tail} )
        {
            $tail = $level->{_tail};
            $param_data{$tail} = [];
        }
    }
    
    my $action = $level->{ '_' . lc($method) };
    return undef unless $level && $controller && $action;

    # инициализация процесса передачи управления контроллеру
    return {
        controller => $controller,
        method     => $action,
        params     => \%param_data,
    };
}


1;

