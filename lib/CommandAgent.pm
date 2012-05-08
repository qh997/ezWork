package CommandAgent;

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.2');

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
    my %cont;

    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;

        $resp{ident $self} = Response -> new();
        $cont{ident $self} = '';
        
        $self -> command_analyze(cmd => $args{command}) if $args{command};
        
        return $self;
    }

    sub command_analyze {
        my $self = shift;
        my %args = @_;

        if (my ($acnt, $pswd, $type, $c) = $args{cmd} =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            $cont{ident $self} = decode64($c);
            if ($type) {
                $resp{ident $self} -> user(account => $acnt, password => decode64($pswd));
                $resp{ident $self} -> command(type => $type, content => $cont{ident $self});
            }
            else {
                $resp{ident $self} -> command(type => 'HELP', content => 'A');
                $resp{ident $self} -> welcome();
            }
            $resp{ident $self} -> analyze();
        }
        else {
            $resp{ident $self} -> set_warning("Bad of command format.\n");
        }
    }

    sub response {
        my $self = shift;

        my ($cmd, $msg) = $resp{ident $self} -> get_result();
        my $pmt = exists $PROMPTS{$cmd} ? $PROMPTS{$cmd} : $SPROMPT;
        debug("Return command = [$cmd]");

        my $resp = '';
        $resp .= get_program_replace('CHANGE_CMD', CMD => $cmd);

        if ($cmd eq 'ACOK') {
            $resp .= get_program_replace('LOGIN', ACNT => $cont{ident $self});
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
            $resp .= get_program_replace('MSG_PRINT', MSG => $msg.$pmt);
            $resp .= get_program('USER_INPUT');
        }

        return encode64($resp);
    }
}

return 1;