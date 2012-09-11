package CommandAgent;

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.5');

use General;
use Response;
use Programs;

my $HPROMPT = '?> ';
my $SPROMPT = ' > ';
my %PROMPTS = (
    'HELP' => $HPROMPT,
    'ACOK' => $HPROMPT,
    'PWOK' => $HPROMPT,
);

use Class::Std::Utils; {
    my %resp;
    my %acnt;
    my %pswd;
    my %type;
    my %cont;

    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;

        $resp{ident $self} = Response->new();
        $acnt{ident $self} = '';
        $pswd{ident $self} = '';
        $type{ident $self} = '';
        $cont{ident $self} = '';
        
        $self->command_analyze(cmd => $args{command}) if $args{command};
        
        return $self;
    }

    sub command_analyze {
        my $self = shift;
        my %args = @_;

        if ($args{cmd} =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            $acnt{ident $self} = $1;
            $pswd{ident $self} = decode64($2);
            $type{ident $self} = $3;
            $cont{ident $self} = decode64($4);
            if ($type{ident $self}) {
                $resp{ident $self}->user(
                    account => $acnt{ident $self},
                    password => $pswd{ident $self},
                );
                $resp{ident $self}->command(
                    type => $type{ident $self},
                    content => $cont{ident $self},
                );
            }
            else {
                $resp{ident $self}->command(type => 'HELP', content => 'A');
                $resp{ident $self}->welcome();
            }
            $resp{ident $self}->analyze();
        }
        else {
            $resp{ident $self}->set_warning("Bad of command format.\n");
        }
    }

    sub response {
        my $self = shift;

        my ($cmd, $msg) = $resp{ident $self}->get_result();
        my $pmt = exists $PROMPTS{$cmd} ? $PROMPTS{$cmd} : $SPROMPT;
        debug("Return command = [$cmd]");

        my $resp = '';
        $resp .= get_program_replace('CHANGE_CMD', CMD => $cmd);

        if ($cmd eq 'ACOK') {
            $cont{ident $self} =~ s/@.*//;
            $resp .= get_program_replace('LOGIN', ACNT => $cont{ident $self});
            if (CheckInitPassword($cont{ident $self})) {
                $resp .= get_program_replace('REGISTER', PSWD => 'neusoft');
            }
            $resp .= get_program_replace('CHANGE_CMD', CMD => 'HELP');
            $resp .= get_program_replace('MSG_PRINT', MSG => $msg);
            $resp .= get_program_replace('USER_INPUT_AGENT', INPUT => 'S');
        }
        elsif ($cmd eq 'PWOK') {
            $resp .= get_program_replace('REGISTER', PSWD => $cont{ident $self});
            $resp .= get_program_replace('CHANGE_CMD', CMD => 'HELP');
            $resp .= get_program_replace('MSG_PRINT', MSG => $msg.$pmt);
            $resp .= get_program('USER_INPUT');
        }
        else {
            if (!$acnt{ident $self} && $cmd ne 'ACNT') {
                $resp .= get_program_replace('CHANGE_CMD', CMD => 'HELP');
                $resp .= get_program_replace('MSG_PRINT', MSG => $msg);
                $resp .= get_program_replace('USER_INPUT_AGENT', INPUT => 'A');
            }
            else {
                $resp .= get_program_replace('MSG_PRINT', MSG => $msg.$pmt);
                $resp .= get_program('USER_INPUT');
            }
        }

        return encode64($resp);
    }

    sub CheckInitPassword {
        my $account = shift;

        my $chk = Response->new();
        $chk->user(
            account => $account,
            password => '',
        );
        $chk->command(
            type => 'PSWD',
            content => 'neusoft',
        );
        $chk->analyze();
        my ($cmd, $msg) = $chk->get_result();
        print $cmd."\n";
        print $msg."\n";
        return $cmd eq 'PWOK' ? 1 : 0;
    }
}

return 1;