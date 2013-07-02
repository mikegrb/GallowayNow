#!/usr/bin/env perl

use strict;
use warnings;

use Weather::NOAA::Alert;
use Config::Auto;
use Net::Twitter;
use YAML::Tiny;
use Try::Tiny;
use FindBin;

use 5.010;
use Data::Dumper;

my %twats = (
    'NWS Storm Prediction Center (Storm Prediction Center - Norman, Oklahoma)'
        => '@NWSSPC',
    'NWS Philadelphia - Mount Holly (New Jersey, Delaware, Southeastern Pennsylvania)'
        => '@NWS_MountHolly',
);

# 22 june 2012 http://alerts.weather.gov/cap/product_list.txt
my %event_gets_tweeted = (
    '911 Telephone Outage'                       => 1,
    'Administrative Message'                     => 1,
    'Air Quality Alert'                          => 1,
    'Air Stagnation Advisory'                    => 1,
    'Ashfall Advisory'                           => 1,
    'Ashfall Warning'                            => 1,
    'Avalanche Warning'                          => 1,
    'Avalanche Watch'                            => 1,
    'Beach Hazards Statement'                    => 0,
    'Blizzard Warning'                           => 1,
    'Blizzard Watch'                             => 1,
    'Blowing Dust Advisory'                      => 1,
    'Blowing Snow Advisory'                      => 1,
    'Brisk Wind Advisory'                        => 0,
    'Child Abduction Emergency'                  => 1,
    'Civil Danger Warning'                       => 1,
    'Civil Emergency Message'                    => 1,
    'Coastal Flood Advisory'                     => 0,
    'Coastal Flood Statement'                    => 0,
    'Coastal Flood Warning'                      => 0,
    'Coastal Flood Watch'                        => 0,
    'Dense Fog Advisory'                         => 1,
    'Dense Smoke Advisory'                       => 1,
    'Dust Storm Warning'                         => 1,
    'Earthquake Warning'                         => 1,
    'Evacuation Immediate'                       => 1,
    'Excessive Heat Warning'                     => 1,
    'Excessive Heat Watch'                       => 1,
    'Extreme Cold Warning'                       => 1,
    'Extreme Cold Watch'                         => 1,
    'Extreme Fire Danger'                        => 1,
    'Extreme Wind Warning'                       => 1,
    'Fire Warning'                               => 1,
    'Fire Weather Watch'                         => 1,
    'Flash Flood Statement'                      => 1,
    'Flash Flood Warning'                        => 1,
    'Flash Flood Watch'                          => 1,
    'Flood Advisory'                             => 1,
    'Flood Statement'                            => 1,
    'Flood Warning'                              => 1,
    'Flood Watch'                                => 1,
    'Freeze Warning'                             => 0,
    'Freeze Watch'                               => 0,
    'Freezing Drizzle Advisory'                  => 1,
    'Freezing Fog Advisory'                      => 1,
    'Freezing Rain Advisory'                     => 1,
    'Freezing Spray Advisory'                    => 0,
    'Frost Advisory'                             => 0,
    'Gale Warning'                               => 1,
    'Gale Watch'                                 => 1,
    'Hard Freeze Warning'                        => 0,
    'Hard Freeze Watch'                          => 0,
    'Hazardous Materials Warning'                => 1,
    'Hazardous Seas Warning'                     => 0,
    'Hazardous Seas Watch'                       => 0,
    'Hazardous Weather Outlook'                  => 0,
    'Heat Advisory'                              => 1,
    'Heavy Freezing Spray Warning'               => 0,
    'Heavy Freezing Spray Watch'                 => 0,
    'Heavy Snow Warning'                         => 1,
    'High Surf Advisory'                         => 0,
    'High Surf Warning'                          => 0,
    'High Wind Warning'                          => 1,
    'High Wind Watch'                            => 1,
    'Hurricane Force Wind Warning'               => 1,
    'Hurricane Force Wind Watch'                 => 1,
    'Hurricane Statement'                        => 1,
    'Hurricane Warning'                          => 1,
    'Hurricane Watch'                            => 1,
    'Hurricane Wind Warning'                     => 1,
    'Hurricane Wind Watch'                       => 1,
    'Hydrologic Advisory'                        => 1,
    'Hydrologic Outlook'                         => 0,
    'Ice Storm Warning'                          => 1,
    'Lake Effect Snow Advisory'                  => 0,
    'Lake Effect Snow and Blowing Snow Advisory' => 0,
    'Lake Effect Snow Warning'                   => 0,
    'Lake Effect Snow Watch'                     => 0,
    'Lakeshore Flood Advisory'                   => 0,
    'Lakeshore Flood Statement'                  => 0,
    'Lakeshore Flood Warning'                    => 0,
    'Lakeshore Flood Watch'                      => 0,
    'Lake Wind Advisory'                         => 0,
    'Law Enforcement Warning'                    => 1,
    'Local Area Emergency'                       => 1,
    'Low Water Advisory'                         => 0,
    'Marine Weather Statement'                   => 0,
    'Nuclear Power Plant Warning'                => 1,
    'Radiological Hazard Warning'                => 1,
    'Red Flag Warning'                           => 1,
    'Rip Current Statement'                      => 0,
    'Severe Thunderstorm Warning'                => 1,
    'Severe Thunderstorm Watch'                  => 1,
    'Severe Weather Statement'                   => 1,
    'Shelter In Place Warning'                   => 1,
    'Sleet Advisory'                             => 1,
    'Sleet Warning'                              => 1,
    'Small Craft Advisory'                       => 0,
    'Snow Advisory'                              => 1,
    'Snow and Blowing Snow Advisory'             => 1,
    'Special Marine Warning'                     => 0,
    'Special Weather Statement'                  => 1,
    'Storm Warning'                              => 1,
    'Storm Watch'                                => 1,
    'Test'                                       => 0,
    'Tornado Warning'                            => 1,
    'Tornado Watch'                              => 1,
    'Tropical Storm Warning'                     => 1,
    'Tropical Storm Watch'                       => 1,
    'Tropical Storm Wind Warning'                => 1,
    'Tropical Storm Wind Watch'                  => 1,
    'Tsunami Advisory'                           => 1,
    'Tsunami Warning'                            => 1,
    'Tsunami Watch'                              => 1,
    'Typhoon Statement'                          => 1,
    'Typhoon Warning'                            => 1,
    'Typhoon Watch'                              => 1,
    'Volcano Warning'                            => 1,
    'Wind Advisory'                              => 1,
    'Wind Chill Advisory'                        => 1,
    'Wind Chill Warning'                         => 1,
    'Wind Chill Watch'                           => 1,
    'Winter Storm Warning'                       => 1,
    'Winter Storm Watch'                         => 1,
    'Winter Weather Advisory'                    => 1,

);

