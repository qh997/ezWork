package UserCommand;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use Response;

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
        }
        else {
            $resp{ident $self} -> set_warning("Bad of command format.\n");
        }
    }

    sub response {
        my $self = shift;

        return $resp{ident $self} -> get_result();
    }
}

return 1;
