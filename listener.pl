#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use MIME::Base64;

my $USERFILE = 'account.txt';
my $HELPLIST = <<END;
\t(a) Creat or modify account
\t(s) Creat or modify password
\t(h) Show this help list
\t(q) Quit
?> 
END
chomp $HELPLIST;

my $main_sock = new IO::Socket::INET(
    Localhost => 'p-d2-gengs',
    LocalPort => 1200,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1,
) or die "Could not connet : $!";

while (my $new_sock = $main_sock -> accept()) {
    while (defined (my $buf = <$new_sock>)) {
        chomp $buf;
        print "From client => $buf\n";

        if ($buf =~ /^(.*?):(.*?):(.*?):(.*?)$/) {
            my $account = $1;
            my $passwrd = $2;
            my $command = $3;
            my $message = decode_base64($4);

            if ($command =~ /^(?:HELP)$/) {
                print $new_sock 'HELP:'.encode_base64($HELPLIST) if $message =~ /^h?$/;
                print $new_sock 'ACNT:'.encode_base64('Input your email account > ') if $message =~ /^a$/;
            }
            elsif ($command =~ /^(?:ACNT)$/) {
                if (get_account($message) eq 'NEW') {
                    print $new_sock 'HELP:'.encode_base64("Creat account $message\n?> ");
                }
                else {
                    print $new_sock 'PSWD:'.encode_base64("Enter password for $message\n?> ");
                }
            }
            elsif ($command =~ /^(?:PSWD)$/) {
                if (check_password($account, $passwrd) eq 'NEW') {
                    print $new_sock 'HELP:'.encode_base64("Creat account $message\n?> ");
                }
            }
        }
    }
}

close $main_sock;

sub get_account {
    my $account = shift;
    chomp $account;

    open my $UF, '< '.$USERFILE;
    my @user_list = <$UF>;
    close $UF;

    unless (grep(/^$account/, @user_list)) {
        my $save_str = $account;
        `echo $save_str >> $USERFILE`;
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

    unless (grep(/^$account:$password/, @user_list)) {
        foreach my $line (@user_list) {
        }
    }
}
