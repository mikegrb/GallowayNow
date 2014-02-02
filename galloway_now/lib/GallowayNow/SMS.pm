package GallowayNow::SMS;

use Mojo::Base -strict;

use GallowayNow::MockConfig;
use WWW::Twilio::API;
use Config::Auto;

sub import {
    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::send_sms' } = \&send;
}

sub send {
    my $message = shift;

    my $config = Config::Auto::parse(
        $GallowayNow::MockConfig::config->{app_path} . '/conf/fire_sms_alert.conf' );

    my $twilio = WWW::Twilio::API->new(
        AccountSid => $config->{account_sid},
        AuthToken  => $config->{auth_token},
    );

    my $res = $twilio->POST(
        'SMS/Messages.json',
        From => $config->{from},
        To   => $config->{alerts_to},
        Body => $message,
    );

    unless ( $res->{code} =~ /^2../ ) {
        die "Error: ($res->{code}): $res->{message}\n$res->{content}";
    }

    say $res->{content};
}

1;
