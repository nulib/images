# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/PostScript.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..3\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::PostScript;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'PostScript';
my $testnum = 1;

# test 2: Extract information from PostScript.eps
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/PostScript.eps');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Write EPS information
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->SetNewValuesFromFile('t/images/IPTC-XMP.jpg','*:*');
    $exifTool->SetNewValue(Title => 'new title');
    $exifTool->SetNewValue(Copyright => 'my copyright');
    $exifTool->SetNewValue(Creator => 'phil made it', Replace => 1);
    $testfile = "t/${testname}_${testnum}_failed.eps";
    unlink $testfile;
    $exifTool->WriteInfo('t/images/PostScript.eps', $testfile);
    my $info = $exifTool->ImageInfo($testfile);
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}


# end
