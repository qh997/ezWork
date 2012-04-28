package CommandAgent;

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.1');

use General;
use Response;

my $HPROMPT = '?> ';
my $SPROMPT = ' > ';
my %PROMPTS = (
    'HELP' => $HPROMPT,
    'ACOK' => $HPROMPT,
    'PWOK' => $HPROMPT,
);

use Class::Std::Utils; {
    my %resp;

    sub new {
        my ($class, %args) = @_;
        my $self = bless anon_scalar(), $class;

        $resp{ident $self} = Response -> new();
        
        $self -> command_analyze(cmd => $args{command}) if $args{command};
        
        return $self;
    }

    sub command_analyze {
        my $self = shift;
        my %args = @_;

        if ($args{cmd} =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            $resp{ident $self} -> user(account => $1, password => decode64($2));
            $resp{ident $self} -> command(type => $3, content => decode64($4));
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

        return $cmd.':'.encode64($msg.$pmt);
    }
}

return 1;
