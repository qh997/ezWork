#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use MIME::Base64;

my $HELPLIST <<EOF;
(c) Creat account
(m) Modify an exists account
(q) Quit
EOF

my $main_sock = new IO::Socket::INET(
    Localhost => 'gengs-host',
    LocalPort => 1200,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1,
) or die "Could not connet : $!";

while (my $new_sock = $main_sock -> accept()) {
    while (defined (my $buf = <$new_sock>)) {
        chomp $buf;
        print "===> $buf\n";

        if ($buf =~ /^.*?:[A-Z]*:.*$/) {
	    if ($buf =~ /^.*?::$/) {
                print $new_sock $HELPLIST;
	        #print $new_sock "SETEMAIL:Please input your email account > \n";
   	    }
	    else {
	        print $new_sock "ERROR:Unknow COMMAND : [$buf]. \n";
	    }
	}
	else {
	    print $new_sock "ERROR:Unknow COMMAND : [$buf]. \n";
	}
    }
}

close $main_sock;
