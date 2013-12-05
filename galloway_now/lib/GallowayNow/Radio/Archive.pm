package GallowayNow::Radio::Archive;

use POSIX 'strftime';
use Mojo::Base 'Mojolicious::Controller';

sub index {
}

sub sizes {
    my $self = shift;

    my $year  = $self->stash('year');
    my $month = $self->stash('month');
    my $day   = $self->stash('day');

    for ($year, $month, $day) {
        if (/[^\d]/) {
            $self->render({text => 'nop', status => 403});
            return;
        }
    }
    
    my $sizes;
    for my $mp3 (glob $GallowayNow::archive_path . "/$year/$month/$day/*mp3") {
        (my $hour = $mp3) =~ s|^.*/(\d\d)00\.mp3$|$1|;
        $sizes->{$hour} = -s $mp3;
    }
    $self->render( json => { size_for_hour => $sizes } );
}

sub get_log {
    my $self = shift;
    my $date = $1 if ( $self->stash('date') =~ m|^(\d{4}/\d{2}/\d{2})$| );
    $date ||= strftime( '%Y/%m/%d', localtime );

    $self->res->headers->content_type('text/plain');
    $self->res->content->asset(
        Mojo::Asset::File->new(
            path => $GallowayNow::archive_path . '/' . $date . '/log.txt'
        ) );
    $self->rendered(200);
}

sub ArchiveToday {
    my $self = shift;
    $self->redirect_to( '/radio/archive' . _get_archive_today() );
}

sub tail {
    my $path = shift;
    my $lines = shift || 5;

    open( my $fh, '-|', '/usr/bin/tail', '-n', $lines, $path ) or return;
    my @lines = <$fh>;
    close($fh);
    return join '', @lines;
}

sub _get_archive_today {
    return strftime( '/%Y/%m/%d/', localtime );
}

1;
