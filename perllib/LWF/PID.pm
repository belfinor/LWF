## @file
#  @brief Реализация класса LWF::PID
#  @author Mikhail Kirillov


## @class LWF::PID
#  @brief Класс PID файла
package LWF::PID;
use LWF::Exception::IO;


# глобальные данные
my $FILE;


## @method void init(name)
#  Метод открытия pid файла. Если не удается открыть, то скрипт завершает свое выполнение
#  @return void
sub init
{
    my ( $class, $name ) = @_;
    
    LWF::Exception::IO->new( "pid file name isn't entered" ) if !defined($name) || $name eq ''; 
    
    $name = $ENV{LWF_HOME} . '/' . $name if $name !~ m!^/!;

    $FILE = $name;
    
    $class->_is_running;
    $class->_save_pid;
    
    return;
}


## @method void _is_running(void)
#  Метод проверки нет ли уже запущенной копии процесса. Завершает процесс, если есть рабочай копия
#  @return void
sub _is_running
{
    my $class = shift;
    
    return unless -e $FILE;
    
    open( FH, '<', $FILE ) or LWF::Exception::IO->new( "Open file $FILE error" );
    my $pid = <FH>;
    close FH;
    
    return unless $pid;
    
    # пошлем cигнал, чтобы убедится что процесс не запущен
    exit 0 if kill( 0, $pid );
    
    return;
}



## @method void _save_pid(void)
#  Метод записи pid файла пока работает процесс
#  @return void
sub _save_pid
{
	my $self = shift;
	
	open( FH, '>', $FILE ) or  LWF::Exception::IO->new( "Open file $FILE for write error" );;
	print FH $$;
	close FH;
	
	return;
}


## @method void finish(void)
#  Метод очистки пид файла по факту завершения скрипта
sub finish
{
	my $self = shift;
	open( FH, '>', $FILE );
	print FH '';
	close FH;
}


1;

