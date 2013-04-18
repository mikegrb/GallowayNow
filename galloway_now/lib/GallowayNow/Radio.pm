package GallowayNow::Radio;

use POSIX 'strftime';
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->render();
}

sub GetLog {
    my $self = shift;
    my $path = $GallowayNow::archive_path
        . strftime( '/%Y/%m/%d/log.txt', localtime );
    my $data = tail($path);
    $self->render( text => $data, format => 'txt' );
}

sub tail {
    my $path = shift;
    my $lines = shift || 5;

    open( my $fh, '-|', '/usr/bin/tail', '-n', $lines, $path ) or return;
    my @lines = <$fh>;
    close($fh);
    return join '', @lines;
}

1;
