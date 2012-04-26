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
    get_word_replace
    get_word_replace_nowarp
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
    (i mode) Set project module
    (i list) List all fields
END

our $INV_CMD = <<END;
Invalid command, use 'h' for help.
END

our $UKN_CMD = <<END;
Unkonw system status.
END

our $ACNT = <<END;
Input your email account
END

our $PSWD = <<END;
Input your email password
END

our $NEED_ACCOUNT = <<END;
Use 'a' to login frist.
END

our $NEED_PASSWORD = <<END;
Use 's' to register your account.
END

our $LOGIN_ACCOUNT = <<END;
Login as *ACCOUNT*.
END

our $CREAT_ACCOUNT = <<END;
Creat account *ACCOUNT*, password [neusoft].
END

our $BAD_ACCOUNT = <<END;
* Bad of user name.
* User name CANNOT contain special characters or space.
END

our $REGISTER = <<END;
Register as *ACCOUNT*.
END

our $BAD_REGISTER = <<END;
Invalid password.
END

our $NOTHING = <<END;
Nothing to change.
END

our $TASK = <<END;
Type the task text. (*EXISTS*)
END

our $PROJ = <<END;
Type the project number. (*EXISTS*)
END

our $SEL_ATON = <<END;
****************************************************************************
*                            !!PAY ATTENTION!!                             *
* You SHOULD ONLY use the following values in the parentheses.             *
* If the list is NULL, you can just press {enter} to set this field empty. *
****************************************************************************

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
    my $str = get_word(@_);
    chomp $str;

    return $str;
}

sub get_word_replace {
    my $str = ${shift;};
    my %replace = @_;

    while (my ($ori, $tar) = each %replace) {
        $str =~ s/\*$ori\*/$tar/g;
    }

    return $str;
}

sub get_word_replace_nowarp {
    my $str = get_word_replace(@_);
    chomp $str;

    return $str;
}

return 1;
