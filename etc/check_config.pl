#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use Text::CSV;
use JSON;


my $config_filename = shift;
my $metadata_filename = shift;
my $assets_dir = shift;

my $csv = Text::CSV->new({ blank_is_undef => 1, binary => 1, auto_diag => 1  });


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


open my $config_fh, '<', $config_filename or
  die "can't open $config_filename\n";
my $config_text = undef;
{
  $/ = undef;
  $config_text = <$config_fh>;
}
close $config_fh;

my $config = decode_json $config_text;

my $panels = $config->{front_page_panels};

map {
  my $panel = $_;

  if (defined $panel->{head_image}) {
    my @head_images = @{$panel->{head_image}};
    map {
      my $head_image = $_;
      if ($head_image !~ m|^/media/|) {
        if ($head_image =~ m|^/|) {
          die qq|"head_image" shouldn't start with "/": $head_image\n|;
        }
        if (! -f "$assets_dir/$head_image") {
          die qq|missing file for "head_image": $head_image\n|;
        }
      }
    } @head_images;
  } else {
    die 'missing "head_image" for: ', Dumper([$panel]);
  }

  my $date_added = $panel->{date_added};

  if (defined $date_added) {
    if ($date_added =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/) {
      if ($1 < 2015) {
        die qq|year too far in the past for "date_added": "$date_added"\n|;
      }
      if ($2 > 12) {
        die qq|month should be 1-12 for "date_added": "$date_added"\n|;
      }
      if ($3 > 31) {
        die qq|day of month should be 1-31 for "date_added": "$date_added"\n|;
      }
   } else {
      die "unknown date format: $date_added\n";
    }
  } else {
    die 'missing "date_added" for: ', Dumper([$panel]);
  }
} @$panels;


