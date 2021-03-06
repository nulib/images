# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/AFCP.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN {$Image::ExifTool::noConfig = 1; $| = 1; print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::FotoStation;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'FotoStation';
my $testnum = 1;

# test 2: Extract information from FotoStation.jpg
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/FotoStation.jpg', {Duplicates => 1});
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Test writing some information
{
    ++$testnum;
    my @writeInfo = (
        ['Rotation' => 0 ],
        ['Keywords' => 'FotoStation' ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum, undef, 1);
    print "ok $testnum\n";
}

# end
