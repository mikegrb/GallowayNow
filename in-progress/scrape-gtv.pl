#!/usr/bin/env perl

use strict;
use warnings;

use 5.014;

use Mojo::UserAgent;
use Data::Printer;

my $ua = Mojo::UserAgent->new;

my $items
    = $ua->get('http://webus.telvue.com/wi/index.aspx?cid=39')
    ->res->dom->at('#MessageSelect')
    ->children->map(
    sub { $_->text =~ m/^- / ? [ $_->attrs('value'), $_->text ] : () } );

p $items;

__END__

http://webus.telvue.com/wi/index.aspx?cid=39



items is now a Mojo::Collection that looks like:

[0]  [
    [0] "39:8140:17453",
    [1] "- THE GALLOWAY TOWNSHIP ENVIRONMENTAL COMMISSION"
],
[1]  [
    [0] "39:506493:861326",
    [1] "- ONLY RAIN DOWN THE DRAIN"
],
[2]  [
    [0] "39:901865:1468592",
    [1] "- AFFORDABLE HOUSING UNITS"
],
[3]  [
    [0] "39:499560:849554",
    [1] "- Mid Atlantic AARP"
],


Next step is hit url for each message:
cid,mid,mpi are the first element split on :
http://webus.telvue.com/wi/index.aspx?cid=39&mid=630683&mpi=1051652&pno=1


on that page for each item #message-pages contains an A href for each page in
that message

message page thumbnails are then:
pno == page number
http://webus.telvue.com/ThumbnailPreview/GetThumbnail.aspx?weblinx=true&mid=630683&mpi=1051652&pno=1