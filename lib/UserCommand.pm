package UserCommand;

use warnings;
use strict;
use version;
our $VERSION = qv('0.0.1');

my %STATUS = (
    E01 => 'Unknow error',
    E02 => 'Bad of command format',
    E03 => 'Unknow command',
    P01 => 'WELCOME',
    C01 => 'HELP',
    S01 => 'ACNT',
    S02 => 'PSWD',
);

use Class::Std::Utils; {
    my %status;
    my %user;
    my %command;
    
    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;
        
        $status{ident $self} = 0;
        $user{ident $self} = {
            account => '',
            password => '',
        };
        $command{ident $self} = {
            type => '',
            content => '',
        };
        
        $self -> command_analyze(cmd => $args{command}) if $args{command};
        
        return $self;
    }
    
    sub command_analyze {
        my $self = shift;
        my %args = @_;
        
        if ($args{cmd} =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            $user{ident $self} -> {account} = $1;
            $user{ident $self} -> {password} = $2;
            $command{ident $self} -> {type} = $3;
            $command{ident $self} -> {content} = $4;
            
            if (!$command{ident $self} -> {type}) {
                $status{ident $self} = 'P01';
            }
            elsif ($command{ident $self} -> {type} =~ /^HELP$/) {
                $status{ident $self} = 'C01';
            }
            elsif ($command{ident $self} -> {type} =~ /^ACNT$/) {
                $status{ident $self} = 'S01';
            }
            elsif ($command{ident $self} -> {type} =~ /^PSWD$/) {
                $status{ident $self} = 'S02';
            }
            elsif ($command{ident $self} -> {type} =~ /^(?:I\+)(.*)$/) {
                $status{ident $self} = '';
            }
            else {
                $status{ident $self} = 'E03';
            }
        }
        else {
            $status{ident $self} = 'E02';
        }
    }
    
    sub status {
        my $self = shift;
        
        return $status{ident $self};
    }
    
    sub status_line {
        my $self = shift;

        return $STATUS{$status{ident $self}};
    }
}

return 1;
