#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use IO::Select;
use MIME::Base64;

chomp(my $SERVER = @ARGV ? shift : 'backup1');
my $PORT   = '8321';

my $socket = IO::Socket::INET -> new(
    PeerAddr => $SERVER,
    PeerPort => $PORT,
    Type => SOCK_STREAM,
    Proto => "tcp",
) or die "Can not create socket connection to server : <$SERVER>.\n$@";

my $acunt = '';
my $paswd = '';
my $commd = '';
my $input = '';
until ($commd eq 'HELP' && $input =~ /^\s*q(uit)?\s*$/i) {
    my $ser_cmd = decode_base64(talk());

    eval $ser_cmd;
    die $@ if $@;
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
