package GallowayNow::PublicNotices;
use Mojo::Base 'Mojolicious::Controller';

my $results_per_page = 10;
my $summary_length   = 400;

sub index {
    my $self = shift;
    my $page = $self->stash('page') || 1;

    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $self->config->{notices_db} );
    my $q   = $dbh->prepare(
        q{
        SELECT * FROM `Notice`
        ORDER BY `id` DESC LIMIT ?, ?
    }
    );
    $q->execute( ( $page - 1 ) * $results_per_page, $results_per_page );
    my @notices;
    while ( my $row = $q->fetchrow_hashref ) {
        $row->{body} =~ m/^(.{1,$summary_length}).*(Printer Fee:.*)$/g;
        my $sum = $1;
        $sum .= '...' if length $sum == $summary_length;
        $row->{body} = "$sum\n<br/>$2";
        push @notices, $row;
    }

    # Render template "example/welcome.html.ep" with message
    $self->render( notices => \@notices, page => $page );
}

sub view {
    my $self = shift;
    my $dbh  = DBI->connect( 'dbi:SQLite:dbname=' . $self->config->{notices_db} );
    my $q    = $dbh->prepare(q{ SELECT * FROM `Notice` WHERE `id` = ? });
    $q->execute( $self->stash('id') );
    my $notice = $q->fetchrow_hashref;
    $self->render( notice => $notice );
}

1;
