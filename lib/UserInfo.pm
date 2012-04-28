package UserInfo;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;

my %FIELDS = (
    'TASK' => ['TXT' => 'txtTask'],
    'PROJ' => ['SEL' => 'selProject'],
    'PROT' => ['SEL' => 'selProTask'],
    'ACTV' => ['SEL' => 'selActType1'],
    'SACT' => ['SEL' => 'selActType2'],
    'MODE' => ['SEL' => 'selModule1'],
);

my %DEPEND = (
    'PROT' => 'PROJ',
    'ACTV' => 'PROJ',
    'SACT' => 'ACTV',
    'MODE' => 'PROJ',
);

use Class::Std::Utils; {
    my %user;
    my %info;
    
    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;

        $user{ident $self} = '';
        $info{ident $self} = {};
        
        return $self;
    }
    
    sub user {
        my $self = shift;
        my $input = @_ ? shift : undef;

        if (defined $input) {
            $user{ident $self} = $input;
            if (!$self -> _read_infos()) {
                $user{ident $self} = '';
                $info{ident $self} = {};
            }
        }

        return $user{ident $self};
    }

    sub depend_on {
        my $self = shift;
        my $field = shift;

        my $depval = 0;
        if (exists $DEPEND{$field}) {
            $depval = $self -> depend_on($DEPEND{$field});
            if (!$depval && !defined $self -> get_field_value($DEPEND{$field})) {
                $depval = 'NEED_'.$DEPEND{$field};
            }
        }

        return $depval;
    }

    sub get_field_value {
        my $self = shift;
        my $field = shift;

        return $info{ident $self}{$field};
    }

    sub set_field_value {
        my $self = shift;
        my $field = shift;
        my $value = shift;

        my %CFGS = get_configs();

        open my $UF, '< '.$CFGS{USERLIST};
        my @user_list = <$UF>;
        close $UF;

        my $account = $user{ident $self};
        my $fname = $FIELDS{$field} -> [1];
        my $evalue = encode64($value);

        foreach my $line (@user_list) {
            if ($line =~ /^$account:/) {
                if ($line =~ /[:;]?$fname</) {
                    $line =~ s/(?<=(;|:)$fname<).*?(?=;|$)/$evalue/;
                }
                else {
                    $line =~ s/(?<!:|;)(?=\n)$/;/;
                    $line =~ s/(?<=:|;)(?=\n)$/$fname<$evalue/;
                }
            }
        }

        open my $OH, '> '.$CFGS{USERLIST};
        print $OH join '', @user_list;
        close $OH;
    }

    sub get_field_option {
        my $self = shift;
        my $field = shift;

        if ($self -> depend_on($field)) {
            return undef;
        }
        else {
            my $fname = $FIELDS{$field} -> [1];
            my $search = $self -> _depend_value($field);
            my $account = $user{ident $self};

            my %CFGS = get_configs();

            open my $UF, '< '.$CFGS{USEROPTS};
            my @user_opts = <$UF>;
            close $UF;
            my $opts = join '', @user_opts;
     
            if ($opts =~ s/.*###$account###(.*?)###$account###.*/$1/s) {
                my $level = 0;
                while ($search =~ /(.*?)=(.*?);/g) {
                    my $sfield = $1;
                    my $svalue = $2;
                    $opts =~ s/.*^\*{$level}$svalue.*?\n(.*?)^\*{$level}[^*]+.*/$1/gsm;
                    $level++;
                }

                $opts =~ s/.*\*{$level}$fname\n*(.*?)\*{$level}$fname.*/$1/s;
                my @retval;
                while ($opts =~ /^\*{$level}([^*].*)$/gm) {
                    my $str = $1;

                    $str =~ /(.*?)=(.*)/;
                    push @retval, [$1 => $2];
                }

                return @retval;
            }
            else {
                return undef;
            }
        }
    }
    
    sub SettingExists {
        my $field = shift;
        
        return exists $FIELDS{$field} ? 1 : 0;
    }
    
    sub FieldType {
        my $field = shift;

        if (SettingExists($field)) {
            return $FIELDS{$field} -> [0];
        }

        return 0;
    }

    sub _read_infos {
        my $self = shift;

        my %CFGS = get_configs();

        open my $UF, '< '.$CFGS{USERLIST};
        my @user_list = <$UF>;
        close $UF;

        my $account = $self -> user();
        my @lines = grep(/^$account:/, @user_list);
        return 0 unless @lines;

        my $line = shift @lines;
        chomp $line;

        while (my ($fdef, $fdetail) = each %FIELDS) {
            my $fname = $fdetail -> [1];
            if ($line =~ m/[:;]$fname<(.*?)(?:;|$)/) {
                $info{ident $self}{$fdef} = decode_base64($1);
            }
            else {
                $info{ident $self}{$fdef} = undef;
            }
        }

        return 1;
    }

    sub _depend_value {
        my $self = shift;
        my $field = shift;

        my $depval = '';
        if (exists $DEPEND{$field}) {
            $depval .= $self -> _depend_value($DEPEND{$field});
            $depval .= $FIELDS{$DEPEND{$field}} -> [1].'='.$self -> get_field_value($DEPEND{$field}).';';
        }

        return $depval;
    }
}

return 1;
