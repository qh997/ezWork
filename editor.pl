#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use IO::Select;
use MIME::Base64;

my $SERVER = 'gengs-host';
my $PORT   = '1200';

my $socket = IO::Socket::INET->new(
    PeerAddr => $SERVER,
    PeerPort => $PORT,
    Type => SOCK_STREAM,
    Proto => "tcp",
) or die "Can not create socket connection to server : <$SERVER>.\n$@";

my $email = '';
my $paswd = '';
my $commd = '';
my $input = '';
until ($input =~ m{^q$}i) {
    my $serstr = talk();
    
    if ($serstr =~ /^(.*?):(.*)$/) {
        $commd = $1;
	my $prt_str = $2;
        print $prt_str;

        $input = <STDIN>;
        chomp $input;

	if ($commd eq '') {
	    $email = $input;
	}
    }
}

$socket -> close() or die "Close Socket failed.$@";

sub talk {
    $socket -> send("$email:$commd:$input\n", 0);
    $socket -> autoflush(1);

    my $sel = IO::Select -> new($socket);
    while (my @ready = $sel -> can_read) {
        foreach my $fh (@ready) {
            if ($fh == $socket) {
                while (<$fh>) {
                    my $str = $_;
                    chomp $str;
                    return $str;
                }
                $sel -> remove($fh);
                close $fh;
            }
        }
    }    
}
