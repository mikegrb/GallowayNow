#!/usr/bin/env perl

use strict;
use warnings;
use 5.014;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use GallowayNow::SMS;
use Mojo::UserAgent;
use Data::Dumper;
use Date::Parse;
use RRD::Simple;

# http://www.atlanticcityelectric.com/home/emergency/maps/stormcenter/data/thematic/current/thematic_areas.xml

my $ua = Mojo::UserAgent->new;

my $directory = get_directory();
my $timestamp = directory_to_timestamp($directory);
my $url
    = 'http://stormcenter.atlanticcityelectric.com.s3.amazonaws.com/data/interval_generation_data/'
    . $directory;

my $report = $ua->get($url.'/report2.js')->res->json->{file_data}->{curr_custs_aff}->{areas}->[0]->{areas}->[0];
my $data = $ua->get($url.'/data.js')->res->json->{file_data};
die "Didn't get data :'(" unless $report && $data;

if ( $data->{servlet_interval} != 600 || $data->{storm_mode} ne 'n' ) {
    say "Unseen storm mode or interval: storm_mode: $data->{storm_mode}, "
        . "interval $data->{servlet_interval}";
}

my $total_without_power = $report->{custs_out};
my $total_outages       = $data->{total_outages};

my %rrd_ds = (
    total_without => $total_without_power,
    total_outages => $total_outages
);

for my $area ( @{ $report->{areas} } ) {
    my $county = lc $area->{area_name};
    $county =~ tr/ /_/;
    $rrd_ds{"${county}_without"} = $area->{custs_out};
    $rrd_ds{"${county}_total"}   = $area->{total_custs};

    if ( $county eq 'atlantic' ) {
        my ($galloway)
            = grep { $_->{area_name} eq 'Galloway Twp' } @{ $area->{areas} };
        next unless $galloway;
        $rrd_ds{galloway_without} = $galloway->{custs_out};
        $rrd_ds{galloway_total}   = $galloway->{total_custs};

    }
}

my $rrd = RRD::Simple->new(
    file           => "/home/michael/public_html/ace_outages/outages.rrd",
    tmpdir         => "/var/tmp",
    cf             => [qw(AVERAGE MAX)],
    default_dstype => "GAUGE",
    on_missing_ds  => "add",
);

while ( my ( $ds, $value ) = each %rrd_ds ) {
    next unless $ds =~ m/^([^_]+)_without$/;
    my $area       = ucfirst $1;
    my $last_value = $rrd->info->{ds}{$ds}{last_ds};
    my $delta      = $value - $last_value;
    next unless abs($delta) >= 100;
    my $message =  "Large magnitude change for $area, $delta, now $value.";
    say $message;
    send_sms($message) if $area eq 'Galloway';
}

if ( $timestamp == $rrd->last ) {
    # don't freak out if last update isn't older than an hour
    exit unless $timestamp < time - 3600;
    die "Haven't updated rrd since "
        . scalar( localtime( $rrd->last ) ) . "!\n";
}

$rrd->update( $timestamp, %rrd_ds );

$rrd->graph(
    destination     => '/home/michael/public_html/ace_outages',
    basename        => 'total_outage',
    sources         => [qw (total_without total_outages)],
    title           => "Total ACE Customers w/o Power",
    extended_legend => 1,
    width           => 800,
    height          => 200,
);

$rrd->graph(
    destination     => '/home/michael/public_html/ace_outages',
    basename        => 'galloway_twp_outage',
    sources         => ['galloway_without'],
    title           => "Galloway Twp Customers w/o Power",
    extended_legend => 1,
    width           => 800,
    height          => 200,
);

$rrd->graph(
    destination     => '/home/michael/public_html/ace_outages',
    basename        => 'atlantic_county_outage',
    sources         => ['atlantic_without'],
    title           => "Atlantic County Customers w/o Power",
    extended_legend => 1,
    width           => 800,
    height          => 200,
);

$rrd->graph(
    destination     => '/home/michael/public_html/ace_outages',
    basename        => 'ocean_county_outage',
    sources         => ['ocean_without'],
    title           => "Ocean County Customers w/o Power",
    extended_legend => 1,
    width           => 800,
    height          => 200,
);


sub get_directory {
    my $report
        = $ua->get(
        'http://stormcenter.atlanticcityelectric.com.s3.amazonaws.com/data/interval_generation_data/metadata.xml'
        )->res->dom;

    die "Didn't get data :'(" unless $report;

    return $report->at('directory')->text;
}

sub directory_to_timestamp {
    my $directory  = shift;
    my @time_parts = split( '_', $directory );
    my $date       = join( '-', @time_parts[ 0 .. 2 ] ) . ' '
        . join( ':', @time_parts[ 3 .. 5 ] );
    return str2time( $date, 'EST' );
}

