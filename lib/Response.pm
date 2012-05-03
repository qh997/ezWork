package Response;

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.4');

use General;
use User;
use FieldControl;
use Words;

my %MOVEMENT = (
    'NULL' => 'HELP',
    'A'    => 'ACNT',
    'S'    => 'PSWD',
    'G'    => 'G+TASK',
    'I'    => 'HELP',
    'P'    => 'HELP',
    'H'    => 'HELP',

    'ACNT' => 'ACOK',
    'PSWD' => 'PWOK',

    'I+TASK' => 'HELP',
    'I+PROJ' => 'HELP',
    'I+PROT' => 'HELP',
    'I+ACTV' => 'HELP',
    'I+SACT' => 'HELP',
    'I+MODE' => 'HELP',

    'G+TASK' => 'G+PROJ',
    'G+PROJ' => 'G+PROT',
    'G+PROT' => 'G+ACTV',
    'G+ACTV' => 'G+SACT',
    'G+SACT' => 'G+MODE',
    'G+MODE' => 'HELP',
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
            command => GetNext(),
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
            my $next = uc 'I+'.$1;
            if (GetNext(uc $next)) {
                $result{ident $self}{command} = $next;
                $result{ident $self}{content} = $self -> _reponse_info($next);
            }
            else {
                $result{ident $self}{content} = get_word('INV_CMD');
            }
        }
        else {
            if (my $next = GetNext(uc $ucmd)) {
                if (my $need = $user{ident $self} -> need_for($next)) {
                    $result{ident $self}{content} = get_word($need);
                }
                else {
                    $result{ident $self}{command} = $next;

                    if ('P' eq uc $ucmd) {
                        my ($warning, %user_infos) = $user{ident $self} -> infos_print();
                        $result{ident $self}{content} = get_word_replace('USER_INFOS', %user_infos);
                        $result{ident $self}{content} .= get_word_replace('USER_INFOS_WARN', COUNT => $warning) if $warning;
                    }
                    elsif ('G' eq uc $ucmd) {
                        $result{ident $self}{command} = $next;
                        my $next_field = $result{ident $self}{command};
                        $next_field =~ s/^G\+//;
                        $result{ident $self}{content} .= get_word_replace('GUIDE_TITLE', 'TITLE' => $next_field);
                        $result{ident $self}{content} .= $self -> _reponse_info($next);
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
        if (my $next = GetNext($scmd)) {
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
                
                $result{ident $self}{command} = GetNext();
                $result{ident $self}{content} = get_word($word);
            }
            elsif (($field) = $scmd =~ /^G\+(.*)$/) {
                my $word = $user{ident $self} -> field_value($field, $mesg);

                $result{ident $self}{command} = $next;
                if ($word eq 'ILLEGAL_VALUE') {
                    $result{ident $self}{command} = $scmd;
                }

                $result{ident $self}{content} = get_word($word);
                if (GetNext($result{ident $self}{command})) {
                    my $next_field = $result{ident $self}{command};
                    $next_field =~ s/^G\+//;
                    $result{ident $self}{content} .= get_word_replace('GUIDE_TITLE', 'TITLE' => $next_field);
                    $result{ident $self}{content} .= $self -> _reponse_info($result{ident $self}{command})
                }
                else {
                    $result{ident $self}{content} .= get_word('GUIDE_FINISH');
                }
            }
            else {
                $result{ident $self}{command} = GetNext();
                $result{ident $self}{content} = get_word('INCOMPLETE');
            }
        }
        else {
            $result{ident $self}{content} = get_word('UKN_CMD');
        }
    }

    sub set_warning {
        my $self = shift;

        $result{ident $self}{command} = GetNext();
        $result{ident $self}{content} = $_[0];
    }

    sub get_result {
        my $self = shift;

        return ($result{ident $self}{command}, $result{ident $self}{content});
    }

    sub GetNext {
        my $current = @_ ? shift : 'NULL';
        $current = uc $current;

        return $MOVEMENT{$current} if defined $MOVEMENT{$current};
        return 0;
    }

    sub _reponse_info {
        my $self = shift;
        my $next = uc shift;

        my $retstr;
        if (GetNext($next)) {
            my ($field) = $next =~ /^(?:I|G)\+(.*)$/;

            if (my $need = $user{ident $self} -> need_for($field)) {
                $retstr = get_word($need);
            }
            else {
                my $evalue = $user{ident $self} -> field_value($field);
                my $ftype = FieldControl::FieldType($field);

                if ($ftype eq 'TXT') {
                    #So far, for doing nothing.
                }
                elsif ($ftype eq 'SEL') {
                    $retstr = get_word('SEL_ATON');
                    my ($empty, $list) = $user{ident $self} -> field_option_print($field);
                    $retstr .= $empty ? get_word($list) : $list."\n";
                    if ($empty == 2) {
                        $retstr = GetNext();
                        return;
                    }
                }

                $retstr .= get_word_replace_nowarp($field, 'EXISTS' => $evalue);
            }
        }
        else {
            $retstr = get_word('INV_CMD');
        }

        return $retstr;
    }
}

return 1;
