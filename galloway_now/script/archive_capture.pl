#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use IPC::Open3;
use Proc::Fork;
use Term::ANSIColor;
use Symbol 'gensym';
use POSIX 'strftime';
use GallowayNow::MockConfig;

my $m3u_url  = 'http://localhost:8000/stream.m3u';
my $uid_path = "$FindBin::Bin/../../conf/radio_uids.txt";
my %uids;
my $have_feed = 0;

# http://www.thregr.org/~wavexx/software/fIcy/

my $mp3_path;

while (1) {
    run_fork {
        child {
            my $path = $GallowayNow::MockConfig::config->{archive_path}
                . strftime( '/%Y/%m/%d/', localtime );
            my $filename = strftime( '%H00.mp3', localtime );
            system 'mkdir', '-p', $path;
            $mp3_path = $path . $filename;

            reload_uids();

            my $seconds_left = seconds_to_next_hour();
            my $err          = gensym;
            open3(
                undef, undef, $err,
                qq{
                /home/michael/bin/fPls -T 10 -L-1 -v -M $seconds_left $m3u_url -t | \
                /usr/bin/sox  -t mp3 - $mp3_path silence -l 1 0.3 1% -1 2.0 1 }
            );

            system( '/usr/bin/touch', $path . 'log.txt' )
                unless -e $path . 'log.txt';
            while ( my $line = <$err> ) {
                chomp $line;
                process_metadata( $path, $line );
            }

            exit 0;
        }
        parent {
            my $child_pid = shift;
            sleep seconds_to_next_hour();
            kill 9, $child_pid;
            waitpid $child_pid, 0;

            sleep 1;
        }
    };
}

sub reload_uids {
    if ( exists( $uids{timestamp} ) ) {
        return
            unless ( stat($uid_path) )[9] > $uids{timestamp};
    }

    open( my $fh, '<', $uid_path ) or warn "Couldn't open uids: $!";
    return unless $fh;

    %uids = ();

    while ( my $line = <$fh> ) {
        next if $line =~ /^\s*#/;
        next if $line =~ /^$/;

        chomp $line;
        my ( $uid, $description ) = split /\s+/, $line, 2;
        $uids{$uid} = $description;
    }

    $uids{timestamp} = ( stat($fh) )[9];

    my $timestamp = strftime( '%Y-%m-%d %H:%M:%S', localtime );
    my $file_stamp
        = strftime( '%Y-%m-%d %H:%M:%S', localtime $uids{timestamp} );

    print colored ( "$timestamp Loaded UID table with ts $file_stamp\n",
        'yellow' );
    print color 'reset';
}

sub process_metadata {
    my ( $path, $line ) = @_;
    my $timestamp = strftime( '%H:%M:%S', localtime );
    if ( $line !~ /^playing #\d+:\s+(.*)$/ ) {
        return if $line =~ m/404 File Not Found/;
        if ( $line =~ m|stream http://gallowaynow.com:8000/stream: retry| ) {
            lost_feed( $timestamp, $line );
        }
        else {
            print colored ( "$timestamp $line\n", 'yellow' );
        }
    }
    else {
        my $metadata = $1;
        if ( $metadata =~ /Feed Lost/ ) {
            lost_feed( $timestamp, $line );
            return;
        }

        if ( $have_feed == 0 && $metadata eq 'Scanning' ) {
            $have_feed = 1;
            print colored ( "$timestamp Feed restored\n", 'yellow', 'bold' );
            print color 'reset';
            return;
        }
        return if $metadata eq 'Scanning';

        if ( $metadata =~ m/- (\d+)$/ ) {
            my $uid = $1;
            reload_uids() unless exists $uids{$uid};
            $metadata .= " ($uids{$1})" if ( exists $uids{$uid} );
        }

        my $color = 'white';
        given ($metadata) {
            when (/fire/i)  { $color = 'red' }
            when (/EMS/i)   { $color = 'green' }
            when (/MEDCOM/) { $color = 'cyan' }
        }

        print colored ( "$timestamp $metadata\n", $color );

        $metadata .= ' |' . -s $mp3_path if ( $mp3_path && -s $mp3_path );

        open( my $fh, '>>', $path . "log.txt" )
            or warn "Couldn't open log: $!";
        say $fh "$timestamp $metadata";
        close($fh);
    }
    print color 'reset';
}

sub lost_feed {
    my ( $timestamp, $line ) = @_;
    print colored ( "$timestamp Lost Feed\n", 'yellow' ) if $have_feed;
    print color 'reset';

    # print "$line\n";
    $have_feed = 0;
}

sub seconds_to_next_hour {
    my ( $sec, $min ) = localtime;
    return ( 60 - $min ) * 60 - $sec;
}
