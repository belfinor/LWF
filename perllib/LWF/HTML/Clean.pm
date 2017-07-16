## @file
#  @brief Класс LWF::HTML::Clean
#  @author Mikhail Kirillov


## @class LWF::HTML::Clean
#  Класс очистки HTML
package LWF::HTML::Clean;


# пакеты
use strict;
use warnings;
use utf8;
use HTML::Parser;


# глобальные данные
my %TAGS = ();          # допустимые теги
my %EAT = ();           # теги, которые нужно състь
my @STACK;              # стек открытых тегов
my @ERASE;              # стек стирания



## @method string clean(html)
#  Метод выполнения очистки
#  @param html - исходный HTML
#  @return текст
sub proc {
    my ( $self, $html ) = @_;

    @STACK = ();
    @ERASE = ();
    
    my $parser = HTML::Parser->new( 
                     api_version => 3,
                     handlers => {
                         start => [ \&tag_start, 'self, tagname, attr, text' ],
                         end   => [ \&tag_end, 'self, tagname, text' ],
                         text  => [ \&text, 'self, text' ],
                     },
                 );

    $parser->{res} = '';
    
    $parser->parse( $html );
    $parser->eof;
    
    my $res = $parser->{res};
    
    $res .= join( '', map { "</$_>" } reverse @STACK );
    
    return $res;
}


## @fn void tag_start(self,tag,attr,text)
#  Обработчик открытия тега
#  @param self - парсер
#  @param tag - тег
#  @param attr - хэш атрибутов
#  @param text - текст
#  @return void
sub tag_start {
    my ( $self, $tag, $attr, $text ) = @_;
    
    $tag = lc $tag;
    
    if( scalar(@ERASE) ) {
        push @ERASE, $tag;
        return;
    }
    
    if( $EAT{$tag} ) {
        push @ERASE, $tag if $tag ne 'meta';
        return;
    }
    
    if( $TAGS{$tag} ) {
        push @STACK, $tag;
        $self->{res} .= $text;
    }
}

## @fn void tag_start(self,tag,text)
#  Обработчик открытия тега
#  @param self - парсер
#  @param tag - тег
#  @param text - текст
#  @return void
sub tag_end {
    my ( $self, $tag, $text ) = @_;

    $tag = lc $tag;
    
    if( scalar(@ERASE) ) {
    
        if( $ERASE[-1] eq $tag ) {
            pop @ERASE;
            return;
        }
        
        my @positions = grep { $ERASE[$_] eq $tag } ( 0 .. $#ERASE );
        
        if( scalar(@positions) ) {
            splice @ERASE, $positions[-1];
            return;
        }
    }
    else {
        
        if( $STACK[-1] && $STACK[-1] eq $tag ) {
            $self->{res} .= "</$tag>";
            pop @STACK;
            return;
        }
        
        unless( $TAGS{$tag} ) {
            return;
        }
        
        my @positions = grep { $STACK[$_] eq $tag } ( 0 .. $#STACK );
        
        if( scalar(@positions) ) {
            
            my $num = $positions[-1];
            $self->{res} .= join( '', map { "</$STACK[$_]>" } reverse ( $num .. $#STACK ) );
            splice @STACK, $positions[-1];
        }
    }
}


## @fn void text(self,text)
#  Обработчик текстового блока
#  @param self - парсер
#  @param text - текст
#  @return void
sub text {
    my ( $self, $text ) = @_;
    
    unless( scalar( @ERASE ) ) {
        $self->{res} .= $text;
    }
}


## @method void init() 
#  Метод выполнения инициализации, при загрузки модуля выполняется автоматом
#  @return void
sub init {

    %TAGS = map { $_ => 1 } ( qw( a article b big br button code color div em figure font form h1 h2 h3 h4 h5 h6 header hr 
                                  i img input li ol option p pre
                                  section small span strike strong table tbody td textarea th thead tr u ul) );
    %EAT  = map { $_ => 1 } ( qw( head script style meta iframe applet frame frameset) );
}


## @method void enable_tags(array)
#  Метод разрешения использования тегов
#  @return void
sub enable_tags {
    my ( $self, @tags ) = @_;
    
    foreach my $t ( @tags ) {
        $TAGS{ lc $t } = 1;
        $EAT{ lc $t } = 0;
    }
}


## @method void disable_tags(array)
#  Метод отклбчения тегов
#  @return void
sub disable_tags {
    my ( $self, @tags ) = @_;
    
    foreach my $t ( @tags ) {
        $TAGS{lc $t} = 0;
    }
}


## @method void disable_all_tags(array)
#  Метод отключения всех тегов
#  @retrun void
sub disable_all_tags {
    %TAGS = ();
}


## @method void eat_tags(array)
#  Метод добавления тегов в список на съедение
#  @param array - массив имен тегов
#  @return void
sub eat_tags {
    my ( $self, @tags ) = @_;
    
    foreach my $t ( @tags ) {
        $TAGS{ lc $t } = 0;
        $EAT{ lc $t } = 1;
    }
}


## @method void reset_eat_tags()
#  Метод сброса тегов на съедение
#  @return oid
sub reset_eat_tags {
    %EAT = ();
}


# запус инициализации
init();


1;
