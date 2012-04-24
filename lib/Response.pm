package Response;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use User;
use Words;

my $PROMPT = '?> ';
my %MOVEMENT = (
    'NULL' => 'HELP',
);

use Class::Std::Utils; {
    my %user;
    my %command;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $user{ident $self} = undef;
        $command{ident $self} = {
            type => '',
            content => '',
        };
        
        return $self;
    }

    sub user {
        my $self = shift;
        my %args = @_ ? @_ : ();

        $user{ident $self} = User -> new();
        return $user{ident $self} -> settings(%args);
    }

    sub command {
        my $self = shift;
        my %args = @_;

        if (keys %args) {
            $command{ident $self}{type} = $args{type} if $args{type};
            $command{ident $self}{content} = $args{content} if $args{content};
        }

        return {
            type => $command{ident $self}{type},
            content => $command{ident $self}{content},
        };
    }

    sub get_static_response {
        my $self = shift;
        my $static_words = shift;

        if ($static_words eq 'WELCOME') {
            return _get_next()._encode64(get_welcome().$PROMPT);
        }
        elsif ($static_words eq 'NULL') {
            return _get_next()._encode64($PROMPT);
        }
        else {
            return _get_next()._encode64(get_word($static_words).$PROMPT);
        }
    }

    sub get_cmd_response {
        my $self = shift;
        my $rqst = shift;

        
    }

    sub get_set_response {
        my $self = shift;
    }

    sub _get_next {
        my $self = shift;
        my $current = @_ ? shift : 'NULL';

        return $MOVEMENT{$current}.':';
    }

    sub _encode64 {
        my $input = shift;

        return encode_base64($input, '');
    }
}

return 1;
