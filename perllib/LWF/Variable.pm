## @file
#  @brief Реализация класса LWF::Variable
#  @author Mikhail Kirillov


## @class LWF::Variable
#  @brief Класс системных переменных
package LWF::Variable;


# пакеты
use strict;
use warnings;
use LWF::DBO;


## @method string get(name)
#  Метод получения значение переменной
#  @param name - имя переменной
#  @return значение или undef
sub get {
    my ( $self, $name ) = @_;
    return unless defined($name);
    return LWF::DBO->sql->select_value( 'SELECT value FROM variables WHERE name = ? LIMIT 1', $name );
}


## @method void string set(name,value[,group])
#  Метод задания значение переменной и перенос ее в группу, если указана
#  @param name - имя переменной
#  @param value - значение
#  @param grp - группа, может отсутствовать
#  @return void
sub set {
    my ( $self, $name, $value, $group ) = @_;

    LWF::DBO->sql->select_value( 'UPDATE variables SET value = ?, grp = COALESCE(?,grp) WHERE name = ? RETURNING id', $value, $group, $name ) or
    LWF::DBO->sql->select_value( "INSERT INTO variables(name,grp,value) VALUES (?,COALESCE(?,''),?) RETURNING id", $name, $group, $value );

    return;
}


## @method hashref group(name)
#  Метод поулчения всех переменных в группе
#  @param group - имя группы
#  @return ссылка на хэш (переменная => значение)
sub group{
    my ( $self, $name ) = @_;
    my %h = map { $_->{name} => $_->{value} } @{LWF::DBO->sql->select_list( 'SELECT name, value FROM variables WHERE grp = ?', $name )};
    return \%h;
}


1;
