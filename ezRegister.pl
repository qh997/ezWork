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
\t(i prom) Set project module
\t(i list) List all fields
END
chomp $EHELPLIST;

my $main_sock = IO::Socket::INET -> new(
    'Localhost' => 'localhost',
    'LocalPort' => 8321,
    'Proto'     => 'tcp',
    'Listen'    => 5,
    'Reuse'     => 1,
) or die "Could not connet : $!";

my %FIELDSDEF = (
    TASK => 'txtTask',
    PROJ => 'selProject',
    PROT => 'selProTask',
    ACTV => 'selActType1',
    SACT => 'selActType2',
    PROM => 'selModule1',
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

                if ($command =~ /^$/) {
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
                                    "If the list is NULL, you can just press {enter} to set this field empty.\n\n".
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
                                        "If the list is NULL, you can just press {enter} to set this field empty.\n\n".
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
                                if (my $project = get_field_info($account, 'selProject')) {
                                    print $new_sock 'I+ACTV:'.encode_base64(
                                        "!!PAY ATTENTION!!\n".
                                        "You SHOULD ONLY use the following values in the parentheses.\n".
                                        "If the list is NULL, you can just press {enter} to set this field empty.\n\n".
                                        get_field_def("account=$account;selProject=$project;", 'selActType1').
                                        'Type the active number ('.
                                        get_field_info($account, 'selActType1').')> '
                                    , '');
                                }
                                else {
                                    print $new_sock 'HELP:'.encode_base64("You should use 'i proj' to set project frist.\n?> ", '');
                                }
                            }
                            elsif ($set_cmd =~ /^sact$/) {
                                if (my $project = get_field_info($account, 'selProject')) {
                                    if (my $active = get_field_info($account, 'selActType1')) {
                                        print $new_sock 'I+SACT:'.encode_base64(
                                            "!!PAY ATTENTION!!\n".
                                            "You SHOULD ONLY use the following values in the parentheses.\n".
                                        "If the list is NULL, you can just press {enter} to set this field empty.\n\n".
                                            get_field_def("account=$account;selProject=$project;selActType1=$active;", 'selActType2').
                                            'Type the active number ('.
                                            get_field_info($account, 'selActType2').')> '
                                        , '');
                                    }
                                    else {
                                        print $new_sock 'HELP:'.encode_base64("You should use 'i actv' to set active type frist.\n?> ", '');
                                    }
                                }
                                else {
                                    print $new_sock 'HELP:'.encode_base64("You should use 'i proj' to set project frist.\n?> ", '');
                                }
                            }
                            elsif ($set_cmd =~ /^prom$/) {
                                if (my $project = get_field_info($account, 'selProject')) {
                                    print $new_sock 'I+PROM:'.encode_base64(
                                        "!!PAY ATTENTION!!\n".
                                        "You SHOULD ONLY use the following values in the parentheses.\n".
                                        "If the list is NULL, you can just press {enter} to set this field empty.\n\n".
                                        get_field_def("account=$account;selProject=$project;", 'selModule1').
                                        'Type the active number ('.
                                        get_field_info($account, 'selModule1').')> '
                                    , '');
                                }
                                else {
                                    print $new_sock 'HELP:'.encode_base64("You should use 'i proj' to set project frist.\n?> ", '');
                                }
                            }
                            elsif ($set_cmd =~ /^list$/) {
                                print $new_sock 'HELP:'.encode_base64(get_field_info($account)."\n?> ", '');
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
                            my $prt_str = change_password($account, $message);
                            print $new_sock 'PWOK:'.encode_base64("$prt_str\n?> ", '');
                        }
                        elsif ($chk eq 'ILLE') {
                            print $new_sock 'HELP:'.encode_base64("Invalid password!\n?> ", '');
                        }
                    }
                }
                elsif ($command =~ /^(?:I\+)(.*)$/) {
                    my $e_cmd = $1;
                    if ($e_cmd eq 'TASK') {
                        if ($message =~ /^\s*$/) {
                            print $new_sock 'HELP:'.encode_base64("Nothing to change!\n?> ", '');
                        }
                        else {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Task has been set.\n?> ", '');
                        }
                    }
                    elsif ($e_cmd eq 'PROJ') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def("account=$account;", 'selProject');
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Project has been set.\n?> ", '');
                        }
                        elsif ($message =~ /^\s*$/) {
                            if (!$check) {
                                set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                                print $new_sock 'HELP:'.encode_base64("Project has been set to empty.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Nothing has been changed.\n?> ", '');
                            }
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64("!!WARNING!!\nDO NOT input ILLEGAL values\n?> ", '');
                        }
                    }
                    elsif ($e_cmd eq 'PROT') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def("account=$account;selProject=".get_field_info($account, $FIELDSDEF{'PROJ'}).';', $FIELDSDEF{$e_cmd});
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Project task has been set.\n?> ", '');
                        }
                        elsif ($message =~ /^\s*$/) {
                            if (!$check) {
                                set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                                print $new_sock 'HELP:'.encode_base64("Project task has been set to empty.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Nothing has been changed.\n?> ", '');
                            }
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64("!!WARNING!!\nDO NOT input ILLEGAL values\n?> ", '');
                        }
                    }
                    elsif ($e_cmd eq 'ACTV') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def("account=$account;selProject=".get_field_info($account, $FIELDSDEF{'PROJ'}).';', $FIELDSDEF{$e_cmd});
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Active has been set.\n?> ", '');
                        }
                        elsif ($message =~ /^\s*$/) {
                            if (!$check) {
                                set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                                print $new_sock 'HELP:'.encode_base64("Active has been set to empty.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Nothing has been changed.\n?> ", '');
                            }
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64("!!WARNING!!\nDO NOT input ILLEGAL values\n?> ", '');
                        }
                    }
                    elsif ($e_cmd eq 'SACT') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def(
                            "account=$account;selProject=".get_field_info($account, $FIELDSDEF{'PROJ'}).
                            ";selActType1=".get_field_info($account, $FIELDSDEF{'ACTV'}).
                            ';', $FIELDSDEF{$e_cmd}
                        );
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Project sub active type has been set.\n?> ", '');
                        }
                        elsif ($message =~ /^\s*$/) {
                            if (!$check) {
                                set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                                print $new_sock 'HELP:'.encode_base64("Project sub active has been set to empty.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Nothing has been changed.\n?> ", '');
                            }
                        }
                        else {
                            print $new_sock 'HELP:'.encode_base64("!!WARNING!!\nDO NOT input ILLEGAL values\n?> ", '');
                        }
                    }
                    elsif ($e_cmd eq 'PROM') {
                        my $dcmsg = decode_base64($message);
                        my $check = get_field_def("account=$account;selProject=".get_field_info($account, $FIELDSDEF{'PROJ'}).';', $FIELDSDEF{$e_cmd});
                        if ($check =~ /\($dcmsg\)/) {
                            set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                            print $new_sock 'HELP:'.encode_base64("Project module has been set.\n?> ", '');
                        }
                        elsif ($message =~ /^\s*$/) {
                            if (!$check) {
                                set_info_field($account, $FIELDSDEF{$e_cmd}, $message);
                                print $new_sock 'HELP:'.encode_base64("Project module has been set to empty.\n?> ", '');
                            }
                            else {
                                print $new_sock 'HELP:'.encode_base64("Nothing has been changed.\n?> ", '');
                            }
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

    my $dcpasswd = decode_base64($password);
    my $chk_pass_ol = `perl getuseroptions.pl "$account" "$dcpasswd"`;

    if ($chk_pass_ol =~ /!ERROR! Invalid username or password!!/) {
        return "!!WARNING!! Your new password can not be verified.\n"
              ."            And the password will not change any more!";
    }
    else{
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
        return "Password has successfully changed";
    }
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

    my $uservalue = get_field_info($account, $field);
    if ($uservalue) {
        $retval =~ s/^(\s+)(?=\($uservalue\))/  * /sm;
    }

    return $retval;
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
    if ($field && $line =~ m/[:;]$field<(.*?)(?:;|$)/) {
        $retstr .= decode_base64($1);
    }
    elsif ($field) {
        $retstr .= '';
    }
    else {
        foreach my $key (keys %FIELDSDEF) {
            $retstr .= $FIELDSDEF{$key}.' = '.get_field_info($account, $FIELDSDEF{$key})."\n";
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
            if ($value) {
                if ($line =~ /[:;]?$field</) {
                    $line =~ s/(?<=(;|:)$field<).*?(?=;|$)/$value/;
                }
                else {
                    $line =~ s/(?<!:|;)(?=\n)$/;/;
                    $line =~ s/(?<=:|;)(?=\n)$/$field<$value/;
                }
            }
            else {
                $line =~ s/(?<=;|:)$field<[^;]*//;
            }
        }
    }

    open my $OH, '> '.$USERFILE;
    print $OH join '', @user_list;
    close $OH;
}
