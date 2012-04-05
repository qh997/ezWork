#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;

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
         print "==> $buf\n";
         print $new_sock "You said : $buf\n";
    }
}

close $main_sock;