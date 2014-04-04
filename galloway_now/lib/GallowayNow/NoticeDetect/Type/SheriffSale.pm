package GallowayNow::NoticeDetect::Type::SheriffSale;

use Moose;

with 'GallowayNow::NoticeDetect::Type';

has 'name' => { is => 'ro', default => "Sheriff's Sale" };

has 'regex' => { is => 'ro', default => qr/^SHERIFF'S SALE By virtue/o };

1;
