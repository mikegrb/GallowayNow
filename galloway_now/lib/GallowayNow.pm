package GallowayNow;
use Mojo::Base 'Mojolicious';

use DBI;
use Sys::Hostname;
use GallowayNow::NWSAlert::Active;

our $notices_db   = '/home/michael/public_html/public_notices/notices.db';
our $archive_path = '/home/michael/public_html/stream/archive';
our $app_path     = '/home/michael/gallowaynow';

if ( hostname() ne 'orion' ) {
    $notices_db   = '/Users/mgreb/Dropbox/Documents/proj/public_notice/notices.db';
    $archive_path = '/Users/mgreb/Dropbox/Documents/proj/scanner_archive/test';
    $app_path     = '/Users/mgreb/proj/gallowaynow';
}

sub startup {
    my $self = shift;

    $self->helper( nws_alerts => \&GallowayNow::NWSAlert::Active::fetch );

    my $r = $self->routes;

    $r->get('/')->to( 'Main#index', active_tab => 1 );
    $r->get('/radio/')->to( 'Radio#index', active_tab => 2 );
    $r->get('/radio/archive/:year/:month/:day')->to('radio-archive#index', active_tab => 2, year => undef, month => undef, day => undef);
    $r->get('/radio/log')->to('Radio#GetLog');
    $r->get('/radio/today')->to('Radio#ArchiveToday');
    $r->get('/outages/')->to( 'Outages#index',       active_tab => 3 );
    $r->get('/notices/')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notices/:page')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notice/:id')->to( 'PublicNotices#view', active_tab => 4 );
    $r->get('/calendar/')->to( 'Calendar#index', active_tab => 5 );
    $r->get('/links/')->to( 'Links#index', active_tab => 6 );
    $r->get('/about/')->to( 'About#index', active_tab => 7 );
    $r->get('/twiml')->to( 'Twiml#get');
}

1;
