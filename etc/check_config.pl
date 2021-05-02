#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use Text::CSV;
use JSON;


my $csv = Text::CSV->new({ blank_is_undef => 1, binary => 1, auto_diag => 1  });

my $metadata_filename = 'website/jbrowse_track_metadata.csv';

open my $metadata_fh, '<', $metadata_filename
  or die "can't open metadata file $!";

my $expected_columns = 22;

while (my $row = $csv->getline($metadata_fh)) {
  if (@$row != $expected_columns) {
    die "config check failed: line $. of the JBrowse metadata table ($metadata_filename) has ", scalar(@$row),
      " columns instead of $expected_columns\n";
  }
}

close $metadata_fh;



my $config_filename = 'website/pombase_v2_config.json';

open my $config_fh, '<', $config_filename;

$/ = undef;

my $config_text = <$config_fh>;

my $config = decode_json $config_text;

my $panels = $config->{front_page_panels};

map {
  my @head_images = @{$_->{head_image}};

  map {
    my $image_filename = $_;

    if ($image_filename !~ m|^/| && !-f "pombase-website/src/assets/$image_filename") {
      die "can't find image from config file in the website repository: $image_filename\n";
    }
  } @head_images;
} @$panels;

close $config_fh;
