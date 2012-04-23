#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use MIME::Base64;

BEGIN {push @INC, q[./lib]};
use General;
use UserCommand;

my %CFGS = get_configs();

my $main_socket = IO::Socket::INET -> new(
    'Localhost' => 'localhost',
    'LocalPort' => $CFGS{PORT},
    'Proto'     => 'tcp',
    'Listen'    => '5',
    'Reuse'     => '1',
) or die "Could not connet : $!";

while (my $new_socket = $main_socket -> accept()) {
    my $pid = fork();
    if (defined $pid && $pid == 0) {
    }
}
