package UserCommand;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use Response;
=del
my %STATUS = (
    E01 => 'Unknow error',
    E02 => 'Bad of command format',
    E03 => 'Unknow command',
    P00 => 'NULL',
    P01 => 'WELCOME',
    P02 => 'HELPLIST',
    P03 => 'IHELPLIST',
    P04 => 'USERLIST',
    C01 => 'ACNT',
    C02 => 'PSWD',
    C03 => 'INFO',
    S01 => 'SETACNT',
    S02 => 'SETPSWD',
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
=cut
use Class::Std::Utils; {
    my %user;
    my %status;
    my %resp;

    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;

        $user{ident $self} = User -> new();
        $status{ident $self} = '';
        $resp{ident $self} = Response -> new();
        
        $self -> command_analyze(cmd => $args{command}) if $args{command};
        
        return $self;
    }

    sub command_analyze {
        my $self = shift;
        my %args = @_;
        
        if ($args{cmd} =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            $resp{ident $self} -> user(account => $1, password => decode_base64($2));
            $resp{ident $self} -> command(type => $3, content => decode_base64($4));
            $resp{ident $self} -> analyze();
=del            
            if (!$command -> {type}) {
                $status{ident $self} = 'P01';
            }
            elsif ($command -> {type} =~ /^HELP$/) {
                if ($command -> {content} =~ /^\s*$/i) {
                    $status{ident $self} = 'P00';
                }
                elsif ($command -> {content} =~ /^\s*h\s*$/i) {
                    $status{ident $self} = 'P02';
                }
                elsif ($command -> {content} =~ /^\s*i\s*$/i) {
                    $status{ident $self} = 'P03';
                }
                elsif ($command -> {content} =~ /^\s*(a|s)\s*$/i) {
                    $status{ident $self} = $1 =~ /a/i ? 'C01' : 'C02';
                }
                elsif ($command -> {content} =~ /^\s*i\s+(.*?)\s*$/i) {
                    my $subcmd = $1;
                    if (exists $SETINFOS{$subcmd}) {
                        $status{ident $self} = 'C03';
                    }
                    else {
                        $status{ident $self} = 'E03';
                    }
                }
                else {
                    $status{ident $self} = 'E03';
                }
            }
            elsif ($command -> {type} =~ /^ACNT$/) {
                $status{ident $self} = 'S01';
            }
            elsif ($command -> {type} =~ /^PSWD$/) {
                $status{ident $self} = 'S02';
            }
            elsif ($command -> {type} =~ /^(?:I\+)(.*)$/) {
                my $subcmd = $1;
                $subcmd = lc $1;
                if (exists $SETINFOS{$subcmd}) {
                    $status{ident $self} = 'S03';
                }
            }
            else {
                $status{ident $self} = 'E03';
            }
=cut
        }
        else {
            $status{ident $self} = 'Bad of command format';
        }
    }
=del
    sub status {
        my $self = shift;
        
        return $status{ident $self};
    }
    
    sub status_line {
        my $self = shift;

        return $STATUS{$status{ident $self}};
    }
=cut
    sub response {
        my $self = shift;

        return $resp{ident $self} -> get_result() unless $status{ident $self};
=del
        if ($self -> status =~ /^P/) {
            return $resp{ident $self} -> get_static_response($self -> status_line);
        }
        elsif ($self -> status =~ /^C/) {
            return $resp{ident $self} -> get_cmd_response($self -> status_line);
        }
        elsif ($self -> status =~ /^S/) {
            return $resp{ident $self} -> get_set_response($self -> status_line);
        }
        else {
        }
=cut
    }
}

return 1;
