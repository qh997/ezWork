package General;

use warnings;
use strict;
use Time::Format;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    $DEBUG
    %STATUS
    get_configs
    encode64
    debug
);

our $DEBUG = 1;

my $CONFIG_FILE = 'ezWork.config';

sub get_configs {
    open my $CF, "< $CONFIG_FILE";
    my @file_content = <$CF>;
    close $CF;

    my %configs;
    foreach my $line (@file_content) {
        chomp $line;

        if ($line =~ m{^\s*(.*?)\s*=\s*(.*?)\s*$}) {
            $configs{$1} = $2;
        }
    }

    return %configs;
}

sub encode64 {
    my $input = shift;

    return encode_base64($input, '');
}

sub debug {
    my $string = shift;
    
    print $time{'yyyy/mm/dd hh:mm:ss'}.' - '.$string."\n" if $DEBUG;
}

return 1;
