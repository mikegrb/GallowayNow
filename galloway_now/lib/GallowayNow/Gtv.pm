package GallowayNow::Gtv;
use Mojo::Base 'Mojolicious::Controller';
use YAML::Tiny;

our $YAML = $GallowayNow::app_path . '/data/gtv/data.yml';
our $IMG  = '/assets/img/gtv/';

sub index {
    my $self = shift;
    my $data  = YAML::Tiny->read($YAML)->[0];
    $self->render( gtv_data => $data );
}

1;
