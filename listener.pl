#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;

my $sock = new IO::Socket::INET(
    Localhost => 'gengs-host',
    LocalPort => 1200,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1,
);

die "Could not connet : $!" unless $sock;

while (my $new_sock = $sock -> accept()) {
    while (defined (my $buf = <$new_sock>)) {
        print $buf;
    }
}

close $sock;
