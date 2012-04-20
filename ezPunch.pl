#!/usr/bin/env perl
use warnings;
use strict;
use LWP;

my %USER = (
    NAME => @ARGV ? shift : 'gengs',
    PASS => @ARGV ? shift : '',
);

my %URLS = (
    INDX => 'http://kq.neusoft.com/index.jsp',
    LOGN => 'http://kq.neusoft.com/login_wkq1103_3023.jsp',
    MAIN => 'http://kq.neusoft.com/attendance.jsp',
    RCOD => 'http://kq.neusoft.com/record.jsp',
);

my @HEAD = (
    'Host' => 'kq.neusoft.com',
    'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:10.0.1) Gecko/20100101 Firefox/10.0.1',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'en-us,en;q=0.5',
    'Accept-Encoding' => 'gzip, deflate',
    'Connection' => 'keep-alive',
);

my $browser = LWP::UserAgent -> new();
my $response = $browser -> get($URLS{INDX}, @HEAD);
$response -> is_success or die "Cannot get $URLS{INDX} -- ", $response -> status_line;
my $cookie = ${$response -> headers}{'set-cookie'};
$cookie =~ s/(.*?);.*/$1/;
push @HEAD, ('Cookie' => $cookie);

my $neusoft_key = $response -> content;
$neusoft_key =~ s/.*name="neusoft_key".*?value="ID(.*?)PWD\1".*/$1/s;

my $name_id = $response -> content;
$name_id =~ s/.*name="(ID.*?)".*/$1/s;

my $pass_id = $response -> content;
$pass_id =~ s/.*name="(KEY.*?)".*/$1/s;

my $logn_para = 'login=true';
$logn_para .= '&neusoft_attendance_online=';
$logn_para .= '&KEY'.$neusoft_key.'=';
$logn_para .= '&neusoft_key=ID'.$neusoft_key.'PWD'.$neusoft_key;
$logn_para .= '&'.$name_id.'='.$USER{NAME};
$logn_para .= '&'.$pass_id.'='.$USER{PASS};

$response = $browser -> post("$URLS{LOGN}?$logn_para", @HEAD);
if ($response -> content =~ /href=".*?\?(error=.*?)"/) {
    print $USER{NAME}.":Receive error code when login : $1\n";
    exit 1;
}

$response = $browser -> get($URLS{MAIN}, @HEAD);

my $tempoid = $response -> content;
$tempoid =~ s/.*name="currentempoid"\s+value="(.*?)".*/$1/s;
my $rcod_para = 'currentempoid='.$tempoid;

$response = $browser -> post("$URLS{RCOD}?$rcod_para", @HEAD);

exit 0;
