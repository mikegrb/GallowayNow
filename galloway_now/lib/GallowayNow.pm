package GallowayNow;
use Mojo::Base 'Mojolicious';

use DBI;
use Sys::Hostname;
use GallowayNow::NWSAlert::Active;

sub startup {
    my $self = shift;

    $self->plugin('JSONConfig');
    $self->helper( nws_alerts => \&GallowayNow::NWSAlert::Active::fetch );

    my $r = $self->routes;

    $r->get('/')->to( 'Main#index', active_tab => 1 );
    $r->get('/radio/')->to( 'Radio#index', active_tab => 2 );
    $r->get('/radio/archive/:year/:month/:day')->to('radio-archive#index', active_tab => 2, year => undef, month => undef, day => undef);
    $r->get('/radio/archive/:year/:month/:day/sizes')->to('radio-archive#sizes', active_tab => 2);
    $r->get('/radio/log')->to('Radio#GetLog');
    $r->get('/radio/today')->to('Radio#ArchiveToday');
    $r->get('/radio/mobile')->to('Radio#mobile');
    $r->get('/outages/')->to( 'Outages#index',       active_tab => 3 );
    $r->get('/gtv/')->to( 'Gtv#index', active_tab => 8 );
    $r->get('/notices/')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notices/search')->to('PublicNotices#search', active_tab => 4);
    $r->get('/notices/:page')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notice/:id')->to( 'PublicNotices#view', active_tab => 4 );
    $r->get('/calendar/')->to( 'Calendar#index', active_tab => 5 );
    $r->get('/links/')->to( 'Links#index', active_tab => 6 );
    $r->get('/about/')->to( 'About#index', active_tab => 7 );
    $r->get('/twiml')->to( 'Twiml#get');
}

1;
