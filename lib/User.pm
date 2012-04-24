package UserCommand;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;

use Class::Std::Utils; {
    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;
        
        return $self;
    }
}

return 1;
