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
    sub { [ $_->attrs('value'), $_->text ] } );

open my $index, '>', 'output/index.html';
say $index "<ul>";

my $second_level = 0;
for my $item (@$items) {
    $item->[0] =~ s/:/-/g;
    if ($item->[1] =~ m/^- (.*)$/) {
        $item->[2] = $1;
        say $index "\t<ul>" unless $second_level++;
        say $index qq{\t\t<li><a href="#$item->[0]">$item->[2]</a></li>};
    }
    elsif ($item->[1]) {
        say $index "\t</ul>" if $second_level;
        $second_level = 0;
        say $index qq{\t<li>$item->[1]</li>};
    }
}
say $index "</ul>"; 

for my $item (@$items) {
    next unless $item->[2];
    print "Grabbing $item->[2]... ";
    my ( $cid, $mid, $mpi ) = split /-/, $item->[0];
    my $url = "http://webus.telvue.com/wi/index.aspx?cid=$cid&mid=$mid&mpi=$mpi";
    my $pages = $ua->get("${url}&pno=1")->res->dom->at('#message-pages')->children->size;
    
    print "$pages pages... ";
    
    say $index qq{<a name="$item->[0]"/><h2>$item->[2]</h2>};
    for my $page ( 1 .. $pages ) {
        print "$page ";
        my $filename = $item->[0] . "-$page.png";
        my $url = "http://webus.telvue.com/ThumbnailPreview/GetThumbnail.aspx?" 
        . "weblinx=true&mid=$mid&mpi=$mpi&pno=$page";
        $ua->get($url)->res->content->asset->move_to("output/$filename");
        say $index qq{<img src="$filename" width="400" height="300"/>};
        sleep 1;
    }
    say $index "<hr/>";
    print "\n";
}
