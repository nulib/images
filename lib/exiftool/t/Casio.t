# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Casio.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..5\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::Casio;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'Casio';
my $testnum = 1;

# test 2: Extract information from Casio.jpg
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/Casio.jpg');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Extract information from Casio2.jpg
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/Casio2.jpg');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 4: Write some new information
{
    ++$testnum;
    my @writeInfo = (
        [MaxApertureValue => 4],
        [FocusMode => 'Macro'],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum);
    print "ok $testnum\n";
}

# test 5: Write some new information in type 2 file
{
    ++$testnum;
    my @writeInfo = (
        ['XResolution',300],
        ['YResolution',300],
        ['ObjectDistance','3.5'],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum, 't/images/Casio2.jpg');
    print "ok $testnum\n";
}


# end
