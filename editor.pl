#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;
use IO::Select;

my %ser_info = (
    "ser_ip" => "gengs-host",
    "ser_port" => "1200",
);

&main();

sub main {
    my $ser_addr = $ser_info{"ser_ip"};
    my $ser_port = $ser_info{"ser_port"};

    my $socket = IO::Socket::INET->new(
        PeerAddr => $ser_addr,
        PeerPort => $ser_port,
        Type => SOCK_STREAM,
        Proto => "tcp",
    ) or die "Can not create socket connect.$@";

    my $read = <STDIN>;
    chomp $read;

    $socket->send($read."\n",0);
    $socket->autoflush(1);  
    my $sel = IO::Select->new($socket);
    while (my @ready = $sel->can_read) {
        foreach my $fh (@ready) {
            if ($fh == $socket) {
                while (<$fh>) {
                    print $_;
                }
                $sel->remove($fh);  
                close $fh;
            }
        }
    }
    $socket->close() or die "Close Socket failed.$@";
}
