#  @file
#  @brief Реализация класса LWF::Net::Domain
#  @author Mikhail Kirillov


## @class LWF::Net::Domain
#  Класс домена
package LWF::Net::Domain;


use strict;
use warnings;
use utf8;
use Net::IDN::Encode qw(:all);
use base 'LWF';


# генерация методов доступа
__PACKAGE__->make_accessors(
    domain     => 'domain',
    domain_idn => 'domain_idn',
    name       => 'name',
    name_idn   => 'name_idn',
    zone       => 'zone',
    zone_idn   => 'zone_idn',
);


## @method object new(name)
#  Конструктор объекта, на вход принимает имя домена. В случае еспеха домен
#  @name - имя домена
#  @return объект LWF::Net::Domain
sub new
{
	my ( $class, $name ) = @_;

	eval { $name = lc domain_to_ascii($name); };
	return if $@;

	# теперь выполним проверку, того что декодировали
	return unless $name =~ /^(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+(?:[a-z]{2,}|(?:xn\-\-.+))$/i;
	return if $name =~ /^..--/ && $name !~ /^xn/;

	my $idn_name = lc domain_to_unicode($name);
	
	my $res = {
		domain     => $name,
		domain_idn => $idn_name,
	};
	
	$idn_name =~ /^[^\.]+/i;
	
	$res->{name_idn} = $&;
	$res->{zone_idn} = $';
	$res->{zone_idn} =~ s/^\.//;
	
	$name =~ /^[^\.]+/i;
	
	$res->{name} = $&;
	$res->{zone} = $';
	$res->{zone} =~ s/^\.//;
	
	# проверка на случай IDN-а
	if( $res->{zone_idn} =~ /^[а-яё0-9-]+$/ )
	{
		return unless $res->{name_idn} =~ /^[а-яё0-9][а-яё0-9-]*[а-яё0-9]?$/;
	}
	
	return bless( $res, $class );
}


1;
