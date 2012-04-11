#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use MIME::Base64;

my $USERFILE = 'accounts';
my $HELPLIST = <<END;
\t(a) Login creat or change account
\t(s) Set or change password
\t(p) Print your imformation
\t(h) Show this help list
\t(q) Quit
?> 
END
chomp $HELPLIST;

my $main_sock = new IO::Socket::INET(
    Localhost => 'localhost',
    LocalPort => 1200,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1,
) or die "Could not connet : $!";

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

                if ($command =~ /^(?:HELP)$/) {
                    $message = decode_base64($message);
                    if ($message =~ /^h?$/) {
                        print $new_sock 'HELP:'.encode_base64($HELPLIST);
                    }
                    elsif ($message =~ /^a$/) {
                        print $new_sock 'ACNT:'.encode_base64('Input your email account > ');
                    }
                    elsif (!$account) {
                        print $new_sock 'HELP:'.encode_base64("Use 'a' to login frist.\n?> ");
                    }
                    elsif ($message =~ /^s$/) {
                        print $new_sock 'PSWD:'.encode_base64('Input your email password > ');
                    }
                    elsif ($message =~ /^p$/) {
                        print $new_sock 'HELP:'.encode_base64(get_account_information($account, $passwrd)."?> ");
                    }
                    else {
                        print $new_sock 'HELP:'.encode_base64("Invalid command, use 'h' for help.\n?> ");
                    }
                }
                elsif ($command =~ /^(?:ACNT)$/) {
                    $message = decode_base64($message);
                    my $acnt_flag = get_account($message);
                    if ($acnt_flag eq 'NEW') {
                        print $new_sock 'HELP:'.encode_base64("Creat account $message, password [neusoft]\n?> ");
                    }
                    elsif ($acnt_flag eq 'ILE') {
                        print $new_sock 'HELP:'.encode_base64("Not allow empty username!\n?> ");
                    }
                    else {
                        print $new_sock 'HELP:'.encode_base64("Login as $message\n?> ");
                    }
                }
                elsif ($command =~ /^(?:PSWD)$/) {
                    if ($message =~ /^\s*$/) {
                        print $new_sock 'HELP:'.encode_base64("Not allow empty password!\n?> ");
                    }
                    else {
		        my $chk = check_password($account, $passwrd);
                        if ($passwrd =~ /^\s*$/) {print "new pass\n";
                            if (check_password($account, $message) eq 'LGIN') {
                                print $new_sock 'PWOK:'.encode_base64("Password OK.\n?> ");
                            }
                            else {
		                print $new_sock 'HELP:'.encode_base64("Invalid account or password!\n?> ");
                            }
                        }
                        elsif ($chk eq 'LGIN') {
                            change_password($account, $message);
                            print $new_sock 'PWOK:'.encode_base64("Password changed.\n?> ");
                        }
		        elsif ($chk eq 'ILLE') {
		            print $new_sock 'HELP:'.encode_base64("Invalid account or password!\n?> ");
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

    return;
}

sub check_password {
    my $account = shift;
    chomp $account;
    my $password = shift;
    chomp $password;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    if (my @ttt = grep(/^$account:$password:/, @user_list)) {
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

sub get_account_information {
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
        return "Invalid account or password!\n";
    }
}
