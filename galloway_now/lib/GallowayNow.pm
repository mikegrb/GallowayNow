package GallowayNow;
use Mojo::Base 'Mojolicious';

use DBI;
use Sys::Hostname;

our $notices_db   = '/home/michael/public_html/public_notices/notices.db';
our $archive_path = '/home/michael/public_html/stream/archive';

if ( hostname() ne 'orion' ) {
    $notices_db
        = '/Users/mgreb/Dropbox/Documents/proj/public_notice/notices.db';
    $archive_path = '/Users/mgreb/Dropbox/Documents/proj/scanner_archive/test';
}

sub startup {
    my $self = shift;

    my $r = $self->routes;

    $r->get('/')->to( 'Main#index', active_tab => 1 );
    $r->get('/radio/')->to( 'Radio#index', active_tab => 2 );
    $r->get('/radio/log')->to('Radio#GetLog');
    $r->get('/radio/today')->to('Radio#ArchiveToday');
    $r->get('/outages/')->to( 'Outages#index',       active_tab => 3 );
    $r->get('/notices/')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notices/:page')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notice/:id')->to( 'PublicNotices#view', active_tab => 4 );
    $r->get('/calendar/')->to( 'Calendar#index', active_tab => 5 );
    $r->get('/links/')->to( 'Links#index', active_tab => 6 );
    $r->get('/about/')->to( 'About#index', active_tab => 7 );

}

1;
