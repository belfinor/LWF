## @file
#  @brief Релаизация класса LWF::Net::URL
#  @author Mikhail Kirillov


## @class LWF::Net::URL
#  @brief Класс адреса
package LWF::Net::URL;


# пакеты
use strict;
use warnings;
use utf8;
use URI::URL;
use LWF::Net::Domain;
use base 'LWF';


__PACKAGE__->make_accessors(
  url      => '+url',
  host     => '+host',
  host_idn => '+host_idn',
  port     => '+port',
  protocol => '+protocol',
  path     => '+path',
  params   => '+params',
);


## @method obj new(url)
#  Метод создания объека по адресу
#  @return obj, если все ок
sub new {
    my ( $class, $url ) = @_;
    
    my $self = $class->SUPER::new;    

    eval {
     
      my $obj = URI::URL->new( $url );
   
      my $hd = LWF::Net::Domain->new( $obj->host );

      $self->url( $url );
      $self->host( $hd->domain );
      $self->host_idn( $hd->domain_idn );
      $self->port( $obj->port );
      $self->protocol( lc $obj->scheme );
      $self->path( $obj->path );
      $self->params( $obj->query );
    };
 
    return $self if $self->host;

    return; 
}


1;

