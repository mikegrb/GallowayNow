#!/usr/bin/env perl 

use 5.010;
use strict;
use warnings;

use DBI;
use Data::Printer;


my $db = shift || '/home/michael/public_html/public_notices/notices.db';

my $dbh = DBI->connect( 'dbi:SQLite:' . $db );
my $sth = $dbh->prepare('SELECT * FROM `Notice` ORDER BY `id` ASC');
$sth->execute;
while ( my $row = $sth->fetchrow_hashref ) {
    say $row->{id};
}
