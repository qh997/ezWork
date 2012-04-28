package User;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.1.2');

use General;
use FieldControl;

use Class::Std::Utils; {
    my %account;
    my %password;
    my %info;
    my %lack;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $account{ident $self} = '';
        $password{ident $self} = '';
        $info{ident $self} = FieldControl -> new();
        $lack{ident $self} = 'NEED_ACCOUNT';
        
        return $self;
    }

    sub account {
        my $self = shift;
        my $input = @_ ? shift : '';
        
        if ($input) {
            $account{ident $self} = $input;
            $password{ident $self} = '';
            $info{ident $self} -> user('');
            $lack{ident $self} = 'NEED_PASSWORD';
        }

        return $account{ident $self};
    }

    sub password {
        my $self = shift;
        my $input = @_ ? shift : '';

        if ($input) {
            if ($account{ident $self} && CheckPassword($account{ident $self}, $input)) {
                $password{ident $self} = $input;
                $info{ident $self} -> user($account{ident $self});
                $lack{ident $self} = 0;
            }
            else {
                $password{ident $self} = '';
                $info{ident $self} -> user('');
                $lack{ident $self} = 'NEED_PASSWORD';
            }
        }

        return $password{ident $self};
    }

    sub Login {
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
            if ($lack{ident $self}) {
                if (CheckPassword($account{ident $self}, $password)) {
                    return (1, 'REGISTER');
                }
                else {
                    return (0, 'BAD_REGISTER');
                }
            }
            else {
                if (CheckPassword($account{ident $self}, $password{ident $self})) {
                    if ($self -> _change_password($password)) {
                        return (1, 'PASSWORD_CHANGED');
                    }
                    else {
                        return (0, 'NOT_VER_PASSWORD');
                    }
                }
                else {
                    return (0, 'BAD_REGISTER');
                }
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
        else {
            if (!$lack{ident $self}) {
                return $info{ident $self} -> depend_on($next);
            }
        }

        return $lack{ident $self};
    }
    
    sub field_option_print {
        my $self = shift;
        my $field = shift;

        my $fvalue = $self -> field_value($field);
        $fvalue = defined $fvalue ? $fvalue : '';

        my $empty = 1;
        my $ret_str = '';
        if (my @opt_list = $info{ident $self} -> get_field_option($field)) {
            if (@opt_list ==1 && !defined $opt_list[0]) {
                $empty = 2;
                $ret_str = 'NO_OPTION';
            }
            else {
                $empty = 0;
                foreach my $option (@opt_list) {
                    my ($value, $descr) = @$option;

                    $ret_str .= "      ($value) $descr\n";
                }

                $ret_str =~ s/^(\s+)(?=\($fvalue\))/    * /sm if $fvalue;
            }
        }
        else {
            $empty = 1;
            $ret_str = 'EMPTY_OPTION';
        }

        return ($empty, $ret_str);
    }

    sub infos_print {
        my $self = shift;
        my %infos;

        my $warning = 0;
        $infos{ACNT} = StrPrtFmt($account{ident $self});
        $infos{PSWD} = StrPrtFmt($password{ident $self});
        my %values = $info{ident $self} -> get_fields_value();
        while (my ($field, $value) = each %values) {
            if (defined $value) {
                my ($warn, $str) = $info{ident $self} -> get_value_description($field, $value);
                $str = StrPrtFmt($str);
                $str = $warn ? $str.' <!Something wrong!>' : $str;
                $infos{$field} = $str;
                $warning += $warn;
            }
            else {
                $infos{$field} = StrPrtFmt(undef).' <!Something wrong!>';
                $warning++;
            }
        }

        return ($warning, %infos);
    }
    
    sub field_value {
        my $self = shift;
        my $field = shift;
        my $value = @_ ? shift : undef;

        if (defined $value) {
            my $ftype = FieldControl::FieldType($field);
            if ($ftype eq 'TXT') {
                if ($value) {
                    $info{ident $self} -> set_field_value($field, $value);
                    return 'SET_FIELD';
                }
                else {
                    return 'NOTHING';
                }
            }
            elsif ($ftype eq 'SEL') {
                if (my @opt_list = $info{ident $self} -> get_field_option($field)) {
                    if (@opt_list ==1 && !defined $opt_list[0]) {
                        return 'INV_OPRT';
                    }
                    else {
                        if ($value) {
                            if (grep $value eq $_ -> [0], @opt_list) {
                                $info{ident $self} -> set_field_value($field, $value);
                                return 'SET_FIELD';
                            }
                            else {
                                return 'ILLEGAL_VALUE';
                            }
                        }
                        else {
                            return 'NOTHING';
                        }
                    }
                }
                else {
                    $info{ident $self} -> set_field_value($field, '');
                    return 'SET_EMPTY';
                }
            }
        }
        else {
            my $retvalue = $info{ident $self} -> get_field_value($field);
            return defined $retvalue ? $retvalue : '';
        }
    }

    sub CheckPassword {
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

    sub lack {
        my $self = shift;

        return $lack{ident $self};
    }

    sub _change_password {
        my $self = shift;
        my $pswd = shift;

        my $acnt = $account{ident $self};

        debug("Update user option list START.($acnt)");
        my $chk_pass_ol = `perl getuseroptions.pl '$acnt' '$pswd'`;
        debug("Update user option list STOP.($acnt)");

        if ($chk_pass_ol =~ /!ERROR! Invalid username or password!!/) {
            return 0;
        }
        else {
            my %CFGS = get_configs();

            open my $UF, '< '.$CFGS{USERLIST};
            my @user_list = <$UF>;
            close $UF;

            my $epswd = encode_base64($pswd, '');
            foreach my $line (@user_list) {
                if ($line =~ /^$acnt:/) {
                    $line =~ s/^($acnt:)[^:]*/$1$epswd/;
                }
            }

            open my $OH, '> '.$CFGS{USERLIST};
            print $OH join '', @user_list;
            close $OH;
            return 1;
        }
    }

    sub StrPrtFmt {
        my $string = shift;

        return !defined $string ? '(undefined)' :
               $string          ? $string       : '(--empty--)';
    }
}

return 1;
