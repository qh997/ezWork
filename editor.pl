#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;

my $sock = new IO::Socket::INET (
    PeerAddr => 'gengs-host',
    PeerPort => 1200,
    Proto    => 'tcp',
) or die $!;

foreach (1..10) {
    print $sock "Msg $_: How are you ?\n";
    $sock -> flush();
}

close $sock;
