package GallowayNow::NoticeDetect::Type::StorageAuction;

use Moose;

with 'GallowayNow::NoticeDetect::Type';

has 'name' => { is => 'ro', default => "Storage Auction" };

has 'regex' => { is => 'ro', default => qr/Public Auction.*(?:storage|unit)/oi };

1;
