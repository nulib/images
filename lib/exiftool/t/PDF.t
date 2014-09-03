# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/PDF.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..21\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::PDF;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'PDF';
my $testnum = 1;

# test 2: Extract information from PDF.pdf
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/PDF.pdf');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Test Standard PDF decryption
{
    ++$testnum;
    my $skip = '';
    if (eval 'require Digest::MD5') {
        my $id = pack('H*','12116a1a124ae4cd8179e8978f6ac88b');
        my %cryptInfo = (
            Filter => '/Standard',
            P => -60,
            V => 1,
            R => 0,
            O => pack('H*','2055c756c72e1ad702608e8196acad447ad32d17cff583235f6dd15fed7dab67'),
            U => pack('H*','7150bd1da9d292af3627fca6a8dde1d696e25312041aed09059f9daee04353ae'),
        );
        my $exifTool = new Image::ExifTool;
        my $data = pack('N', 0x34a290d3);
        my $err = Image::ExifTool::PDF::DecryptInit($exifTool, \%cryptInfo, $id);
        $err and warn "\n  $err\n";
        Image::ExifTool::PDF::Crypt(\$data, '4 0 R');
        my $expected = 0x5924d335;
        my $got = unpack('N', $data);
        unless ($got == $expected) {
            warn "\n  Test $testnum (decryption) returned wrong value:\n";
            warn sprintf("    Expected 0x%x but got 0x%x\n", $expected, $got);
            print 'not ';
        }
    } else {
        $skip = ' # skip Requires Digest::MD5';
    }
    print "ok $testnum$skip\n";
}

# tests 4-21: Test writing, deleting and reverting two different files
{
    # do a bunch of edits
    my @edits = ([  # (on file containing both PDF Info and XMP)
        [   # test 4: write PDF and XMP information
            [ 'PDF:Creator' => 'me'],
            [ 'XMP:Creator' => 'you' ],
            [ 'AllDates'    => '2:30', Shift => -1 ],
        ],[ # test 5: delete all PDF
            [ 'PDF:all' ],
        ],[ # test 6: write some XMP
            [ 'XMP:Author' => 'them' ],
        ],[ # test 7: create new PDF
            [ 'PDF:Keywords'  => 'one' ],
            [ 'PDF:Keywords'  => 'two' ],
            [ 'AppleKeywords' => 'three' ],
            [ 'AppleKeywords' => 'four' ],
        ],[ # test 8: delete all XMP
            [ 'XMP:all' ],
        ],[ # test 9: write some PDF
            [ 'PDF:Keywords'  => 'another one', AddValue => 1 ],
            [ 'AppleKeywords' => 'three',       DelValue => 1 ],
        ],[ # test 10: create new XMP
            [ 'XMP:Author' => 'us' ],
        ],[ # test 11: write some PDF
            [ 'PDF:Keywords'  => 'two',  DelValue => 1 ],
            [ 'AppleKeywords' => 'five', AddValue => 1 ],
        ],[ # test 12: delete re-added XMP
            [ 'XMP:all' ],
        ],
    ],[             # (on file without PDF Info or XMP)
        [   # test 14: create new XMP
            [ 'XMP:Author' => 'him' ],
        ],[ # test 15: create new PDF
            [ 'PDF:Author' => 'her' ],
        ],[ # test 16: delete XMP and PDF
            [ 'XMP:all' ],
            [ 'PDF:all' ],
        ],[ # test 17: delete XMP and PDF again
            [ 'XMP:all' ],
            [ 'PDF:all' ],
        ],[ # test 18: create new PDF
            [ 'PDF:Author' => 'it' ],
        ],[ # test 19: create new XMP
            [ 'XMP:Author' => 'thing' ],
        ],[ # test 20: delete all
            [ 'all' ],
        ],
    ]);
    my $testSet;
    foreach $testSet (0,1) {
        my ($edit, $testfile2, $lastOK);
        my $testfile = 't/images/PDF' . ($testSet ? '2' : '') . '.pdf';
        my $testfile1 = $testfile;
        my $exifTool = new Image::ExifTool;
        $exifTool->Options(PrintConv => 0);
        foreach $edit (@{$edits[$testSet]}) {
            ++$testnum;
            $exifTool->SetNewValue();
            $exifTool->SetNewValue(@$_) foreach @$edit;
            $testfile2 = "t/${testname}_${testnum}_failed.pdf";
            unlink $testfile2;
            $exifTool->WriteInfo($testfile1, $testfile2);
            my $info = $exifTool->ImageInfo($testfile2,
                    qw{Filesize PDF:all XMP:Creator XMP:Author AllDates});
            my $ok = check($exifTool, $info, $testname, $testnum);
            print 'not ' unless $ok;
            print "ok $testnum\n";
            # erase source file if previous test was OK
            unlink $testfile1 if $lastOK;
            $lastOK = $ok;
            $testfile1 = $testfile2;    # use this file for the next test
        }
        # revert all edits and compare with original file
        ++$testnum;
        $exifTool->SetNewValue('PDF-update:all');
        $testfile2 = "t/${testname}_${testnum}_failed.pdf";
        unlink $testfile2;
        $exifTool->WriteInfo($testfile1, $testfile2);
        if (binaryCompare($testfile2, $testfile)) {
            unlink $testfile2;
        } else {
            print 'not ';
        }
        print "ok $testnum\n";
        unlink $testfile1 if $lastOK;
    }
}

# end
