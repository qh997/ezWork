#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use MIME::Base64;

my $USERFILE = 'accounts';
my $USERSELS = 'useroptions';

my $WELCOME = <<END;

*************************
*                       *
*        WELCOME        *
*                       *
*************************

Use 'h' for help list.
END
chomp $WELCOME;

my $HELPLIST = <<END;
\t(a) Login creat or change account
\t(s) Input or change password
\t(i) Information edition command
\t(p) Print your informations
\t(h) Show this help list
\t(q) Quit
END
chomp $HELPLIST;

my $EHELPLIST = <<END;
\t(i task) Set task
\t(i proj) Set project
\t(i prot) Set project task
\t(i actv) Set activity type
\t(i sact) Set sub activity type
\t(i prom) Set project mode
\t(i list) List all fields
END
chomp $EHELPLIST;

my $main_sock = IO::Socket::INET -> new(
    'Localhost' => 'localhost',
    'LocalPort' => 1200,
    'Proto'     => 'tcp',
    'Listen'    => 5,
    'Reuse'     => 1,
) or die "Could not connet : $!";

my %FIELDSDEF = (
    TASK => 'txtTask',
    PROJ => 'selProject',
);

while (my $new_sock = $main_sock -> accept()) {
    if (my $pid = fork) {
        while (defined (my $buf = <$new_sock>)) {
            chomp $buf;
            print "From client => $buf\n";

            if ($buf =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
                my $account = $1;
                my $passwrd = $2;
                my $command = $3;
                my $message = $4;

                if ($command =~ /^(?:HELO)$/) {
                    print $new_sock 'HELP:'.encode_base64($WELCOME."\n?> ", '');
                }
                elsif ($command =~ /^(?:HELP)$/) {
                    $message = decode_base64($message);
                    if ($message =~ /^h$/) {
                        print $new_sock 'HELP:'.encode_base64($HELPLIST."\n?> ", '');
                    }
                    elsif ($message =~ /^\s*$/) {
                        print $new_sock 'HELP:'.encode_base64('?> ', '');
                    }
                    elsif ($message =~ /^a$/) {
                        print $new_sock 'ACNT:'.encode_base64('Input your email account > ', '');
                    }
                    elsif ($message =~ /^s$/) {
                        if (!$account) {
                            print $new_sock 'HELP:'.encode_base64("Use 'a' to login frist.\n?> ", '');
                        }
                        else {
                            print $new_sock 'PSWD:'.encode_base64('Input your email password > ', '');
                        }
                    }
                    elsif ($message =~ /^p$/) {
                        if (!$account) {
                            print $new_sock 'HELP:'.encode_base64("Use 'a' to login frist.\n?> ", '');
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64(get_informations($account, $passwrd)."?> ", '');
                        }
                    }
                    elsif ($message =~ /^i(?:\s+(.*?)\s*)?$/) {
                        if (!$account) {
                            print $new_sock 'HELP:'.encode_base64("Use 'a' to login frist.\n?> ", '');
                        }
                        elsif (check_password($account, $passwrd) ne 'LGIN') {
                            print $new_sock 'HELP:'.encode_base64("Invalid password!\n?> ", '');
                        }
                        else {
                            my $set_cmd = $1;
                            if (!$set_cmd) {
                                print $new_sock 'HELP:'.encode_base64($EHELPLIST."\n?> ", '');
                            }
                            elsif ($set_cmd =~ /^task$/) {
                                print $new_sock 'I+TASK:'.encode_base64('Type the task text ('.get_field_info($account, 'txtTask').')> ', '');
                            }
                            elsif ($set_cmd =~ /^proj$/) {
                                print $new_sock 'I+PROJ:'.encode_base64(
                                    "!!PAY ATTENTION!!\n".
                                    "You SHOULD ONLY use the following values in the parentheses.\n".
                                    get_field_def("account=$account;", 'selProject').
                                    'Type the project number ('.
                                    get_field_info($account, 'selProject').')> '
                                , '');
                            }
                            elsif ($set_cmd =~ /^prot$/) {
                                if (my $project = get_field_info($account, 'selProject')) {
                                    print $new_sock 'I+PROT:'.encode_base64(
                                        "!!PAY ATTENTION!!\n".
                                        "You SHOULD ONLY use the following values in the parentheses.\n".
                                        get_field_def("account=$account;selProject=$project;", 'selProTask').
                                        'Type the project number ('.
                                        get_field_info($account, 'selProTask').')> '
                                    , '');
                                }
                                else {
                                    print $new_sock 'HELP:'.encode_base64("You should use 'i proj' to set project frist.\n?> ", '');
                                }
                            }
                            elsif ($set_cmd =~ /^actv$/) {
                            }
                            elsif ($set_cmd =~ /^sact$/) {
                            }
                            elsif ($set_cmd =~ /^prom$/) {
                            }
                            elsif ($set_cmd =~ /^list$/) {
                                print $new_sock 'HELP:'.encode_base64(get_info_field($account)."\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Invalid command, use 'i' for help.\n?> ", '');
                            }
                        }
                    }
                    else {
                        print $new_sock 'HELP:'.encode_base64("Invalid command, use 'h' for help.\n?> ", '');
                    }
                }
                elsif ($command =~ /^(?:ACNT)$/) {
                    $message = decode_base64($message);
                    if ($message =~ /:/) {
                        print $new_sock 'HELP:'.encode_base64("Not allow [:] in account name!\n?> ", '');
                    }
                    else {
                        my $acnt_flag = get_account($message);
                        if ($acnt_flag eq 'NEW') {
                            print $new_sock 'ACOK:'.encode_base64("Creat account $message, password [neusoft]\n?> ", '');
                        }
                        elsif ($acnt_flag eq 'ILE') {
                            print $new_sock 'HELP:'.encode_base64("Not allow empty username!\n?> ", '');
                        }
                        else {
                            print $new_sock 'ACOK:'.encode_base64("Login as $message\n?> ", '');
                        }
                    }
                }
                elsif ($command =~ /^(?:PSWD)$/) {
                    if ($message =~ /^\s*$/) {
                        print $new_sock 'HELP:'.encode_base64("Not allow empty password!\n?> ", '');
                    }
                    else {
                        my $chk = check_password($account, $passwrd);
                        if ($passwrd =~ /^\s*$/) {
                            if (check_password($account, $message) eq 'LGIN') {
                                print $new_sock 'PWOK:'.encode_base64("Password OK.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Invalid password!\n?> ", '');
                            }
                        }
                        elsif ($chk eq 'LGIN') {
                            change_password($account, $message);
                            print $new_sock 'PWOK:'.encode_base64("Password changed.\n?> ", '');
                        }
                        elsif ($chk eq 'ILLE') {
                            print $new_sock 'HELP:'.encode_base64("Invalid password!\n?> ", '');
                        }
                    }
                }
                elsif ($command =~ /^(?:I\+)(.*)$/) {
                    my $e_cmd = $1;
                    if ($message =~ /^\s*$/) {
                        print $new_sock 'HELP:'.encode_base64("Nothing to change!\n?> ", '');
                    }
                    elsif ($e_cmd eq 'TASK') {
                        set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                        print $new_sock 'HELP:'.encode_base64("Project task has been set.\n?> ", '');
                    }
                    elsif ($e_cmd eq 'PROJ') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def("account=$account;", 'selProject');
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Project has been set.\n?> ", '');
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64("!!WARNING!!\nDO NOT input ILLEGAL values\n?> ", '');
                        }
                    }
                }
            }
        }

    exit 0;
    }
}

