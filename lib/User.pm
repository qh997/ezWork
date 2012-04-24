package User;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;

use Class::Std::Utils; {
    my %account;
    my %password;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $account{ident $self} = '';
        $password{ident $self} = '';
        
        return $self;
    }

    sub settings {
        my $self = shift;
        my %args = @_ ? @_ : ();

        if (keys %args) {
            $account{ident $self} = $args{account} if $args{account};
            $password{ident $self} = $args{password} if $args{password};
        }

        return {
            account => $account{ident $self},
            password => $password{ident $self},
        };
    }
}

return 1;
