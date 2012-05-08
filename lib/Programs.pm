package Programs;

use warnings;
use strict;
require Exporter;
use version;

our $VERSION = qv('0.1.1');

our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_program
    get_program_replace
);

our $CHANGE_CMD = <<'END';
$commd = '*CMD*';
END

our $MSG_PRINT = <<'END';
print '*MSG*';
END

our $USER_INPUT = <<'END';
if ($acunt ne '') {
    print "[$acunt";
    print "*" if $paswd eq '';
    print "] ";
}
chomp($input = <>);
END

our $USER_INPUT_AGENT = <<'END';
$input = '*INPUT*';
END

our $LOGIN = <<'END';
$acunt = '*ACNT*';
$paswd = '';
END

our $REGISTER = <<'END';
$paswd = encode_base64('*PSWD*', '');
END

no strict 'refs';
sub get_program {
    return ${shift;};
}

sub get_program_replace {
    my $str = ${shift;};
    my %replace = @_;

    while (my ($ori, $tar) = each %replace) {
        $tar =~ s/'/\\'/g;
        $str =~ s/\*$ori\*/$tar/g;
    }

    return $str;
}