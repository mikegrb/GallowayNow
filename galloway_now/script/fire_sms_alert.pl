#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use DateTime;
use File::Touch;
use GallowayNow::SMS;
use POSIX 'strftime';
use WWW::Twilio::API;
use List::MoreUtils 'uniq';
use GallowayNow::MockConfig;
use DateTime::Format::Strptime;

my $config = $GallowayNow::MockConfig::config->{fire_sms};
$config->{touch_file} .= '_fire';

exit 10
    if -e $config->{touch_file}
    && ( stat $config->{touch_file} )[9]
    > time - ( $config->{sleep_time} * 60 );

my $today        = strftime( '%Y/%m/%d/', localtime );
my $archive_path = $GallowayNow::MockConfig::config->{archive_path} . '/' . $today . '/log.txt';
my $strp         = DateTime::Format::Strptime->new( pattern => '%Y/%m/%d/ %T' );
my $threshold    = DateTime->now( time_zone => 'local', formatter => $strp )
    ->set_time_zone('floating')->subtract( minutes => $config->{sleep_time} );

my @kept_lines;
my $lines = `tail -n $config->{log_lines} $archive_path`;

for my $line ( split /\n/, $lines ) {
    if ( $line =~ /^(\d{2}):(\d{2}):(\d{2}) / ) {
        my $date = "$today $1:$2:$3";
        $line =~ s/\|\d+$//;
        push @kept_lines, $line
            if $strp->parse_datetime($date) > $threshold;
    }
}
my @fire_lines = grep /fire/i, @kept_lines;

exit 0 if @fire_lines < $config->{required_count};

my @fire_units
    = uniq map { /- (\d+)\ ?\(?([^)]*)?\)?$/ ? ( $2 ? $2 : $1 ) : () }
    @fire_lines;

exit 1 if @fire_units < $config->{required_units};

# shorten and join units for SMS
# Engine 26-35 becomes E26-35, Rescue 8 R8, Dispatch, D, etc
my $units = join ',',
    sort map { s/([A-Z])[A-Z]* ?(.*)?/$1$2/i; $_ } @fire_units;

my $message = @fire_lines . " fire lines from $units.";
say $message;

send_sms($message);

system '/usr/bin/touch', $config->{touch_file};

