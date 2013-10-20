#!/usr/bin/env perl

use 5.012;

use Facebook::Graph;
use Config::JSON;
use Ouch;

use List::Util 'first';
use YAML::Tiny;
use Data::Dumper;
use Data::Printer;
use Data::ICal;
use LWP::UserAgent;
use DateTime::Format::ICal;

my $fb_config = Config::JSON->new('my.conf')->get('ics2facebook');
my $fb        = Facebook::Graph->new($fb_config);

# get access token for the page
my $pages = $fb->query->find('me/accounts')
    ->include_metadata->request->as_hashref->{data};
my $page = first { $_->{name} eq 'Galloway Now' } @$pages;
$fb->access_token( $page->{access_token} );

# grab and parse ical
my $ical
    = LWP::UserAgent->new->get(
    'http://www.google.com/calendar/ical/ivgf5vo85m6t7daacoj4ei32e8%40group.calendar.google.com/public/basic.ics'
    )->content;
my $calendar = Data::ICal->new( data => $ical );

my $seen = YAML::Tiny->read("seen.yml") || YAML::Tiny->new;

# post events
foreach my $entry ( @{ $calendar->entries } ) {
    next unless $entry->properties->{summary}[0]{value};
    next if $seen->[0]{uids}{ $entry->properties->{uid}[0]{value} };

    for my $time ( 'dtstart', 'dtend' ) {
        next if $entry->properties->{$time}[0]{value} =~ /Z$/;
        $entry->properties->{$time}[0]{value}
            = 'TZID=America/New_York:' . $entry->properties->{$time}[0]{value};
    }

    say $entry->properties->{summary}[0]{value};
    say $entry->properties->{dtstart}[0]{value} . ' - '
        . $entry->properties->{dtend}[0]{value};
    say $entry->properties->{location}[0]{value};
    say $entry->properties->{description}[0]{value};
    say "";

    my $id = $fb->add_event->set_name(
        $entry->properties->{summary}[0]{value} )
        ->set_location( $entry->properties->{location}[0]{value} )
        ->set_description( $entry->properties->{description}[0]{value} )
        ->set_start_time( DateTime::Format::ICal->parse_datetime( $entry->properties->{dtstart}[0]{value} ) )
        ->set_end_time( DateTime::Format::ICal->parse_datetime( $entry->properties->{dtend}[0]{value} ) )
        ->publish->as_hashref->{id};

    $seen->[0]{uids}{ $entry->properties->{uid}[0]{value} } = {
        added_epoch => time,
        added_human => scalar localtime,
        id          => $id,
        title       => $entry->properties->{summary}[0]{value} };
}

$seen->write("seen.yml");
