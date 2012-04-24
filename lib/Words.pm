package Words;

use warnings;
use strict;
require Exporter;
use version;

our $VERSION = qv('0.0.1');

our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_welcome
    get_word
    get_word_nowarp
);

my $WELCOME = <<END;
\t***************************
\t*                         *
\t*         WELCOME         *
\t*                         *
\thostname
\t***************************

Use 'h' for help list.
END

our $HELPLIST = <<END;
    (a) Login or creat or change account
    (s) Input or change password
    (i) Information edition command
    (p) Print your informations
    (h) Show this help list
    (q) Quit
END

our $IHELPLIST = <<END;
    (i task) Set task
    (i proj) Set project
    (i prot) Set project task
    (i actv) Set activity type
    (i sact) Set sub activity type
    (i prom) Set project module
    (i list) List all fields
END

our $INV_CMD = <<END;
Invalid command, use 'h' for help.
END

our $ACNT = <<END;
Input your email account
END

our $NEED_ACCOUNT = <<END;
Use 'a' to login frist.
END

our $NEED_PASSWORD = <<END;
Use 's' to register your account.
END

sub get_welcome {
    my $hostname = `hostname`;
    chomp $hostname;

    $WELCOME =~ /^\t(.*)$/m;
    my $ori_len = length $1;
    my $space = int(($ori_len - 2 - length $hostname) / 2);
    $hostname = "*".' ' x $space.$hostname.' ' x $space;
    $hostname .= ' ' if (length($hostname) % 2);
    $hostname .= '*';

    my $ret_str = $WELCOME;
    $ret_str =~ s/hostname/$hostname/;
    return $ret_str;
}

no strict 'refs';
sub get_word {
    return ${shift;};
}

sub get_word_nowarp {
    my $str = ${shift;};
    chomp $str;
    
    return $str;
}

return 1;
