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
my $paspt = '';
my $commd = 'HELP';
my $input = '';
until ($input =~ m{^q$}i) {
    my $serstr = talk();
    print "RECIVED ==> $serstr\n";

    if ($serstr =~ /^(.*?):(.*)$/) {
        my $s_cmd = $1;
	my $msg = decode_base64($2);

        if ($s_cmd ne 'EROR') {
            $commd = $s_cmd;

            if ($s_cmd eq 'PWOK') {
                $commd = 'HELP';
                print "$paswd <=> $paspt\n";
                $paswd = $paspt;
            }
            $paspt = '';
        }
        else {
            $commd = 'HELP';
        }

        print $msg;
        print "[$acunt] " if $acunt ne '';
        $input = <STDIN>;
        chomp $input;

	$acunt = $input if $commd eq 'ACNT';
        if ($commd eq 'PSWD') {
	    $paspt = encode_base64($input);
            chomp $paspt;
        }
    }
}

$socket -> close() or die "Close Socket failed.$@";

sub talk {
    print "SENDING ==> [$acunt:".$paswd.":$commd:".encode_base64($input)."]\n";
    $socket -> send("$acunt:".$paswd.":$commd:".encode_base64($input)."\n", 0);
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
