#!/usr/bin/perl

use warnings;
use strict;
use LWP;

my $NOW_DATE = now_date();

my %USER = (
    NAME => 'gengs',
    PSWD => 'gengs@NEU3',
    TASK => 'SCM working',
    PROJ => '1014680',
    PROT => '442537',
    ACT1 => '30523',
    ACT2 => '32892',
    MOD1 => '81884',
);

my %URLS = (
    MAIN => 'http://processbase.neusoft.com',
    LOGN => 'http://processbase.neusoft.com/UserLogin.do',
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

my $browser = LWP::UserAgent -> new();
my $response = $browser -> get($URLS{MAIN});
my $cookie = ${$response -> headers}{'set-cookie'};
$cookie =~ s/(.*?);.*/$1/;
push @HEAD, (Cookie => $cookie);

my $logn_para = 'state=login';
$logn_para .= '&username='.$USER{NAME};
$logn_para .= '&password='.$USER{PSWD};
$logn_para .= '&selLanguage=en_US&lawEmp=on';

$response = $browser -> post($URLS{LOGN}.'?'.$logn_para, @HEAD);

my $rpot_para = 'hidState=saveBack';
$rpot_para .= '&txtDate='.$NOW_DATE;
$rpot_para .= '&txtTask='.$USER{TASK};
$rpot_para .= '&txtTime=8&txtWorkLoad=';
$rpot_para .= '&selProject='.$USER{PROJ};
$rpot_para .= '&attribute1=&selProTask='.$USER{PROT};
$rpot_para .= '&selActType1='.$USER{ACT1};
$rpot_para .= '&selActType2='.$USER{ACT2};
$rpot_para .= '&selModule1='.$USER{MOD1};
$rpot_para .= '&selModule2=&selResult=&txtResValue=&txtRemark=';

$response = $browser -> post($URLS{RPOT}.'?'.$rpot_para, @HEAD);

sub now_date {
    my $NowTime = time();
    my ($year, $month, $day, $hour, $min, $sec);
    $year = (localtime($NowTime))[5] + 1900;
    $month = (localtime($NowTime))[4] + 1;
    $month =~ s/^(\d{1})$/0$1/;
    $day = (localtime($NowTime))[3];
    $day =~ s/^(\d{1})$/0$1/;

    return "$year-$month-$day";
}
