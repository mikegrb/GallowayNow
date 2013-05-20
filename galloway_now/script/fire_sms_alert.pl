#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use File::Touch;
use GallowayNow;
use Config::Auto;
use POSIX 'strftime';
use WWW::Twilio::API;

my $touch_file     = '/tmp/gnow_twilio_fire';
my $sleep_time     = 5;                         # min 5 min between sms
my $log_lines      = 20;                        # check last 20 lines of logs
my $required_count = 3;                         # require 3 matches

exit 10
    if -e $touch_file && ( stat $touch_file )[9] > time - ( $sleep_time * 60 );

my $config = Config::Auto::parse("$FindBin::Bin/../../conf/twilio.conf");
my $archive_path
    = strftime( "$GallowayNow::archive_path/%Y/%m/%d/log.txt", localtime );

chomp( my $count = `tail -n $log_lines $archive_path | grep -ci fire` );

if ( $count < $required_count ) {
    say "$count lines with fire in last 10 lines of $archive_path";
    exit 0;
}

my $message = "$count messages matching fire in activity log.";
say $message;

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

touch($touch_file);
say $res->{content};
