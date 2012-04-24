package Response;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use Words;

my $PROMPT = '?> ';

use Class::Std::Utils; {
    my %user;
    my %command;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $user{ident $self} = {
            account => '',
            password => '',
        };
        $command{ident $self} = {
            type => '',
            content => '',
        };
        
        return $self;
    }

    sub set_user {
        my $self = shift;
        my %args = @_;

        $user{ident $self} -> {account} = $args{account};
        $user{ident $self} -> {password} = $args{password};
    }

    sub set_command {
        my $self = shift;
        my %args = @_;

        $command{ident $self} -> {type} = $args{type};
        $command{ident $self} -> {content} = $args{content};
    }

    sub get_static_response {
        my $self = shift;
        my $static_words = shift;

        if ($static_words eq 'WELCOME') {
            return _encode64(get_welcome().$PROMPT);
        }
        elsif ($static_words eq 'NULL') {
            return _encode64($PROMPT);
        }
        else {
            return _encode64(get_word($static_words).$PROMPT);
        }
    }

    sub get_response {
        my $self = shift;
    }

    sub _encode64 {
        my $input = shift;

        return encode_base64($input, '');
    }
}

return 1;
