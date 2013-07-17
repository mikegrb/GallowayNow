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

    my $short_sender;
    my $tweet = $cap_data->{headline};
    
    if ( $tweet =~ m/(?:Weather Statement|Air Quality Alert)/ ) {
        $tweet
            =~ s/issued \S+ \d+ at (\d+:\d+(?:A|P)M) E(?:S|DT) ? by (.*)$/issued at $1/;
            $short_sender = $2;
    }
    else {
        $tweet
            =~ s/issued .*?until (.*? at \d+:\d+(?:A|P)M) E(?:S|DT) by (.*)$/for Atlantic County until $1, issued/;
        $short_sender = $2;
    }

    my $issued_by
        = exists( $twats{ $cap_data->{senderName} } )
        ? $twats{ $cap_data->{senderName} }
        : $short_sender;
    $tweet .= " by $issued_by $event";
    return $tweet;
}

1;

