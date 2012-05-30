#!/usr/bin/perl

use warnings;
use strict;
use version;
our $VERSION = qv('0.1.2');

BEGIN {push @INC, q[./lib]};
use General;
use User;
use FieldControl;

my $SPECUSER = @ARGV ? shift : '';

debug('Start ezDailys.');

my %CFGS = get_configs();

open my $UF, $CFGS{USERLIST};
my @userlist = <$UF>;
close $UF;

foreach (@userlist) {
    my $user_line = $_;
    chomp $user_line;

    if ($user_line =~ /^(.*?):(.*?):(.*)$/) {
        my $user = User -> new();
        $user -> account($1);
        $user -> password(decode64($2));
        next if ($SPECUSER && ($SPECUSER ne $user -> account));

        debug($user -> account);

        system("perl UpdateDailyOptions.pl '".$user -> account."' '".$user -> password."'")
            and do {debug($user -> account." can not be verified."); next;};

        my ($warning, undef) = $user -> infos_print();

        if ($warning) {
            debug($user -> account." has $warning problems.");
            next;
        }
        else {
            my $user_info = FieldControl -> new();
            $user_info -> user($user -> account);

            my $reportstr = "'".$user -> account."' '".$user -> password."'";
            my %infos = $user_info -> get_fields_value;
            foreach my $key ('TASK','PROJ','PROT','ACTV','SACT','MODE') {
                $reportstr .= " '".$infos{$key}."'";
            }

            debug('perl ezDaily.pl '.$reportstr);
            `perl ezDaily.pl $reportstr`;
        }
    }
}