close $main_sock;

sub get_account {
    my $account = shift;
    chomp $account;

    return 'ILE' if $account =~ /^\s*$/;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    unless (grep(/^$account/, @user_list)) {
        my $save_str = $account;
        `echo "$save_str:bmV1c29mdA==:" >> $USERFILE`;
        return 'NEW';
    }

    return '';
}

sub check_password {
    my $account = shift;
    chomp $account;
    my $password = shift;
    chomp $password;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    if (grep(/^$account:$password:/, @user_list)) {
        return 'LGIN';
    }
    else {
        return 'ILLE';
    }
}

sub change_password {
    my $account = shift;
    chomp $account;
    my $password = shift;
    chomp $password;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    foreach my $line (@user_list) {
        if ($line =~ /^$account:/) {
            $line =~ s/^($account:)[^:]*/$1$password/;
        }
    }

    open my $OH, '> '.$USERFILE;
    print $OH join '', @user_list;
    close $OH;
}

sub get_informations {
    my $account = shift;
    chomp $account;
    my $password = shift;
    chomp $password;

    if (check_password($account, $password) eq 'LGIN') {
        open my $UF, '< '.$USERFILE;
        my @user_list = <$UF>;
        close $UF;

        my @line = grep(/^$account:/, @user_list);
        my $ifm = shift @line;
        return $ifm;
    }
    else {
        return "Invalid password!\n";
    }
}

