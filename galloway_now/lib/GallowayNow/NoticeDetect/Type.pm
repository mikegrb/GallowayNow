package GallowayNow::NoticeDetect::Type;
use Moose::Role;

requires 'name';
requires 'regex';

sub match {
    my ($self, $notice) = @_;

    my $regex = $self->regex;
    return $notice->{body} =~ m/$regex/;
}

1;
