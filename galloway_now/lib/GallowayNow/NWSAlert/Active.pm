package GallowayNow::NWSAlert::Active;

use strict;
use warnings;

use 5.010;

use YAML::Tiny;
use Data::Dumper;

my @severity = (qw/ Extreme Severe Moderate Minor Unknown  /);

my %class_for_severity = (
    Extreme  => ' alert-error',
    Severe   => ' alert-error',
    Moderate => '',
    Minor    => ' alert-info',
    Unknown  => ' alert-info',
);

sub fetch {
    say "fetch alerts called \\o/";

    my $path = $GallowayNow::conf_path . "/active.yml";
    return [] unless -e $path && -s _ > 7;

    my $current_alerts = YAML::Tiny->read($path)
        || YAML::Tiny->new;
    $current_alerts = $current_alerts->[0];

    my %alerts_by_severity;
    @alerts_by_severity{@severity} = ( [], [], [], [], [] );

    while ( my ( $id, $alert ) = each %$current_alerts ) {
        $alert->{id}    = $id;
        $alert->{class} = $class_for_severity{ $alert->{severity} };
        # $alert->{class} .= ' alert-block' if $alert->{instruction};
        # $alert->{instruction} ||= '';
        push @{ $alerts_by_severity{ $alert->{severity} } }, $alert;
    }

    my @active_alerts;
    push @active_alerts, @{ $alerts_by_severity{$_} } for @severity;

    return \@active_alerts;

}

1;
