## @file
#  @brief Класс LWF::HTML::Strings
#  @author Mikhail Kirillov


## @class LWF::HTML::Strings
#  Класс извлечения не пустых строк
package LWF::HTML::Strings;


# пакеты
use strict;
use warnings;
use utf8;
use LWF::HTML::Clean;
use LWF::Text;
use HTML::Parser;


## @method string clean(html)
#  Метод получения списка непустых текстов из HTML
#  @param html - исходный HTML
#  @return текст
sub proc {
    my ( $self, $html ) = @_;

    # сначла нужно выполнить очистку
    $html = LWF::HTML::Clean->proc( $html );
    
    my $parser = HTML::Parser->new( 
                     api_version => 3,
                     handlers => {
                         text  => [ \&text, 'self, dtext' ],
                     },
                 );

    $parser->{res} = [];
    
    $parser->parse( $html );
    $parser->eof;
    
    return $parser->{res};
}


## @fn void text(self,text)
#  Обработчик текстового блока
#  @param self - парсер
#  @param text - текст
#  @return void
sub text {
    my ( $self, $text ) = @_;
    
    if( $text !~ /^\s+$/s ) {
        push @{$self->{res}}, LWF::Text->trim($text);
    }
}


1;
