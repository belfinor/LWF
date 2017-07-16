## @file
#  @brief Реализация класса LWF::Interface::HTTP::RSS
#  @author Mikhail Kirillov


## @class LWF::Interface::HTTP::RSS
#  Класс поучения RSS ленты
package LWF::Interface::HTTP::RSS;


# пакеты
use strict;
use warnings;
use utf8;
use LWF::Logger;
use LWF::XML::Reader;
use base 'LWF::Interface::HTTP';


## @method arrayref get(url)
#  Метод загрузки RSS ленты
#  @param url - адрес ленты
#  @return ссылка на массив записей ленты или NULL в лучае неудачи
sub get {
    my ( $self, $url ) = @_;

    my $resp = $self->request( {
        url         => $url,
        method      => 'GET',
        timeout     => 5,
        use_cookies => 1,
    } );

    my $log = LWF::Logger->new( $LWF::Logger::EVENT );
    
    if( $resp && $resp->code == 200 ) {
        $log->info( "GET " . $url . " HTTP 200" );

        my $xml = LWF::XML::Reader->new( $resp->decoded_content );

        unless( $xml ) {
            $log->error( "GET " . $url . " RSS parse error" );
            return;
        }

        my @data;

        foreach my $page ( @{$xml->nodes('/rss/channel/item')} )
        {
            push @data, {
                title      => $page->get_value( './title' ) || '',
                link       => $page->get_value( './link' ) || '',
                time       => $page->get_value( './pubDate' ) || '',
                decription => $page->get_value( './description' ) || '',
            };
        }

        return \@data;
    }
    
    !$resp ? $log->error( "GET " . $url . " HTTP 500 Read timeout" ) : $log->error( "GET " . $url . " HTTP " . $resp->code );

    return;

    
}


1;

