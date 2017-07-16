## @file
#  @brief Класс LWF::HTML::SubStr
#  @author Mikhail Kirillov


## @class LWF::HTML::SubStr
#  Класс извлечения не пустых строк
package LWF::HTML::SubStr;


# пакеты
use strict;
use warnings;
use utf8;
use LWF::HTML::Clean;
use LWF::Text;
use HTML::Parser;


# переменные
my @STACK = ();
my $LIMIT = 1;
my $COUNTER = 0;
my $LAST_DOT = 0;


## @method ( string, is_orig ) proc(html,limit,next)
#  Метод выполнения обрезания HTML
#  @param html - исходный HTML
#  @param limit - максимальное число символов в результате
#  @param next - код для продолжения чтения
#  @return ( html, is_orig )
sub proc {
    my ( $self, $html, $limit, $next ) = @_;

    # сначла нужно выполнить очистку
    $html = LWF::HTML::Clean->proc( $html );
    
    @STACK = ();
    $LIMIT = $limit;
    $COUNTER = 0;
    $LAST_DOT = 0;
    
    my $parser = HTML::Parser->new( 
                     api_version => 3,
                     handlers => {
                         start => [ \&tag_start, 'self, tagname, attr, text' ],
                         end   => [ \&tag_end, 'self, tagname, text' ],
                         text  => [ \&text, 'self, dtext' ],
                     },
                 );

    $parser->{res} = '';
    
    $parser->parse( $html );
    $parser->eof;
    
    my $res = $parser->{res};
    
    $res .= ( $LAST_DOT ? '' : '&#8230;' ) . ( $next || '' ) if $COUNTER >= $LIMIT; 
    
    $res .= join( '', map { "</$_>" } reverse @STACK );
    
    return $res, $COUNTER < $LIMIT;
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
    
    return if $COUNTER >= $LIMIT;
    
    $tag = lc $tag;
    
    push @STACK, $tag;
    $self->{res} .= $text;
}

## @fn void tag_start(self,tag,text)
#  Обработчик открытия тега
#  @param self - парсер
#  @param tag - тег
#  @param text - текст
#  @return void
sub tag_end {
    my ( $self, $tag, $text ) = @_;

    return if $COUNTER >= $LIMIT;
    
    $tag = lc $tag;
    
    if( $STACK[-1] eq $tag ) {
        $self->{res} .= "</$tag>";
        pop @STACK;
        return;
    }
    
    my @positions = grep { $STACK[$_] eq $tag } ( 0 .. $#STACK );
    
    if( scalar(@positions) ) {
        
        my $num = $positions[-1];
        $self->{res} .= join( '', map { "</$STACK[$_]>" } reverse ( $num .. $#STACK ) );
        splice @STACK, $positions[-1];
    }
}


## @fn void text(self,text)
#  Обработчик текстового блока
#  @param self - парсер
#  @param text - текст
#  @return void
sub text {
    my ( $self, $text ) = @_;
    
    return if $COUNTER >= $LIMIT;
    
    my @seq = $text =~ /(\S+)/sg;
    
    foreach my $s ( @seq ) {
        my $l = length $s;
        
        if( $COUNTER + $l + 1 <= $LIMIT ) {
            $LAST_DOT = $s =~ /\.\s*$/s;
            $self->{res} .= ' ' . __PACKAGE__->encode_html($s);
        }
        
        $COUNTER += $l + 1;
    }
}


## @method string encode_html(string)
#  метод кодирования входной строки в HTML строку
#  @param string - произвольная строка
#  @return строка с экранирование специальных символов
sub encode_html {
    my ( $self, $str ) = @_;

    $str ||= '' if !defined($str);

    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/&/&amp;/gm;
    $str =~ s/'/&apos;/gm;
    $str =~ s/"/&quot;/gm;
    $str =~ s/</&lt;/gm;
    $str =~ s/>/&gt;/gm;

    return $str;
}


1;
