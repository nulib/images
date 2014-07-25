#!/usr/bin/perl


if ($#ARGV != 0) {
 print "usage: exif.pl image_path\n";
 exit;
}

my $image_path = $ARGV[0];
my $EXIF_TOOL = './exiftool/exiftool -a -g1 -u ';

my $raw_metadata = `$EXIF_TOOL $image_path`;
$raw_metadata =~ s/\&/&amp;/g;
$raw_metadata =~ s/>/&gt;/g;
$raw_metadata =~ s/</&lt;/g;
$raw_metadata =~s/([^\x00-\x7f])/sprintf("&#x%x;", ord($1))/ge;


print	"<exif>\n";

print	"  <raw>\n$raw_metadata\n  </raw>\n";
my @lines = split(/[\r\n]/, $raw_metadata);
foreach my $line (@lines) {
	my ($field, $value) = split(/:/, $line, 2);
	$field =~ s/\s+$//;
	$field =~ s/^\s+//;
	$field =~ s/[\s\/]+/_/g;
	$value =~ s/^\ //;
	$value =~ s/"/''/g;
	$value =~ s/\&/&amp;/g;
	$value =~ s/>/&gt;/g;
	$value =~ s/</&lt;/g;
	print	"  <item field=\"$field\" value=\"$value\" />\n";
  }

print	"</exif>";
