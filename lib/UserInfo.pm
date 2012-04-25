package UserInfo;

use warnings;
use strict;
use MIME::Base64;
use version;
our $VERSION = qv('0.0.1');

use General;

my %SETDEFS = (
    'TASK' => 'txtTask',
    'PROJ' => 'selProject',
    'PROT' => 'selProTask',
    'ACTV' => 'selActType1',
    'SACT' => 'selActType2',
    'MODE' => 'selModule1',
);

use Class::Std::Utils; {
    my %user;
    
    sub new {
        my $class = shift;
        my $self = bless anon_scalar(), $class;
        
        $user{ident $self} = '';
        
        return $self;
    }
    
    sub user {
        my $self = shift;

        $user{ident $self} = @_ ? shift : '';

        return $user{ident $self};
    }
    
    sub SettingExists {
        my $set = shift;
        
        return exists $SETDEFS{$set} ? 1 : 0;
    }
}

return 1;