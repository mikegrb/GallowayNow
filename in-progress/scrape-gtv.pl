#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use 5.014;

use Mojo::UserAgent;
use Data::Printer;

$| = 1;

my $ua = Mojo::UserAgent->new;

my $items
    = $ua->get('http://webus.telvue.com/wi/index.aspx?cid=39')
    ->res->dom->at('#MessageSelect')
    ->children->map(
    sub { $_->text =~ m/^- (.*)$/ ? [ $_->attrs('value'), $1 ] : () } );

open my $index, '>', 'output/index.html';

for my $item (@$items) {
    print "Grabbing $item->[1]... ";
    my ( $cid, $mid, $mpi ) = split /:/, $item->[0];
    my $url = "http://webus.telvue.com/wi/index.aspx?cid=$cid&mid=$mid&mpi=$mpi";
    my $pages = $ua->get("${url}&pno=1")->res->dom->at('#message-pages')->children->size;
    
    print "$pages pages... ";
    
    say $index "<h2>$item->[1]</h3>";
    for my $page ( 1 .. $pages ) {
        print "$page ";
        my $filename = "$mid-$mpi-$page.png";
        my $url = "http://webus.telvue.com/ThumbnailPreview/GetThumbnail.aspx?" 
        . "weblinx=true&mid=$mid&mpi=$mpi&pno=$page";
        $ua->get($url)->res->content->asset->move_to("output/$filename");
        say $index qq{<img src="$filename" width="400" height="300"/>};
    }
    say $index "<hr/>";
    print "\n";
}
