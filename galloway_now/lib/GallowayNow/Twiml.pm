package GallowayNow::Twiml;

use Mojo::Base 'Mojolicious::Controller';
use File::Touch;
use Data::Dumper;
use Config::Auto;
use WWW::Twilio::TwiML;

sub get {
    my $self   = shift;
    my $params = $self->req->params->to_hash;
    $self->app->log->error( "TwiML Params: " . Dumper($params) );

    my $config
        = Config::Auto::parse("$FindBin::Bin/../../conf/fire_sms_alert.conf");

    my $tw = WWW::Twilio::TwiML->new;

    if (   $params->{AccountSid} eq $config->{account_sid}
        && $params->{From} eq $config->{alerts_to} )
    {   my $command = $params->{Body};
        if ( $command =~ m/^\s*sleep (\d+) ?(h|m)?\s*$/i ) {
            my $period = $1;
            my $units = $2 || 'm';
            $period *= 60 if $units eq 'h';
            my $touch_time = time + $period * 60 - $config->{sleep_time} * 60;

            my $ft = File::Touch->new( mtime => $touch_time );
            $ft->touch( $config->{touch_file} );
            $tw->Response->Sms(
                "sleeping for $period min w/ mtime " . localtime($touch_time) );
        }
        else {
            $tw->Response->Sms("Unrecognized command");
        }
    }
    else {
        $tw->Response();
    }
    $self->render( text => $tw->to_string, format => 'xml' );

}

1;
