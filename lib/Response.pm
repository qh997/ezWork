package Response;

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.2');

use General;
use User;
use FieldControl;
use Words;

my %MOVEMENT = (
    'NULL' => 'HELP',
    'A'    => 'ACNT',
    'S'    => 'PSWD',
    'P'    => 'HELP',
    'ACNT' => 'ACOK',
    'PSWD' => 'PWOK',
    'TASK' => 'HELP',
    'PROJ' => 'HELP',
    'PROT' => 'HELP',
    'ACTV' => 'HELP',
    'SACT' => 'HELP',
    'MODE' => 'HELP',
);

use Class::Std::Utils; {
    my %user;
    my %command;
    my %result;

    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $user{ident $self} = undef;
        $command{ident $self} = {
            type => '',
            content => '',
        };
        $result{ident $self} = {
            command => _get_next(),
            content => '',
        };
        
        return $self;
    }

    sub user {
        my $self = shift;
        my %args = @_ ? @_ : ();

        $user{ident $self} = User -> new();
        $user{ident $self} -> account($args{account});
        $user{ident $self} -> password($args{password});
    }

    sub command {
        my $self = shift;
        my %args = @_;

        if (keys %args) {
            $command{ident $self}{type} = $args{type} if $args{type};
            $command{ident $self}{content} = $args{content} if $args{content};
            $command{ident $self}{content} =~ s/^\s+//;
            $command{ident $self}{content} =~ s/\s+$//;
            debug('Message = ['.$command{ident $self}{content}.']');
        }
    }

    sub analyze {
        my $self = shift;

        if ($command{ident $self}{type} eq '') {
            $result{ident $self}{content} = get_welcome();
        }
        elsif ($command{ident $self}{type} eq 'HELP') {
            if (!$command{ident $self}{content}) {
                $result{ident $self}{content} = '';
            }
            elsif ($command{ident $self}{content} =~ /^h$/i) {
                $result{ident $self}{content} = get_word('HELPLIST');
            }
            elsif ($command{ident $self}{content} =~ /^i$/i) {
                $result{ident $self}{content} = get_word('IHELPLIST');
            }
            else {
                $self -> get_cmd_response();
            }
        }
        else {
            $self -> get_set_response();
        }
    }
    
    sub get_cmd_response {
        my $self = shift;

        my $ucmd = $command{ident $self}{content};
        if ($ucmd =~ /^i\s+(.*)$/i) {
            my $next = uc $1;
            if (FieldControl::SettingExists($next)) {
                if (my $need = $user{ident $self} -> need_for($next)) {
                    $result{ident $self}{content} = get_word($need);
                }
                else {
                    my $evalue = $user{ident $self} -> field_value($next);
                    my $ftype = FieldControl::FieldType($next);

                    $result{ident $self}{command} = 'I+'.$next;
                    if ($ftype eq 'TXT') {
                        #So far, for doing nothing.
                    }
                    elsif ($ftype eq 'SEL') {
                        $result{ident $self}{content} = get_word('SEL_ATON');
                        my ($empty, $list) = $user{ident $self} -> field_option_print($next);
                        $result{ident $self}{content} .= $empty ? get_word($list) : $list."\n";
                        if ($empty == 2) {
                            $result{ident $self}{command} = _get_next();
                            return;
                        }
                    }

                    $result{ident $self}{content} .= get_word_replace_nowarp($next, 'EXISTS' => $evalue);
                }
            }
            else {
                $result{ident $self}{content} = get_word('INV_CMD');
            }
        }
        else {
            if (my $next = _get_next(uc $ucmd)) {
                if (my $need = $user{ident $self} -> need_for($next)) {
                    $result{ident $self}{content} = get_word($need);
                }
                else {
                    $result{ident $self}{command} = $next;

                    if ('P' eq uc $ucmd ) {
                        my %user_infos = $user{ident $self} -> get_user_infos();
                        $result{ident $self}{content} = get_word_replace('USER_INFOS', %user_infos);
                    }
                    else {
                        $result{ident $self}{content} = get_word_nowarp($next);
                    }
                }
            }
            else {
                $result{ident $self}{content} = get_word('INV_CMD');
            }
        }
    }

    sub get_set_response {
        my $self = shift;

        my $scmd = $command{ident $self}{type};
        my $mesg = $command{ident $self}{content};
        if (my $next = _get_next($scmd)) {
            if ($scmd eq 'ACNT') {
                my ($login, $word) = User::Login($mesg);
                if ($login) {
                    $result{ident $self}{command} = $next;
                    $result{ident $self}{content} = get_word_replace($word, 'ACCOUNT' => $mesg);
                }
                else {
                    $result{ident $self}{content} = get_word($word);
                }
            }
            elsif ($scmd eq 'PSWD') {
                my ($login, $word) = $user{ident $self} -> register($mesg);
                if ($login) {
                    $result{ident $self}{command} = $next;
                    $result{ident $self}{content} = get_word_replace($word, 'ACCOUNT' => $user{ident $self} -> account);
                }
                else {
                    $result{ident $self}{content} = get_word($word);
                }
            }
            elsif (my ($field) = $scmd =~ /^I\+(.*)$/) {
                my $word = $user{ident $self} -> field_value($field, $mesg);
                
                $result{ident $self}{command} = _get_next();
                $result{ident $self}{content} = get_word($word);
            }
            else {
                $result{ident $self}{command} = _get_next();
                $result{ident $self}{content} = get_word('INCOMPLETE');
            }
        }
        else {
            $result{ident $self}{content} = get_word('UKN_CMD');
        }
    }

    sub set_warning {
        my $self = shift;

        $result{ident $self}{command} = _get_next();
        $result{ident $self}{content} = $_[0];
    }

    sub get_result {
        my $self = shift;

        return ($result{ident $self}{command}, $result{ident $self}{content});
    }

    sub _get_next {
        my $current = @_ ? shift : 'NULL';
        $current = uc $current;

        if ($current =~ /^I\+(.*)$/) {
            $current = $1;
            return _get_next() if defined $MOVEMENT{$current};
        }

        return $MOVEMENT{$current} if defined $MOVEMENT{$current};
        return 0;
    }
}

return 1;
