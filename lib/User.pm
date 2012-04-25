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

    sub account {
        my $self = shift;

        return $account{ident $self};
    }

    sub login {
        my $account = shift;
        chomp $account;

        if ($account =~ /[@#:!$%^&*();'"`~\/\\ ]/) {
            return (0, 'BAD_ACCOUNT');
        }
        elsif (!$account) {
            return (0, 'NOTHING');
        }
        else {
            my %CFGS = get_configs();

            open my $UF, '< '.$CFGS{USERLIST};
            my @user_list = <$UF>;
            close $UF;

            if (grep(/^$account/, @user_list)) {
                return (1, 'LOGIN_ACCOUNT');
            }
            else {
                `echo "$account:bmV1c29mdA==:" >> $CFGS{USERLIST}`;
                return (1, 'CREAT_ACCOUNT');
            }
        }
    }

    sub register {
        my $self = shift;
        my $password = shift;
        chomp $password;

        if (!$password) {
            return (0, 'NOTHING');
        }
        else {
            if (check_password($account{ident $self}, $password)) {
                return (1, 'REGISTER');
            }
            else {
                return (0, 'BAD_REGISTER');
            }
        }
    }

    sub need_for {
        my $self = shift;
        my $next = shift;
        
        if ($next eq 'ACNT') {
            return 0;
        }
        elsif ($next eq 'PSWD') {
            return 0 if $account{ident $self};
        }
        return $status{ident $self};
    }

    sub check_password {
        my $account = shift;
        my $password = shift;

        $password = encode_base64($password, '');
        my %CFGS = get_configs();

        open my $UF, '< '.$CFGS{USERLIST};
        my @user_list = <$UF>;
        close $UF;

        if (grep(/^$account:$password:/, @user_list)) {
            return 1;
        }
        else {
            return 0;
        }      
    }

    sub status {
        my $self = shift;

        return $status{ident $self};
    }
}

return 1;
