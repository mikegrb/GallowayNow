#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use RRD::Simple;
use Mojo::UserAgent;
use Data::Printer;

my $data = Mojo::UserAgent->new->get('http://gallowaynow.com:8000/mystats.xsl')->res->body;
exit unless $data =~ m/^Listeners: (\d+)$/m;
my $listeners = $1;

my $rrd = RRD::Simple->new(
    file           => "/home/michael/public_html/stream/stats/listeners.rrd",
    tmpdir         => "/var/tmp",
    cf             => [qw(LAST AVERAGE MAX)],
    default_dstype => "GAUGE",
    on_missing_ds  => "add",
);

$rrd->update( listeners => $listeners );

$rrd->graph(
    destination     => '/home/michael/public_html/stream/stats/',
    basename        => 'listeners',
    sources         => [qw (listeners)],
    title           => "Galloway Now Live Stream Listeners",
    extended_legend => 1,
    width           => 800,
    height          => 200,
);
