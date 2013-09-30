#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use 5.014;

use Mojo::UserAgent;
use Data::Printer;
use YAML::Tiny;
use FindBin;
use POSIX 'strftime';

$| = 1;

my $OUT_PATH  = $FindBin::Bin . '/../../data/gtv';
my $YAML_PATH = $OUT_PATH . '/data.yml';
my $IMG_PATH  = $OUT_PATH . '/images/';
mkdir $OUT_PATH unless -d $OUT_PATH;
mkdir $IMG_PATH unless -d $IMG_PATH;

my $seen = YAML::Tiny->read($YAML_PATH) || YAML::Tiny->new;
my $data = YAML::Tiny->new;
$data->[0]{add_date} = $seen->[0]{add_date};

my $today = strftime( '%F', localtime );
my $ua = Mojo::UserAgent->new;

my $items
    = $ua->get('http://webus.telvue.com/wi/index.aspx?cid=39')
    ->res->dom->at('#MessageSelect')
    ->children->map( sub { [ $_->attr('value'), $_->text ] } );

my $heading;
for my $item (@$items) {
    $item->[0] =~ s/:/-/g;
    if ( $item->[1] =~ m/^- (.*)$/ ) {
        my $item = { id => $item->[0], title => $1 };
        unless ( $item->{pages} = seen($item) ) {
            $data->[0]{add_date}{$today} ||= [];
            push @{ $data->[0]{add_date}{$today} }, $item->{id};
            $item->{pages} = get_pages($item);
        }
        push @{ $heading->{items} }, $item;
    }
    elsif ( $item->[1] ) {
        push @{ $data->[0]{messages} }, $heading if $heading;
        $heading = { title => $item->[1], items => [] };
    }
}
$data->write($YAML_PATH);

sub seen {
    my ($item) = @_;
    my $id = $item->{id};
    for my $section ( @{ $seen->[0]{messages} } ) {
        for my $item ( @{ $section->{items} } ) {
            return $item->{pages} if $item->{id} eq $id;
        }
    }
    return;
}

sub get_pages {
    my ($item) = @_;
    print "Grabbing $item->{title}... ";
    my ( $cid, $mid, $mpi ) = split /-/, $item->{id};
    my $url
        = "http://webus.telvue.com/wi/index.aspx?cid=$cid&mid=$mid&mpi=$mpi";
    my $pages = $ua->get("${url}&pno=1")->res->dom->at('#message-pages')
        ->children->size;

    print "$pages pages... ";

    for my $page ( 1 .. $pages ) {
        print "$page ";
        my $filename = $item->{id} . "-$page.png";
        my $url
            = 'http://webus.telvue.com/ThumbnailPreview/GetThumbnail.aspx?'
            . "weblinx=true&mid=$mid&mpi=$mpi&pno=$page";
        $ua->get($url)->res->content->asset->move_to("$IMG_PATH/$filename");
        sleep 1;
    }
    print "\n";

    return $pages;
}
