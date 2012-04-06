#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use IO::Select;
use MIME::Base64;

my $SERVER = 'p-d2-gengs';
my $PORT   = '1200';

my $socket = IO::Socket::INET->new(
    PeerAddr => $SERVER,
    PeerPort => $PORT,
    Type => SOCK_STREAM,
    Proto => "tcp",
) or die "Can not create socket connection to server : <$SERVER>.\n$@";

my $acunt = '';
my $paswd = '';
my $commd = 'HELP';
my $input = '';
until ($input =~ m{^q$}i) {
    my $serstr = talk();

    if ($serstr =~ /^(.*?):(.*)$/) {
        my $s_cmd = $1;
	my $msg = decode_base64($2);

        unless ($s_cmd eq 'EROR') {
            $commd = $s_cmd;
        }
        else {
            $commd = 'HELP';
        }

        print $msg;
        print "[$acunt] " if $acunt ne '';
        $input = <STDIN>;
        chomp $input;

	$acunt = $input if $commd eq 'ACNT';
	$paswd = $input if $commd eq 'PSWD';
    }
}

$socket -> close() or die "Close Socket failed.$@";

sub talk {
    $socket -> send("$acunt:".encode_base64($paswd).":$commd:".encode_base64($input)."\n", 0);
    $socket -> autoflush(1);

    my $sel = IO::Select -> new($socket);

    while (my @ready = $sel -> can_read) {
        foreach my $fh (@ready) {
            if ($fh == $socket) {
                 $fh -> recv(my $line, 81192);
                 $line =~ s/\n//g;
                 return $line;
            }
        }
    }    
}
