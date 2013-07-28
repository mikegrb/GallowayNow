#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use 5.014;

use Mojo::UserAgent;
use Data::Printer;
use FindBin;

my $out_path = $FindBin::Bin . '/output';

$| = 1;

my $ua = Mojo::UserAgent->new;

my $items
    = $ua->get('http://webus.telvue.com/wi/index.aspx?cid=39')
    ->res->dom->at('#MessageSelect')
    ->children->map( sub { [ $_->attrs('value'), $_->text ] } );

open my $index, '>', $out_path . '/index.html';

# Table of Contents
say $index "<ul>";
my $second_level = 0;
for my $item (@$items) {
    $item->[0] =~ s/:/-/g;
    if ( $item->[1] =~ m/^- (.*)$/ ) {
        $item->[2] = $1;
        say $index "\t<ul>" unless $second_level++;
        say $index qq{\t\t<li><a href="#$item->[0]">$item->[2]</a></li>};
    }
    elsif ( $item->[1] ) {
        say $index "\t</ul>" if $second_level;
        $second_level = 0;
        say $index qq{\t<li>$item->[1]</li>};
    }
}
say $index "</ul>";

# Messages
for my $item (@$items) {
    next unless $item->[2];

    my $img_path = $out_path . '/' . $item->[0];
    my $pages    = 1;

    if ( -e $img_path . '-1.png' ) {
        print "We've seen $item->[2]";
        $pages++ while ( -e $img_path . "-$pages.png" );
        $pages--;
    }

    else {
        print "Grabbing $item->[2]... ";
        my ( $cid, $mid, $mpi ) = split /-/, $item->[0];
        my $url
            = "http://webus.telvue.com/wi/index.aspx?cid=$cid&mid=$mid&mpi=$mpi";
        $pages = $ua->get("${url}&pno=1")->res->dom->at('#message-pages')
            ->children->size;

        print "$pages pages... ";

        for my $page ( 1 .. $pages ) {
            print "$page ";
            my $filename = $item->[0] . "-$page.png";
            my $url
                = 'http://webus.telvue.com/ThumbnailPreview/GetThumbnail.aspx?'
                . "weblinx=true&mid=$mid&mpi=$mpi&pno=$page";
            $ua->get($url)->res->content->asset->move_to("$out_path/$filename");
            sleep 1;
        }
        $item->[2] = '* ' . $item->[2];
    }

    add_item_to_index( $item, $pages );

    print "\n";
}

sub add_item_to_index {
    my ( $item, $pages ) = @_;
    say $index qq{<a name="$item->[0]"/><h2>$item->[2]</h2>};
    say $index qq{<img src="$item->[0]-$_.png" width="400" height="300"/>}
        for 1 .. $pages;
    say $index qq{<hr/>};
}
