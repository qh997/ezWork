#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use IO::Select;
use MIME::Base64;

my $SERVER = 'backup1';
my $PORT   = '8321';

my $socket = IO::Socket::INET -> new(
    PeerAddr => $SERVER,
    PeerPort => $PORT,
    Type => SOCK_STREAM,
    Proto => "tcp",
) or die "Can not create socket connection to server : <$SERVER>.\n$@";

my $acunt = '';
my $acupt = '';
my $paswd = '';
my $paspt = '';
my $commd = '';
my $input = '';
until ($commd eq 'HELP' && $input eq 'q') {
    my $serstr = talk();

    if ($serstr =~ /^(.*?):(.*)$/) {
        my $s_cmd = $1;
        my $msg = decode_base64($2);

        $commd = $s_cmd;
        if ($s_cmd eq 'PWOK') {
            $commd = 'HELP';
            $paswd = $paspt;
        }
        elsif ($s_cmd eq 'ACOK') {
            $commd = 'HELP';
            $acunt = $acupt;
            $paswd = '';
        }
        $paspt = '';
        $acupt = '';

        print $msg;
        if ($acunt ne '') {
            print "[$acunt";
            print "*" if $paswd eq '';
            print "] ";
        }
        $input = <STDIN>;
        chomp $input;

        $acupt = $input if $commd eq 'ACNT';
        if ($commd eq 'PSWD') {
            $paspt = encode_base64($input);
            chomp $paspt;
        }
    }
}

$socket -> close() or die "Close Socket failed.$@";

sub talk {
    $socket -> send("$acunt:$paswd:$commd:".encode_base64($input, '')."\n", 0);
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
