package GallowayNow::Radio::Archive;

use POSIX 'strftime';
use Mojo::Base 'Mojolicious::Controller';

sub index {
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
