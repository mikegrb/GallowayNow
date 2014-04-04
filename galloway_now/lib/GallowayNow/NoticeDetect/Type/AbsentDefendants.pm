package GallowayNow::NoticeDetect::Type::AbsentDefendants;

use Moose;

with 'GallowayNow::NoticeDetect::Type';

has 'name' => { is => 'ro', default => "Notice to Absecon Defendants" };

has 'regex' => { is => 'ro', default => qr/^NOTICE TO ABSENT DEFENDANTS /o };

1;
