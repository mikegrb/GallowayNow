package GallowayNow::NWSAlert::ToTweet;

use strict;
use warnings;

my %twats = (
    'NWS Storm Prediction Center (Storm Prediction Center - Norman, Oklahoma)'
        => '@NWSSPC',
    'NWS Philadelphia - Mount Holly (New Jersey, Delaware, Southeastern Pennsylvania)'
        => '@NWS_MountHolly',
);

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
    return $tweet;
}

1;
