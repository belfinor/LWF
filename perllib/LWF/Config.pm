## @file
#  @brief Реализация класса LWF::Config
#  @author Mikhail Kirillov


## @class LWF::Config
#  @brief Базовый класс для работы с конфигурационными файлами
#  @details Помимо того, что класс является базовым классом для всех объектов конфигуарции он также отвечает, за то что
#  для оббъекта каждого класса создается синглтон. В случае ошибок генерирует \b LWF::Exception::IO
#  @see LWF::Object
#  @see LWF::Exception::IO
package LWF::Config;


# пакеты
use strict;
use warnings;
use utf8;
use YAML::Tiny;
use LWF::Exception::IO;
use base 'LWF';


# кэш конфигов, чтобы потом не думать о том, что закешировано, а что нет
my %CACHE = ();


# в потомаках нужно будет прописывтьа методы длоступа
# __PACKAGE__->make_accessors( name1 => '+setting/name1', name2 => '+setting/name2', ... )
# Плюс означент, что метод доступа поддерживает изменение значения


## @method obj new(filename)
#  Метод получает на вход конфигурационный файл и создает объект для работы с конфигурацией
#  @param filename - имя конфигурационного файла, если не задано, то используется дефолтный
#  @return obj - объект LWF::Config::*
sub new
{
    my ($class, $filename) = @_;

    # здесь фокус, связь между классом и конфигом один к одному
    my $key = $class . '=>' . $filename;

    return $CACHE{$key} if $CACHE{$key};

    my $self    = bless {
        setting        => {},
        errstr         => undef,
        filename       => $filename,
    }, $class;

    # получаем имя конфига и сразу загружаем его
    $self->_parse;

    $CACHE{$key} = $self;

    return $self;
}


## @method void _parse(void)
#  Метод выполнения загрузки конфигурационного файла на базе YAML:Tiny
#  @return void
sub _parse
{
    my $self = shift;

    my $filename = $self->{filename};

    # если файл задан, то пробуем работать с ним
    if( $filename )
    {
        # если имя файла относительное, то считаем его относительно директории ФМ-а
        if( $filename !~ m!^/! )
        {
            my $t = $ENV{LWF_HOME};
            $t =~ s/\/$//;
            $filename = $t . '/' . $filename;
        }
        
    }
    # если файл не был получен, тогда все просто пытаем взять основной конфиг
    else
    {
        $filename = $ENV{LWF_HOME};
        $filename =~ s/\/$//;
        $filename .= '/etc/lwf.yaml';
    }

    # если файл не найден на диске
    unless( -e $filename )
    {
        LWF::Exception::IO->new( "$filename not found" );
        return;
    }

    # пробуем прочитать YAML
    my $yaml = YAML::Tiny->new;
    my $obj = $yaml->read( $filename ) or LWF::Exception::IO->new( "$filename: " . $yaml->errstr );
        
    $self->{setting} = $obj->[0];

    return;
}


1;
