## @file
#  @brief Класс LWF::HTML::Links
#  @author Mikhail Kirillov


## @class LWF::HTML::Links
#  Класс извлечения всех ссылок из HTML документа
package LWF::HTML::Links;


# пакеты
use strict;
use warnings;
use utf8;
use HTML::Parser;


## @method string proc(html)
#  Метод выполнения извелчения всех ссылок из документа
#  @param hashref - ссылка на хэш параметров
#  \li html - исходный html
#  @return текст
sub proc {
    my ( $self, $html ) = @_;
    
    my $parser = HTML::Parser->new( 
                     api_version => 3,
                     handlers => {
                         start => [ \&tag_start, 'self, tagname, attr, text' ],
                     },
                 );

    $parser->{res} = {};
    
    $parser->parse( $html );
    $parser->eof;
    
    return [ keys %{$parser->{res}} ];
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
    
    if( $tag eq 'a' ) {
        my $href = $attr->{href};
        
        return if $href =~ /^#/;
        
        $self->{res}{$href} = 1;
    }
}


1;
