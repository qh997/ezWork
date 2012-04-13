#!/usr/bin/perl

use warnings;
use strict;
use LWP;

my %USER = (
    NAME => @ARGV ? shift @ARGV : 'gengs',
    PSWD => @ARGV ? shift @ARGV : 'gengs@NEU3',
);

my %URLS = (
    MAIN => 'http://processbase.neusoft.com',
    LOGN => 'http://processbase.neusoft.com/UserLogin.do',
    DLAD => 'http://processbase.neusoft.com/daily/dailyAdd.jsp',
    DRDN => 'http://processbase.neusoft.com/daily/dailyDropDown.jsp',
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
$response = $browser -> post($URLS{DLAD}, @HEAD);
my $project = $response -> content;

unless ($project) {
    print "!ERROR! Invalid username or password!!\n";

    exit 1;
}
$project =~ s{.*name="selProject" id="selProject".*?</OPTION>(.*?)</select>.*}{$1}s;

my $user_str = "###$USER{NAME}###\n";
$user_str .= "selProject\n";
while ($project =~ m{<option value="(.*?)">(.*?)</option>}g) {
    my $proidx = $1;
    my $pronam = $2;
    $user_str .= "$proidx=$pronam\n";
    $response = $browser -> post($URLS{DRDN}."?state=1&procode=$proidx", @HEAD);
    my $sels = $response -> content;
    while ($sels =~ m{parent.setDropOptions\(new Array\((.*?)\),\s*"(.*?)"\);}g) {
        my $sel_name = $2;
        my $sel_str = $1;
        next if $sel_name =~ /selActType2/;
        $user_str .= "*$sel_name\n";

        $sel_str =~ s/'//g;
        my @sel = split ',', $sel_str;
        foreach my $num (1..@sel/2) {
            my $index = $num * 2 -2;

            my $opidx = $sel[$index++];
            next unless $opidx;
            my $opnam = $sel[$index];

            $user_str .= "*$opidx=$opnam\n";
            if ($sel_name =~ /selActType1/) {
                $response = $browser -> post($URLS{DRDN}."?state=2&procode=$proidx&type1=$opidx", @HEAD);
                my $act2_str = $response -> content;
                if ($act2_str =~ m{parent.setDropOptions\(new Array\((.*?)\),\s*"selActType2"\);}) {
                    $user_str .= "**selActType2\n";
                    $act2_str = $1;
                    $act2_str =~ s/'//g;
                    my @act2 = split ',', $act2_str;
                    foreach my $act2num (1..@act2/2) {
                        my $act2index = $act2num * 2 -2;

                        my $act2opidx = $act2[$act2index++];
                        next unless $act2opidx;
                        my $act2opnam = $act2[$act2index];
                        $user_str .= "**$act2opidx=$act2opnam\n";
                    }
                    $user_str .= "**selActType2\n";
                }
            }
        }
        $user_str .= "*$sel_name\n";
    }
}
$user_str .= "selProject\n";
$user_str .= "###$USER{NAME}###\n\n";
print $user_str;

open my $RH, '< useroptions';
my @usfile = <$RH>;
close $RH;

my $filestr = join '', @usfile;
unless ($filestr =~ s/###$USER{NAME}###.*###$USER{NAME}###\n+/$user_str/s) {
    $filestr .= $user_str;
}

open my $WH, '> useroptions';
print $WH $filestr;
close $WH;

sub get_options {
    my $opt_str = shift;

    $opt_str =~ s/'//g;
    my @opt_str_l = split ',', $opt_str;

    my $retval = {};
    foreach my $gp_num (1..@opt_str_l/2) {
        my $index = $gp_num * 2 -2;

        my $option_index = $opt_str_l[$index++];
        next unless $option_index;

        ${$retval}{$option_index} = $opt_str_l[$index];
    }
    return $retval;
}
