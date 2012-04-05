#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use IO::Select;

my $SERVER = '192.168.0.108';
my $PORT   = '1200';

my $socket = IO::Socket::INET->new(
    PeerAddr => $SERVER,
    PeerPort => $PORT,
    Type => SOCK_STREAM,
    Proto => "tcp",
) or die "Can not create socket connect.$@";

my $input;
until (defined $input && $input =~ m{^q$}i) {
    my $str = talk($input);
    
    print $str." > ";
    $input = <STDIN>;
    chomp $input;
}

$socket -> close() or die "Close Socket failed.$@";

sub talk {
    my $words = defined $input ? shift : 'HELLO';
    chomp $words;

    print "Sending...[$words]\n";
    $socket -> send("$words\n", 0);
    $socket -> autoflush(1);

    my $sel = IO::Select -> new($socket);
    while (my @ready = $sel -> can_read) {
        foreach my $fh (@ready) {
            my $str;
            if ($fh == $socket) {
                while (<$fh>) {
                    $str = $_;
                    chomp $str;
                    print "\$str=$str\n";
                    return $str;
                }
                $sel -> remove($fh);
                close $fh;
            }
        }
    }    
}