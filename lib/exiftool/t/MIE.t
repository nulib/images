# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/MIE.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..4\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::MIE;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'MIE';
my $testnum = 1;

# test 2: Extract information from MIE.mie
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/MIE.mie', '-filename', '-directory');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Write MIE information
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(IgnoreMinorErrors => 1); # to copy invalid thumbnail
    $exifTool->SetNewValuesFromFile('t/images/Nikon.jpg','*:*');
    $exifTool->SetNewValue('EXIF:XResolution' => 200);
    $exifTool->SetNewValue('MIE:FNumber' => 11);
    $exifTool->SetNewValue('XMP:Creator' => 'phil');
    $exifTool->SetNewValue('IPTC:Keywords' => 'cool');
    $testfile = "t/${testname}_${testnum}_failed.mie";
    unlink $testfile;
    $exifTool->WriteInfo('t/images/MIE.mie', $testfile);
    my $info = $exifTool->ImageInfo($testfile);
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}

# test 4: Create a MIE file from scratch
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(IgnoreMinorErrors => 1); # to copy invalid thumbnail
    $exifTool->SetNewValuesFromFile('t/images/MIE.mie');
    $testfile = "t/${testname}_${testnum}_failed.mie";
    unlink $testfile;
    $exifTool->WriteInfo(undef, $testfile);
    my $info = $exifTool->ImageInfo($testfile, '-filename', '-directory');
    if (check($exifTool, $info, $testname, $testnum, 2)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}

# end
