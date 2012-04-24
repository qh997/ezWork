package UserCommand;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use User;
use Response;

my %STATUS = (
    E01 => 'Unknow error',
    E02 => 'Bad of command format',
    E03 => 'Unknow command',
    P00 => 'NULL',
    P01 => 'WELCOME',
    P02 => 'HELPLIST',
    P03 => 'IHELPLIST',
    P04 => 'USERLIST',
    S01 => 'ACNT',
    S02 => 'PSWD',
    S03 => 'SETINFO',
);

my %SETINFOS = (
    'task' => 'txtTask',
    'proj' => 'selProject',
    'proj' => 'selProTask',
    'actv' => 'selActType1',
    'sact' => 'selActType2',
    'prom' => 'selModule1',
);

use Class::Std::Utils; {
    my %status;
    my %user;
    my %command;

    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;
        
        $status{ident $self} = 0;
        $user{ident $self} = User -> new();
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
            $user{ident $self} -> settings(account => $1, password => $2);
            $command{ident $self} -> {type} = $3;
            $command{ident $self} -> {content} = decode_base64($4);
            
            if (!$command{ident $self} -> {type}) {
                $status{ident $self} = 'P01';
            }
            elsif ($command{ident $self} -> {type} =~ /^HELP$/) {
                if ($command{ident $self} -> {content} =~ /^\s*$/i) {
                    $status{ident $self} = 'P00';
                }
                elsif ($command{ident $self} -> {content} =~ /^\s*h\s*$/i) {
                    $status{ident $self} = 'P02';
                }
                elsif ($command{ident $self} -> {content} =~ /^\s*i\s*$/i) {
                    $status{ident $self} = 'P03';
                }
                elsif ($command{ident $self} -> {content} =~ /^\s*(a|s)\s*$/i) {
                    $status{ident $self} = $1 =~ /a/i ? 'S01' : 'S02';
                }
                elsif ($command{ident $self} -> {content} =~ /^\s*i\s+(.*?)\s*$/i) {
                    my $subcmd = $1;
                    if (exists $SETINFOS{$subcmd}) {
                        $status{ident $self} = 'S03';
                    }
                    else {
                        $status{ident $self} = 'E03';
                    }
                }
                else {
                    $status{ident $self} = 'E03';
                }
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

    sub response {
        my $self = shift;

        my $rsps = Response -> new();
        if ($self -> status =~ /^P/) {
            return 'HELP:'.$rsps -> get_static_response($self -> status_line);
        }
        elsif ($self -> status =~ /^S/) {
        }
    }
}

return 1;
