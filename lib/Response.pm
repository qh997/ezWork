package Response;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;
use User;
use UserInfo;
use Words;

my $HPROMPT = '?> ';
my $SPROMPT = ' > ';
my %MOVEMENT = (
    'NULL' => 'HELP',
    'A' => 'ACNT',
    'S' => 'PSWD',
    'P' => 'HELP',
    'ACNT' => 'ACOK',
    'PSWD' => 'PWOK',
    'I_TASK' => 'HELP',
    'I_PROJ' => 'HELP',
    'I_PROT' => 'HELP',
    'I_ACTV' => 'HELP',
    'I_SACT' => 'HELP',
    'I_MODE' => 'HELP',
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
            debug("content = ".$command{ident $self}{content});
        }
    }

    sub analyze {
        my $self = shift;

        if ($command{ident $self}{type} eq '') {
            $result{ident $self}{content} = _encode64(get_welcome().$HPROMPT);
        }
        elsif ($command{ident $self}{type} eq 'HELP') {
            if (!$command{ident $self}{content}) {
                $result{ident $self}{content} = _encode64($HPROMPT);
            }
            elsif ($command{ident $self}{content} =~ /^h$/i) {
                $result{ident $self}{content} = _encode64(get_word('HELPLIST').$HPROMPT);
            }
            elsif ($command{ident $self}{content} =~ /^i$/i) {
                $result{ident $self}{content} = _encode64(get_word('IHELPLIST').$HPROMPT);
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
            if (UserInfo::SettingExists($next)) {
                if (my $need = $user{ident $self} -> need_for($next)) {
                    $result{ident $self}{content} = _encode64(get_word($need).$HPROMPT);
                }
                else {
                    $result{ident $self}{command} = 'I+'.$next;
                    $result{ident $self}{content} = _encode64(
                        get_word_replace_nowarp(
                            $next,
                            'EXISTS' => $user{ident $self} -> field($next)
                        ).$SPROMPT
                    );
                }
            }
            else {
                $result{ident $self}{content} = _encode64(get_word('INV_CMD').$HPROMPT);
            }
        }
        else {
            if (my $next = _get_next(uc $ucmd)) {
                if (my $need = $user{ident $self} -> need_for($next)) {
                    $result{ident $self}{content} = _encode64(get_word($need).$HPROMPT);
                }
                else {
                    $result{ident $self}{command} = $next;
                    $result{ident $self}{content} = _encode64(get_word_nowarp($next).$SPROMPT);
                }
            }
            else {
                $result{ident $self}{content} = _encode64(get_word('INV_CMD').$HPROMPT);
            }
        }
    }

    sub get_set_response {
        my $self = shift;

        my $scmd = $command{ident $self}{type};
        my $mesg = $command{ident $self}{content};
        if (my $next = _get_next(uc $scmd)) {
            if ($scmd eq 'ACNT') {
                my ($login, $word) = User::Login($mesg);
                if ($login) {
                    $result{ident $self}{command} = $next;
                    $result{ident $self}{content} = _encode64(
                        get_word_replace($word, 'ACCOUNT' => $mesg).$HPROMPT
                    );
                }
                else {
                    $result{ident $self}{content} = _encode64(get_word($word).$HPROMPT);
                }
            }
            elsif ($scmd eq 'PSWD') {
                my ($login, $word) = $user{ident $self} -> register($mesg);
                if ($login) {
                    $result{ident $self}{command} = $next;
                    $result{ident $self}{content} = _encode64(
                        get_word_replace(
                            $word, 'ACCOUNT' => $user{ident $self} -> account
                        ).$HPROMPT
                    );
                }
                else {
                    $result{ident $self}{content} = _encode64(get_word($word).$HPROMPT);
                }
            }
            else {
                
            }
        }
        else {
            $result{ident $self}{content} = _encode64(get_word('INV_CMD').$HPROMPT);
        }
    }

    sub set_warning {
        my $self = shift;

        $result{ident $self}{command} = _get_next();
        $result{ident $self}{content} = _encode64($_[0].$HPROMPT);
    }

    sub get_result {
        my $self = shift;

        return $result{ident $self}{command}.':'.$result{ident $self}{content};
    }

    sub _get_next {
        my $current = @_ ? shift : 'NULL';

        return $MOVEMENT{$current} if defined $MOVEMENT{$current};
        return 0;
    }
    sub _encode64 {
        my $input = shift;

        return encode_base64($input, '');
    }
}

return 1;
