#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Audio::Analyzer::ToneDetect;
use List::MoreUtils 'uniq';
use Term::ANSIColor;
use POSIX 'strftime';
use GallowayNow::MockConfig;

$| = 1;

my $tone_map_path = "$FindBin::Bin/../../conf/dispatch_tones.txt";

my %tone_map = ();

my $td = Audio::Analyzer::ToneDetect->new(
    source          => shift,
    valid_tones     => 'builtin',
    min_tone_length => 0.4,
    chunk_max       => 70,
    rejected_freqs  => [1000],
    valid_error_cb  => sub {
        out( sprintf "VF %s DF %s EF %.2f", @_ ),
        return;
    } );

reload_tone_map();

my $chunk_out = 0;
my @dispatch_stack;
while (1) {
    my $tones = get_two_tones();
    if ($tones) {
        push @dispatch_stack, $tones;
        reload_tone_map() unless exists $tone_map{$tones};
    }
    elsif (@dispatch_stack) {
        @dispatch_stack = map {"[$_]"}
            map { exists $tone_map{$_} ? $tone_map{$_} : $_ } @dispatch_stack;
        out( 'Dispatch Tones - ' . join( ', ', @dispatch_stack ) );

        # log only recognized to file
        @dispatch_stack = grep {m/[a-z]/i} @dispatch_stack;
        if (@dispatch_stack) {
            log_dispatch( get_timestamp()
                    . ' Dispatch Tones - '
                    . join( ', ', @dispatch_stack ) );
        }
        @dispatch_stack = ();
    }
    else {
        # print( $chunk_out ? '.' : 'Chunk pass ' );
        # $chunk_out = 1;
    }
}

sub out {
    # print "\n" if $chunk_out;
    say get_timestamp(), ' ', @_;
    # $chunk_out = 0;
}

sub get_two_tones {

    # my $tone_a = get_next_tone() || return;
    # my $tone_b = get_next_tone() || return;
    # return wantarray ? ( $tone_a, $tone_b ) : "$tone_a $tone_b";
    return $td->get_next_two_tones();
}

sub get_next_tone {
    my $val = $td->get_next_tone();
    return $val;
}

sub log_dispatch {
    my $line = shift;
    my $path = $GallowayNow::MockConfig::config->{archive_path} . strftime( '/%Y/%m/%d', localtime );

    my $mp3 = $path . strftime( '/%H00.mp3', localtime );
    my $location = ( ( -s $mp3 ) - 1024 ) if -s $mp3;
    $line .= ' |' . $location if $location > 0;

    open( my $fh, '>>', $path . '/log.txt' )
        or warn "Couldn't open log: $!";
    say $fh $line;
}

sub reload_tone_map {
    if ( exists( $tone_map{timestamp} ) ) {
        return
            unless ( stat($tone_map_path) )[9] > $tone_map{timestamp};
    }

    open( my $fh, '<', $tone_map_path ) or warn "Couldn't open tone map: $!";
    return unless $fh;

    %tone_map = ();

    while ( my $line = <$fh> ) {
        next if $line =~ /^\s*#/;
        next if $line =~ /^$/;
        chomp $line;

        $line =~ s/#.*$//;
        my ( $tones, $description ) = split /(?:\s{2,}|\t)/, $line, 2;
        $tone_map{$tones} = $description;
    }

    $tone_map{timestamp} = ( stat($fh) )[9];

    {
        # add additional tones in tonemap to valid tones list
        my @valid_tones   = @{ $td->{valid_tones} };
        my $initial_valid = @valid_tones;
        for my $key ( keys %tone_map ) {
            my ( $tone_a, $tone_b ) = split / /, $key;
            next if $tone_a eq 'timestamp';
            push @valid_tones, $tone_a, $tone_b;
        }
        @valid_tones = sort { $a <=> $b } ( uniq(@valid_tones) );
        $td->{valid_tones} = \@valid_tones;
        say "Added ", @valid_tones - $initial_valid, " additional tones.";
    }

    my $timestamp = strftime( '%Y-%m-%d %H:%M:%S', localtime );
    my $file_stamp
        = strftime( '%Y-%m-%d %H:%M:%S', localtime $tone_map{timestamp} );

    print colored ( "$timestamp Loaded tone map with ts $file_stamp\n",
        'yellow' );
    print color 'reset';
}

sub all_match { my $l = shift; $_ == $l->[0] || return 0 for @$l; return 1 }

sub get_timestamp {
    return strftime( '%H:%M:%S', localtime );
}
