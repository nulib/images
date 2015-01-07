# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/GPS.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..3\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::GPS;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'GPS';
my $testnum = 1;

# test 2: Extract information from GPS.jpg with specified coordinate format
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(CoordFormat => '%d degrees %.2f minutes');
    my $info = $exifTool->ImageInfo('t/images/GPS.jpg');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Write some new information
{
    ++$testnum;
    my @writeInfo = (
        ['GPSLatitude' => "12 deg 21' 23.345"],
        ['GPSLatitudeRef' => 'south' ],
        ['GPSTimeStamp' => '2007:03:02 15:21:10.55' ],
        ['GPSDateStamp' => '2007:03:02 15:21:10.55' ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum);
    print "ok $testnum\n";
}


# end
