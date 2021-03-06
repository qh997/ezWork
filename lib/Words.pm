package Words;

use warnings;
use strict;
require Exporter;
use version;

our $VERSION = qv('0.1.6');

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

# Use 'h' for help list.
END

our $HELPLIST = <<END;
    (a) Change account
    (s) Register or change password
    (g) Use guide to set information (Recommend)
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
END

our $INV_CMD = <<END;
# Invalid command, use 'h' for help.
END

our $INV_OPRT = <<END;
# FATAL ERROR : Illegal operation.
END

our $UKN_CMD = <<END;
# Unkonw system status.
END

our $ACNT = <<END;
Input your email account
END

our $PSWD = <<END;
Input your email password
END

our $NEED_ACCOUNT = <<END;
# Use 'a' to login frist.
END

our $NEED_PASSWORD = <<END;
# Use 's' to register your account.
END

our $LOGIN_ACCOUNT = <<END;
# Login as *ACCOUNT*.
END

our $CREAT_ACCOUNT = <<END;
# Creat account *ACCOUNT*.
END

our $BAD_ACCOUNT = <<END;
# Bad of user name.
# Your name can not be found in LDAP.
# The user name can not contain special characters.
# Please check your input.
END

our $REGISTER = <<END;
# Register as *ACCOUNT*.
END

our $BAD_REGISTER = <<END;
# Invalid password.
END

our $PASSWORD_CHANGED = <<END;
# Your password has been successfully set.
# Your option list has been successfully update.
END

our $NOT_VER_PASSWORD = <<END;
# Sorry your password CANNOT be verified.
# Your password should be the same as your email password.
# Please confirm your input or try it later.
# And there is nothing to change.
END

our $NOTHING = <<END;
# Nothing to change.
END

our $TASK = <<END;
Type the task text. (*EXISTS*)
END

our $PROJ = <<END;
Type the project number. (*EXISTS*)
END

our $NEED_PROJ = <<END;
# You should use 'i proj' to set project frist.
END

our $PROT = <<END;
Type the project task type number. (*EXISTS*)
END

our $ACTV = <<END;
Type the active type number. (*EXISTS*)
END

our $NEED_ACTV = <<END;
# You should use 'i actv' to set active type frist.
END

our $SACT = <<END;
Type the sub active type number. (*EXISTS*)
END

our $MODE = <<END;
Type the project module number. (*EXISTS*)
END

our $SEL_ATON = <<END;
  ********************************************
  *            !!PAY ATTENTION!!             *
  * You SHOULD ONLY use the following values *
  * which is in the parentheses.             *
  ********************************************

END

our $EMPTY_OPTION = <<END;
    ***** The list of option is empty *****
    ****** press <ENTER> to continue ******

END

our $NO_OPTION = <<END;
# You don't have an option list.
# use <s> to update the list.
END

our $SET_EMPTY = <<END;
# This field will set to empty.
END

our $INCOMPLETE = <<END;
# Incomplete function.
END

our $SET_FIELD = <<END;
# OK! Your Information has been update.
END

our $ILLEGAL_VALUE = <<END;
# Wrong! DO NOT input ILLEGAL values.
END

our $USER_INFOS = <<END;
   *********************
   * Basic information *
   *********************
   Account  : *ACNT*
   Password : *PSWD*

  ***********************
  * Project information *
  ***********************
  Task      : *TASK*
  Project   : *PROJ*
   Task     : *PROT*
   Active   : *ACTV*
    Active2 : *SACT*
   Module   : *MODE*

END

our $USER_INFOS_WARN = <<END;
# !!WARNING!! You have *COUNT* problems, please fix them ASAP.
END

our $GUIDE_FINISH = <<END;

# You have completed the settings.
# Use the 'p' to view it.

END

our $GUIDE_TITLE = <<END;

====================== *TITLE* ======================

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
