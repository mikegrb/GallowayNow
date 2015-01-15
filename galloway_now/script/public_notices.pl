#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use DBI;
use XML::RSS;
use GallowayNow::MockConfig;
use Mojo::UserAgent;
use POSIX 'strftime';

my $domain = 'http://www.pressofatlanticcity.com';
my $url = $domain . '/classifieds/community/announcements/legal/?l=50&q=galloway';
my $dbh = DBI->connect(
    'dbi:SQLite:dbname=' . $GallowayNow::MockConfig::config->{notices_db} );

#
# Retrieve Currently Listed Notices
#

my $res = Mojo::UserAgent->new->get($url)->res;
my $seen = $dbh->prepare(
    q{
    SELECT `id` FROM `Notice` WHERE `online_id` = ?
} );

my $insert = $dbh->prepare(
    q{
    INSERT INTO `Notice` (online_id, pub_id, seen_date, title, body)
    VALUES (?, ?, DATE('now'), ?, ? )
    }
);

for my $notice ( reverse $res->dom->find('.listing')->each ) {
    # parse stuffs
    my $title    = $notice->at('span.actual-title')->text;
    my $link     = $notice->at('h3.title > a')->attr('href');
    my ($id)     = ( $link =~ m|ad_([\w-]*)\.html$| );

    # have we seen this?
    $seen->execute($id);
    my ($rowid) = $seen->fetchrow_array();
    if ($rowid) {
        say "We've seen $title - $id  - $link";
        next;
    }

    # it's new
    my $text     = get_notice_text($domain . $link);
    my ($pub_id) = ($text) =~ m| #(\d+) Pub Date|;
    $insert->execute( $id, $pub_id, $title, $text );

    say "$title - $id  - $pub_id - $link";
    say $text;
    say '*' x 50;
}

#
# Generate RSS Feed
#

my $q   = $dbh->prepare(
    q{
    SELECT *, strftime("%s" ,seen_date) + (3600 * 11) as seen_ts FROM `Notice`
    ORDER BY `id` DESC LIMIT 25
} );
$q->execute;

my $rss = XML::RSS->new( version => '2.0' );

$rss->channel(
    title       => "Galloway Public Notices",
    link        => "http://gallowaynow.com/notices/",
    language    => 'en',
    description => "Press of Atlantic City Public Notices Matching Galloway",
    rating => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
);

while ( my $row = $q->fetchrow_hashref ) {

    $rss->add_item(
        title => $row->{title},
        permaLink =>
            "http://gallowaynow.com/notice/$row->{id}",
        description => $row->{body},
        pubDate     => strftime( "%a, %d %b %Y %T %z", localtime $row->{seen_ts} ) );
}

$rss->save( $FindBin::Bin . '/../public/public_notices.xml' );

sub get_notice_text {
    my $url = shift;
    state $ua = Mojo::UserAgent->new;
    return $ua->get($url)->res->dom->at('div.description > span.value > p')->text;
}

__END__

CREATE TABLE `Notice` (
    `id` Integer Primary Key NOT NULL,
    `online_id` Integer NOT NULL,
    `pub_id` Integer NOT NULL,
    `pub_date` DATE,
    `seen_date` DATE NOT NULL,
    `title` Text NOT NULL,
    `body` Text NOT NULL
);

CREATE UNIQUE INDEX online_id_idx ON Notice (online_id);


