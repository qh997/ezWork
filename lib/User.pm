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
    }
    
    sub account {
        my $self = shift;
        return $account{ident $self};
    }
    
    sub password {
        my $self = shift;
        return $password{ident $self};
    }
    
    sub need_for {
        my $self = shift;
        my $next = shift;
        
        if ($next eq 'ACNT') {
            return 0;
        }
        elsif ($next eq 'PSWD') {
            return 'NEED_ACCOUNT' unless $account{ident $self};
            return 0;
        }
        elsif ($next eq 'INFO') {
            return 'NEED_ACCOUNT' unless $account{ident $self};
            return 'NEED_PASSWORD' unless $password{ident $self};
            return 0;
        }
    }
}

return 1;
