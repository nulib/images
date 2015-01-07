# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Sony.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..4\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::Sony;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'Sony';
my $testnum = 1;

# test 2: Extract information from Sony.jpg
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/Sony.jpg',{'Unknown'=>1});
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Write some new information
{
    ++$testnum;
    my @writeInfo = (
        [FlashFired => 'true'],
        [ISO => undef],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum);
    print "ok $testnum\n";
}

# test 4: Test Sony decryption
{
    ++$testnum;
    my $data = pack('N', 0x34a290d3);
    Image::ExifTool::Sony::Decrypt(\$data, 0, 4, 0x12345678);
    my $expected = 0x20677968;
    my $got = unpack('N', $data);
    unless ($got == $expected) {
        warn "\n  Test $testnum (decryption) returned wrong value:\n";
        warn sprintf("    Expected 0x%x but got 0x%x\n", $expected, $got);
        print 'not ';
    }
    print "ok $testnum\n";
}

# end
