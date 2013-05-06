package GallowayNow::Radio;

use POSIX 'strftime';
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->render( archive_today => _get_archive_today() );
}

sub GetLog {
    my $self = shift;
    my $path = $GallowayNow::archive_path . _get_archive_today() . 'log.txt';
    my $data = tail($path);
    $self->render( text => $data, format => 'txt' );
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
    return strftime('/%Y/%m/%d/', localtime);
}

1;
