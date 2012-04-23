package General;

use warnings;
use strict;
require Exporter;
use version;

use words;

our $VERSION = qv('0.0.1');

our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_configs
);

my $CONFIG_FILE = 'ezWork.config';

sub get_configs {
    open my $CF, "< $CONFIG_FILE";
    my @file_content = <$CF>;
    close $CF;

    my %configs;
    foreach my $line (@file_content) {
        chomp $line;

        if ($line =~ m{(.*?)=(.*)}) {
            $configs{$1} = $2;
        }
    }

    return %configs;
}

return 1;