sub get_field_def {
    my $search = shift;
    my $field = shift;

    open my $SF, "< $USERSELS";
    my @sf_arry = <$SF>;
    close $SF;

    my $account = $search;
    $account =~ s/account=(.*?);.*/$1/;
    $search =~ s/.*?=.*?;//;

    my $sels = join '', @sf_arry;
    unless ($sels =~ s/.*###$account###(.*?)###$account###.*/$1/s) {
        print "Cannot found $account in $USERSELS";
    }

    my $level = 0;
    while ($search =~ /(.*?)=(.*?);/g) {
        my $sfield = $1;
        my $svalue = $2;
        $sels =~ s/.*^\*{$level}$svalue.*?\n(.*?)^\*{$level}[^*]+.*/$1/gsm;
        $level++;
    }

    $sels =~ s/.*\*{$level}$field\n*(.*?)\*{$level}$field.*/$1/s;
    my $retval = '';
    while ($sels =~ /^\*{$level}([^*]+)$/gm) {
        my $str = $1;

        $str =~ /(.*?)=(.*)/;
        $retval .= "    ($1)  $2\n";
    }

    return $retval;
}

sub check_field_value {
    my $account = shift;
    my $field = shift;
    my $value = shift;

    my $chkval = get_field_def($account);
}

sub get_field_info {
    my $account = shift;
    chomp $account;
    my $field = @_ ? shift : '';
    chomp $field;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    my @lines = grep(/^$account:/, @user_list);
    return "Account [$account] cannot found!" unless @lines;
    my $line = shift @lines;

    chomp $line;

    my $retstr = '';
    if ($field && $line =~ m/[:;]$field<(.*?);?$/) {
        $retstr .= decode_base64($1);
    }
    elsif ($field) {
        $retstr .= '';
    }
    else {
        foreach my $key (keys %FIELDSDEF) {
            $retstr .= $FIELDSDEF{$key}.' = '.get_info_field($account, $FIELDSDEF{$key})."\n";
        }
    }

    return $retstr;
}

sub set_info_field {
    my $account = shift;
    chomp $account;
    my $field = shift;
    chomp $field;
    my $value = shift;
    chomp $value;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    foreach my $line (@user_list) {
        if ($line =~ /^$account:/) {
            if ($line =~ /[:;]?$field</) {
                $line =~ s/(?<=(;|:)$field<).*?(?=;|$)/$value/;
            }
            else {
                $line =~ s/(?<!:|;)(?=\n)$/;/;
                $line =~ s/(?<=:|;)(?=\n)$/$field<$value/;
            }
        }
    }

    open my $OH, '> '.$USERFILE;
    print $OH join '', @user_list;
    close $OH;
}
