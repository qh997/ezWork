#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;

BEGIN {push @INC, q[./lib]};
use General;
use UserCommand;

my %CFGS = get_configs();
debug('Starting at localhost:'.$CFGS{PORT});

my $main_socket = IO::Socket::INET -> new(
    'Localhost' => 'localhost',
    'LocalPort' => $CFGS{PORT},
    'Proto'     => 'tcp',
    'Listen'    => '5',
    'Reuse'     => '1',
) or die "Could not start : $!";

while (my $new_socket = $main_socket -> accept()) {
    my $pid = fork;
    if (defined $pid && $pid == 0) {
        start($new_socket);

        exit 0;
    }
}

sub start {
    my $socket = shift;

    debug($socket);
    while (defined (my $buf = <$socket>)) {
        chomp $buf;
        debug($socket -> peerhost().' => '.$buf);
        
        my $user_cmd = UserCommand -> new(command => $buf);

        print $socket $user_cmd -> response();
    }
}