my $config
    = Config::Auto::parse("$FindBin::Bin/../../conf/nws_alert_tweet.conf");

my $yaml = YAML::Tiny->read("$FindBin::Bin/../../conf/seen.yml");

my $new_alerts = 0;
try {
    my $alert = Weather::NOAA::Alert->new( [ $config->{county_zone} ] );
    $alert->errorLog(1);
    $alert->poll_events();

    my $events = $alert->get_events()->{ $config->{county_zone} };
    for my $event ( keys %{$events} ) {
        ( my $id = $event ) =~ s/^.*?\.php\?x=//;
        next if ( $yaml->[0]{seen_cap}{$id} );

        $yaml->[0]->{seen_cap}{$id} = localtime;
        $new_alerts++;

        my $tweet = generate_tweet_from_alert( $event, $events->{$event} );
        say "Generated Tweet:\n\t$tweet";

        unless ( exists $event_gets_tweeted{ $events->{$event}{event} } ) {
            say "!!! Don't know about $event->{$event}{event}";
            next;
        }

        if ( $event_gets_tweeted{ $events->{$event}{event} } ) {

            my $nt = Net::Twitter->new(
                traits              => [qw/OAuth API::RESTv1_1/],
                consumer_key        => $config->{consumer_key},
                consumer_secret     => $config->{consumer_secret},
                access_token        => $config->{access_token},
                access_token_secret => $config->{access_token_secret},
            );
            $nt->update($tweet);
            say "Tweeted.";
        }
    }
}
catch {
    die $_
        unless $_ =~ m/^Can't call method "children" on an undefined value/;
};

$yaml->write("$FindBin::Bin/../../conf/seen.yml") if $new_alerts;

sub generate_tweet_from_alert {
    my ( $event, $cap_data ) = @_;

    my $tweet = $cap_data->{headline};
    $tweet
        =~ s/issued .*?until (.*? at \d+:\d+(?:A|P)M) E(?:S|DT) by (.*)$/for Atlantic County until $1/;
    my $short_sender = $2;
    my $issued_by
        = exists( $twats{ $cap_data->{senderName} } )
        ? $twats{ $cap_data->{senderName} }
        : $short_sender;
    $tweet .= ", issued by $issued_by $event";
    print STDERR Dumper $cap_data;
    return $tweet;
}
