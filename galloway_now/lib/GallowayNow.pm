package GallowayNow;
use Mojo::Base 'Mojolicious';

use DBI;
use Sys::Hostname;

our $notices_db = '/home/michael/public_html/public_notices/notices.db';

sub startup {
    my $self = shift;

    $notices_db = '/Users/mgreb/Dropbox/Documents/proj/public_notice/notices.db'
        if hostname() eq 'soryu2.linlan';

    my $r = $self->routes;

    $r->get('/')->to( 'Main#index', active_tab => 1 );
    $r->get('/radio/')->to( 'Radio#index', active_tab => 2 );
    $r->get('/outages/')->to( 'Outages#index',       active_tab => 3 );
    $r->get('/notices/')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notices/:page')->to( 'PublicNotices#index', active_tab => 4 );
    $r->get('/notice/:id')->to( 'PublicNotices#view', active_tab => 4 );
    $r->get('/calendar/')->to( 'Calendar#index', active_tab => 5 );
    $r->get('/links/')->to( 'Links#index', active_tab => 6 );
}

1;
