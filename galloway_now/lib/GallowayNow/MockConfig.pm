package GallowayNow::MockConfig;

use strict;
use warnings;

use Mojo::Server;
use File::Basename;

our $config;

BEGIN { $ENV{MOJO_MODE} = 'production' if `hostname` =~ /orion/ };

{
    my $server = Mojo::Server->new;
    my $app = $server->load_app(  dirname(__FILE__) .'/../../script/galloway_now' );
    $config = $app->config;
}

1;
