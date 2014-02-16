#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use File::Touch;
use POSIX 'strftime';
use GallowayNow::SMS;
use GallowayNow::MockConfig;

my $config = $GallowayNow::MockConfig::config->{fire_sms};
$config->{touch_file} .= '_awol';

exit 10
    if -e $config->{touch_file}
    && ( stat $config->{touch_file} )[9]
    > time - ( $config->{awol_time} * 60 * 2 );

my $today = strftime( '%Y/%m/%d/', localtime );
my $archive_path = $GallowayNow::MockConfig::config->{archive_path} . '/' . $today . '/log.txt';

my $silence_time = ( time - ( stat $archive_path )[9] ) / 60;

exit unless $silence_time > $config->{awol_time};

my $hours = int( $silence_time / 60 );
my $minutes = sprintf '%02i', $silence_time - ( $hours * 60 );

my $message = "No scanner log activity for $hours:$minutes";
say $message;
send_sms($message);

unless ( $res->{code} =~ /^2../ ) {
    die "Error: ($res->{code}): $res->{message}\n$res->{content}";
}

system '/usr/bin/touch', $config->{touch_file};

say $res->{content};
