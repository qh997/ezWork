#!/usr/bin/perl

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.1.1');

BEGIN {push @INC, q[./lib]};
use General;

my $SPECUSER = @ARGV ? shift : '';

my %CFGS = get_configs();
my $USERFILE = $CFGS{USERLIST};
my $USERSELS = $CFGS{USEROPTS};

my %FIELDSDEF = (
    TASK => 'txtTask',
    PROJ => 'selProject',
    PROT => 'selProTask',
    ACTV => 'selActType1',
    SACT => 'selActType2',
    PROM => 'selModule1',
);

open my $UF, "< $USERFILE";
my @userlist = <$UF>;
close $UF;

open my $SF, "< $USERSELS";
my @usersels = <$SF>;
close $SF;

foreach my $l (@userlist) {
    my $line = $l;
    chomp $line;
    if ($line =~ /^(.*?):(.*?):(.*)$/) {
        my $user_name = $1;
        if (!$SPECUSER || ($SPECUSER eq $user_name)) {
            my $user_pass = decode_base64($2);
            my $user_info = decode_base64($3);

            print "Reporting for $user_name\n";

            my $chk_pass_ol = `perl UpdateDailyOptions.pl '$user_name' '$user_pass'`;

            if ($chk_pass_ol =~ /Invalid username or password/) {
                print "!!WARNING!! Account [$user_name] can not be verified.\n";
            }
            else {
                if (my $err = check_user_settings($user_name)) {
                    print "!!WARNING!! Account [$user_name] has wrong setting in field [$err].\n";
                }
                else {
                    my $reportstr = "perl ezDaily.pl '$user_name' '$user_pass' ";
                    foreach my $key ('TASK','PROJ','PROT','ACTV','SACT','PROM') {
                        $reportstr .= "'".get_field_info($user_name, $FIELDSDEF{$key})."' ";
                    }
                    print $reportstr."\n";
                    `$reportstr`;
                }
            }
        }
    }
}

sub check_user_settings {
    my $account = shift;

    foreach my $key (keys %FIELDSDEF) {
        if ($key eq 'TASK') {
            return $FIELDSDEF{$key} unless get_field_info($account, $FIELDSDEF{$key});
        }
        else {
            return $FIELDSDEF{$key} if check_field_set($account, $FIELDSDEF{$key});
        }
    }

    return 0;
}

sub check_field_set {
    my $account = shift;
    my $field = shift;

    my $value = get_field_info($account, $field);
    my $searchstr = "account=$account;";
    if ($field eq 'selProject') {
    }
    elsif ($field eq 'selActType2') {
        $searchstr .= "selProject=".get_field_info($account, 'selProject').";".
                      "selActType1=".get_field_info($account, 'selActType1').";";
    }
    else {
        $searchstr .= "selProject=".get_field_info($account, 'selProject').";";
    }

    my $check = get_field_def($searchstr, $field);

    return 0 if $check =~ /\($value\)/;
    return 0 if !$check && !$value;

    return 1;
}

sub get_field_def {
    my $search = shift;
    my $field = shift;

    my $account = $search;
    $account =~ s/account=(.*?);.*/$1/;
    $search =~ s/.*?=.*?;//;

    my $sels = join '', @usersels;
    unless ($sels =~ s/.*###$account###(.*?)###$account###.*/$1/s) {
        print "Cannot found $account in $USERSELS\n";
    }

    my $level = 0;
    while ($search =~ /(.*?)=(.*?);/g) {
        my $sfield = $1;
        my $svalue = $2;
        $sels =~ s/.*^\*{$level}$svalue.*?\n(.*?)^\*{$level}[^*]+.*/$1/gsm;
        $level++;
    }

    $sels =~ s/.*\*{$level}$field\n*(.*?)\*{$level}$field.*/$1/s;
    my $retval = '';
    while ($sels =~ /^\*{$level}([^*]+)$/gm) {
        my $str = $1;

        $str =~ /(.*?)=(.*)/;
        $retval .= "    ($1)  $2\n";
    }

    my $uservalue = get_field_info($account, $field);
    if ($uservalue) {
        $retval =~ s/^(\s+)(?=\($uservalue\))/  * /sm;
    }

    return $retval;
}

sub get_field_info {
    my $account = shift;
    my $field = @_ ? shift : '';

    my @lines = grep(/^$account:/, @userlist);
    return "Account [$account] cannot found!" unless @lines;
    my $line = shift @lines;

    chomp $line;

    my $retstr = '';
    if ($field && $line =~ m/[:;]$field<(.*?)(?:;|$)/) {
        $retstr .= decode_base64($1);
    }
    elsif ($field) {
        $retstr .= '';
    }
    else {
        foreach my $key (keys %FIELDSDEF) {
            $retstr .= $FIELDSDEF{$key}.'='.get_field_info($account, $FIELDSDEF{$key})."\n";
        }
    }

    return $retstr;
}
