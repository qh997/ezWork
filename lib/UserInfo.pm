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
            if (!$depval && !$self -> field_value($DEPEND{$field})) {
                $depval = 'NEED_'.$DEPEND{$field};
            }
        }

        return $depval;
    }

    sub field_value {
        my $self = shift;
        my $field = shift;
        my $value = @_ ? shift : undef;

        if (defined $value) {
        }

        return $info{ident $self}{$field};
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
}

return 1;
