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
    my %status;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $account{ident $self} = '';
        $password{ident $self} = '';
        $status{ident $self} = 'NEED_ACCOUNT';
        
        return $self;
    }

    sub settings {
        my $self = shift;
        my %args = @_ ? @_ : ();

        if (keys %args) {
            if ($args{account}) {
                $account{ident $self} = $args{account};
                $status{ident $self} = 'NEED_PASSWORD';
            }

            if ($args{password}) {
                $password{ident $self} = $args{password};
                $status{ident $self} = 0;
            }
        }
    }

    sub login {
        my $self = shift;
        my $account = shift;
        chomp $account;

        if ($account =~ /[@#:!$%^&*();'"`~\/\\]/) {
            return 'BAD_ACCOUNT';
        }
        else {
            return '';
        }
    }

    sub password {
        my $self = shift;
    }

    sub need_for {
        my $self = shift;
        my $next = shift;
        
        if ($next eq 'ACNT') {
            return 0;
        }
        else {
            return $status{ident $self};
        }
    }
}

return 1;
