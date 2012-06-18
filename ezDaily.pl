#!/usr/bin/perl

use warnings;
use strict;
use LWP;
use Time::Format;
use URL::Encode qw(url_encode);
use version;
our $VERSION = qv('0.1.2');

if (@ARGV < 8) {
    print "Insufficient parameters.\n";
    exit 1;
}

my %USER = (
    NAME => shift,
    PSWD => shift,
    TASK => shift,
    PROJ => shift,
    PROT => shift,
    ACT1 => shift,
    ACT2 => shift,
    MOD1 => shift,
);

my $NOW_DATE = @ARGV ? shift : $time{'yyyy-mm-dd'};
$NOW_DATE = $time{'yyyy-mm-dd'} unless $NOW_DATE =~ /^\d{4}-\d{2}-\d{2}$/;
print "Date : $NOW_DATE\n";

my %URLS = (
    MAIN => 'http://processbase.neusoft.com',
    LOGN => 'http://processbase.neusoft.com/UserLogin.do',
    DLAD => 'http://processbase.neusoft.com/daily/dailyAdd.jsp',
    RPOT => 'http://processbase.neusoft.com/SaveDaily.do',
);

my @HEAD = (
    'Host' => 'processbase.neusoft.com',
    'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:10.0.1) Gecko/20100101 Firefox/10.0.1',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'en-us,en;q=0.5',
    'Accept-Encoding' => 'gzip, deflate',
    'Connection' => 'keep-alive',
);

my $browser = LWP::UserAgent->new();
my $response = $browser->get($URLS{MAIN});
my $cookie = ${$response->headers}{'set-cookie'};
$cookie =~ s/(.*?);.*/$1/;
push @HEAD, (Cookie => $cookie);

my $logn_para = 'state=login';
$logn_para .= '&username='.$USER{NAME};
$logn_para .= '&password='.url_encode($USER{PSWD});
$logn_para .= '&selLanguage=en_US&lawEmp=on';

$response = $browser->post($URLS{LOGN}.'?'.$logn_para, @HEAD);
$response = $browser->post($URLS{DLAD}, @HEAD);

my $project = $response->content;
unless ($project) {
    print "Cannot login as <$USER{NAME}> use password [$USER{PSWD}].\n";
    exit 1;
}

my $rpot_para = '';
$rpot_para .= 'hidState=saveBack';
$rpot_para .= '&txtDate='.$NOW_DATE;
$rpot_para .= '&txtTask='.url_encode($USER{TASK});
$rpot_para .= '&txtTime=8&txtWorkLoad=';
$rpot_para .= '&selProject='.$USER{PROJ};
$rpot_para .= '&attribute1=&selProTask='.$USER{PROT};
$rpot_para .= '&selActType1='.$USER{ACT1};
$rpot_para .= '&selActType2='.$USER{ACT2};
$rpot_para .= '&selModule1='.$USER{MOD1};
$rpot_para .= '&selModule2=&selResult=&txtResValue=&txtRemark=';

$response = $browser->post($URLS{RPOT}.'?'.$rpot_para, @HEAD);
