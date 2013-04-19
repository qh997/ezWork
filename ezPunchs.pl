#!/usr/bin/env perl
use warnings;
use strict;
use MIME::Base64;

my $SPECUSER = @ARGV ? shift : '';
my $USERFILE = '/home/gengs/develops/ezWork/accountpunchs';

my $NOW_DATE = now_date();
my $NOW_WEEK = now_week();

my $EXPCT = 60 * 28 + 18;
my $VARIN = 60 *  4 + 27;
my $RANGE = 60 * 18 + 41;
my $ROUND = 5;

print "\n$NOW_DATE:$NOW_WEEK\n";

open my $UF, "< $USERFILE";
my @userlist = <$UF>;
close $UF;

my $global_time = shift @userlist;
my $global_activity = get_active($global_time);

foreach my $user (@userlist) {
    if ($user =~ /^(.*?):(.*?):(.*)$/) {
        my $user_name = $1;
        my $user_pass = decode_base64($2);
        my $user_time = $3;

        next if ($SPECUSER && ($SPECUSER ne $user_name));

        my $user_activity = get_active($user_time, $global_activity);

        if ($user_activity) {
            my $run_time = get_normal_distribution($EXPCT, $VARIN, $RANGE, $ROUND);

            my $pid = fork();
            if (defined $pid && $pid == 0) {
                print "$user_name sleep $run_time\n";
                sleep $run_time;
                my $fail = 5;
                while ($fail) {
                    system("/home/gengs/develops/ezWork/ezPunch.pl '$user_name' '$user_pass'") ? ($fail--) : ($fail = 0);

                    sleep 2 if $fail;
                }

                exit 0;
            }
        }
        else {
            print "$user_name: Do not running today.\n"
        }
    }
}

wait();
sleep 1;
print "$NOW_DATE:$NOW_WEEK Finished.\n";

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

sub get_active {
    my $time_str = shift;
    my $activity = @_ ? shift : '';
    my @time_ary = split ';', $time_str;

    foreach my $date_def (@time_ary) {
        if (!$activity && $date_def =~ /^(\d+)-(\d+)$/) {
            my ($lower, $upper) = ($1, $2);
            $activity = $lower =~ /^\d$/ ? $lower <= $NOW_WEEK && $NOW_WEEK <= $upper
                                         : $lower <= $NOW_DATE && $NOW_DATE <= $upper;
        }
        elsif ($activity && $date_def =~ /^-(\d+)-(\d+)$/) {
            my ($lower, $upper) = ($1, $2);
            $activity = $lower =~ /^\d$/ ? $lower > $NOW_WEEK || $NOW_WEEK > $upper
                                         : $lower > $NOW_DATE || $NOW_DATE > $upper;
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

    return $activity;
}

sub get_normal_distribution {
    my $expectations = @_ ? shift : 0;
    my $variance = @_ ? shift : 1;
    my $range = @_ ? shift : 2;
    my $rounding = @_ ? shift : 5;

    my $PI = 3.1415926535897;
    my $gaussian = undef;
    until (judgment_range($gaussian, $expectations, $range)) {
        $gaussian = sqrt(-2 * log(rand))*cos(2 * $PI * rand);
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
