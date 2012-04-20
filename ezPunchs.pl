#!/usr/bin/env perl
use warnings;
use strict;

my $SPECUSER = @ARGV ? shift : '';
my $USERFILE = '/home/gengs/develops/ezWork/accountpunchs';

my $NOW_DATE = now_date();
my $NOW_WEEK = now_week();

my $EXPCT = 60 * 28 + 18;
my $VARIN = 60 *  4 + 27;
my $RANGE = 60 * 18 + 41;
my $ROUND = 5;

print "$NOW_DATE:$NOW_WEEK\n";

open my $UF, "< $USERFILE";
my @userlist = <$UF>;
close $UF;

foreach my $user (@userlist) {
    if ($user =~ /^(.*?):(.*?):(.*)$/) {
        my $user_name = $1;
        my $user_pass = $2;
        my @user_time = split ';', $3;

        next if ($SPECUSER && ($SPECUSER ne $user_name));

        my $activity = '';
        foreach my $date_def (@user_time) {
            if (!$activity && $date_def =~ /^(\d+)-(\d+)$/) {
                my ($lower, $upper) = ($1, $2);
                $activity = $lower =~ /^\d$/ ? $lower <= $NOW_WEEK && $NOW_WEEK <= $upper
                                             : $lower <= $NOW_DATE && $NOW_DATE <= $upper;
            }
            elsif ($activity && $date_def =~ /^-(\d+)-(\d+)$/) {
                my ($lower, $upper) = ($1, $2);
                $activity = $lower =~ /^\d$/ ? $lower >= $NOW_WEEK && $NOW_WEEK >= $upper
                                             : $lower >= $NOW_DATE && $NOW_DATE >= $upper;
            }
            elsif (!$activity && $date_def =~ /^(\d+)$/) {
                my $date = $1;
                $activity = $date =~ /^\d$/ ? $date == $NOW_WEEK
                                            : $date == $NOW_DATE;
            }
            elsif ($activity && $date_def =~ /^-(\d+)$/) {
                my $date = $1;
                $activity = $date =~ /^\d$/ ? $date != $NOW_WEEK
                                            : $date != $NOW_DATE;
            }
        }

        if ($activity) {
            my $run_time = get_normal_distribution($EXPCT, $VARIN, $RANGE, $ROUND);

            my $pid = fork();
            if (defined $pid && $pid == 0) {
                print "$user_name sleep $run_time\n";
                my $fail = 5;
                while ($fail) {
                    system("/home/gengs/develops/ezWork/ezPunch.pl '$user_name' '$user_pass'") ? ($fail--) : ($fail = 0);

                    sleep 2 if $fail;
                }

                exit 0;
            }
        }
        else {
            print "Do not running today.\n"
        }
    }
}

wait();
sleep 1;
print "Finished.\n";

sub now_date {
    my $NowTime = time();
    my ($year, $month, $day, $hour, $min, $sec);
    $year = (localtime($NowTime))[5] + 1900;
    $month = (localtime($NowTime))[4] + 1;
    $month =~ s/^(\d{1})$/0$1/;
    $day = (localtime($NowTime))[3];
    $day =~ s/^(\d{1})$/0$1/;

    return "$year$month$day";
}

sub now_week {
    my (undef, undef, undef, undef, undef, undef, $wday, undef) = localtime(time());

    return $wday ? $wday : 7;
}

sub get_normal_distribution {
    my $expectations = @_ ? shift : 0;
    my $variance = @_ ? shift : 1;
    my $range = @_ ? shift : 2;
    my $rounding = @_ ? shift : 5;

    my $PI = 3.1415926535897;
    my $gaussian = undef;
    until (judgment_range($gaussian, $expectations, $range)) {
        $gaussian = sqrt(-2 * log(rand(1)))*cos(2 * $PI * rand(1));
        $gaussian *= $variance;
        $gaussian += $expectations;
    }

    $gaussian += '0.'.(10 - $rounding);
    $gaussian =~ s/(?=\.).*//;

    return $gaussian;
}

sub judgment_range {
    my ($value, $centr, $range) = @_;
    my ($lower, $upper) = ($centr - $range, $centr + $range);

    return 1 if $value && $lower < $value && $value < $upper;

    return 0;
}