# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/IPTC-XMP.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..28\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::IPTC;
use Image::ExifTool::XMP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'IPTC-XMP';
my $testnum = 1;

# test 2: Extract information from IPTC-XMP.jpg
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/IPTC-XMP.jpg', {Duplicates => 1});
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: Test GetValue() in list context
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo('t/images/IPTC-XMP.jpg', {JoinLists => 0});
    my @values = $exifTool->GetValue('Keywords','ValueConv');
    my $values = join '-', @values;
    my $expected = 'ExifTool-Test-XMP';
    unless ($values eq $expected) {
        warn "\n  Test $testnum differs with \"$values\"\n";
        print 'not ';
    }
    print "ok $testnum\n";
}

# test 4: Test rewriting everything with slightly different values
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 1, Binary => 1, List => 1);
    my $info = $exifTool->ImageInfo('t/images/IPTC-XMP.jpg');
    my $tag;
    foreach $tag (keys %$info) {
        my $group = $exifTool->GetGroup($tag);
        my $val = $$info{$tag};
        if (ref $val eq 'ARRAY') {
            push @$val, 'v2';
        } elsif (ref $val eq 'SCALAR') {
            $val = 'v2';
        } elsif ($val =~ /^\d+(\.\d*)?$/) {
            # (add extra .001 to avoid problem with aperture of 4.85
            #  getting rounded to 4.8 or 4.9 and causing failed tests)
            $val += ($val / 10) + 1.001;
            $1 or $val = int($val);
        } else {
            $val .= '-v2';
        }
        # eat return values so warning don't get printed
        my @x = $exifTool->SetNewValue($tag, $val, Group=>$group, Replace=>1);
    }
    # also try writing a few specific tags
    $exifTool->SetNewValue(CreatorContactInfoCiAdrCtry => 'Canada');
    $exifTool->SetNewValue(CodedCharacterSet => 'UTF8');
    undef $info;
    my $image;
    $exifTool->WriteInfo('t/images/IPTC-XMP.jpg',\$image);
    # this is effectively what the RHEL 3 UTF8 LANG problem does:
    # $image = pack("U*", unpack("C*", $image));
    
    my $exifTool2 = new Image::ExifTool;
    $exifTool2->Options(Duplicates => 1);
    $info = $exifTool2->ImageInfo(\$image);
    my $testfile = "t/${testname}_${testnum}_failed.jpg";
    if (check($exifTool2, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        # save bad file
        open(TESTFILE,">$testfile");
        binmode(TESTFILE);
        print TESTFILE $image;
        close(TESTFILE);
        print 'not ';
    }
    print "ok $testnum\n";
}

# tests 5/6: Test extracting then reading XMP data as a block
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/IPTC-XMP.jpg','XMP');
    print 'not ' unless $$info{XMP};
    print "ok $testnum\n";

    ++$testnum;
    my $pass;
    if ($$info{XMP}) {
        $info = $exifTool->ImageInfo($$info{XMP});
        $pass = check($exifTool, $info, $testname, $testnum);
    }
    print 'not ' unless $pass;
    print "ok $testnum\n";
}

# test 7: Test copying information to a new XMP data file
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->SetNewValuesFromFile('t/images/IPTC-XMP.jpg');
    my $testfile = "t/${testname}_${testnum}_failed.xmp";
    unlink $testfile;
    $exifTool->WriteInfo(undef,$testfile);
    my $info = $exifTool->ImageInfo($testfile);
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}

# test 8: Test rewriting CS2 XMP information
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $testfile = "t/${testname}_${testnum}_failed.xmp";
    unlink $testfile;
    $exifTool->SetNewValue(Label => 'Blue');
    $exifTool->SetNewValue(Rating => 3);
    $exifTool->SetNewValue(Subject => q{char test: & > < ' "}, AddValue => 1);
    $exifTool->SetNewValue('Rights' => "\xc2\xa9 Copyright Someone Else");
    $exifTool->Options(Compact => 1);
    $exifTool->WriteInfo('t/images/XMP.xmp',$testfile);
    print 'not ' unless testCompare("t/IPTC-XMP_$testnum.out",$testfile,$testnum);
    print "ok $testnum\n";
}

# test 9-12: Test reading/writing XMP with blank nodes
{
    my $file;
    foreach $file ('XMP2.xmp', 'XMP3.xmp') {
        ++$testnum;
        my $exifTool = new Image::ExifTool;
        my $info = $exifTool->ImageInfo("t/images/$file", {Duplicates => 1});
        print 'not ' unless check($exifTool, $info, $testname, $testnum);
        print "ok $testnum\n";
    
        ++$testnum;
        my $testfile = "t/${testname}_${testnum}_failed.xmp";
        unlink $testfile;
        $exifTool->SetNewValue('XMP:Author' => 'Phil');
        $exifTool->WriteInfo("t/images/$file", $testfile);
        print 'not ' unless testCompare("t/IPTC-XMP_$testnum.out",$testfile,$testnum);
        print "ok $testnum\n";
    }
}

# tests 13-18: Test writing/deleting XMP alternate languages
{
    my @writeList = (
        [ ['Rights-x-default' => "\xc2\xa9 Copyright Another One"] ], # should overwrite x-default only
        [ ['Rights-de-DE' => "\xc2\xa9 Urheberrecht Phil Harvey"] ],  # should create de-DE only
        [ ['Rights-x-default' => undef] ],  # should delete all languages
        [ ['Rights-fr' => undef] ],         # should delete fr only
        [ ['Title-fr' => 'Test fr title'] ],# should also create x-default
        [ ['Title-fr' => 'Test fr title'],
          ['Title-x-default' => 'dTitle'] ],# should create x-default before fr
    );
    my $writeListRef;
    foreach $writeListRef (@writeList) {
        ++$testnum;
        my $exifTool = new Image::ExifTool;
        my $testfile = "t/${testname}_${testnum}_failed.xmp";
        unlink $testfile;
        print 'not ' unless writeCheck($writeListRef, $testname, $testnum,
                                       't/images/XMP.xmp', ['XMP-dc:*']);
        print "ok $testnum\n";
    }
}

# test 19: Delete some family 1 XMP groups
{
    ++$testnum;
    my @writeInfo = (
        [ 'xmp-xmpmm:all' => undef ],
        [ 'XMP-PHOTOSHOP:all' => undef ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum,
                                   't/images/IPTC-XMP.jpg', ['XMP:all']);
    print "ok $testnum\n";
}

# test 20-21: Copy from XMP to EXIF with and without PrintConv enabled
{
    my $exifTool = new Image::ExifTool;
    while ($testnum < 21) {
        ++$testnum;
        my $testfile = "t/${testname}_${testnum}_failed.jpg";
        unlink $testfile;
        $exifTool->SetNewValue();
        $exifTool->SetNewValuesFromFile('t/images/XMP.xmp', 'XMP:all>EXIF:all');
        $exifTool->WriteInfo("t/images/Writer.jpg", $testfile);
        my $info = $exifTool->ImageInfo($testfile, 'EXIF:all');
        if (check($exifTool, $info, $testname, $testnum)) {
            unlink $testfile;
        } else {
            print 'not ';
        }
        print "ok $testnum\n";
        $exifTool->Options(PrintConv => 0);
    }
}

# test 22-23: Copy from EXIF to XMP with and without PrintConv enabled
{
    my $exifTool = new Image::ExifTool;
    while ($testnum < 23) {
        ++$testnum;
        my $testfile = "t/${testname}_${testnum}_failed.xmp";
        unlink $testfile;
        $exifTool->SetNewValue();
        $exifTool->SetNewValuesFromFile('t/images/Canon.jpg', 'EXIF:* > XMP:*');
        $exifTool->WriteInfo(undef, $testfile);
        my $info = $exifTool->ImageInfo($testfile, 'XMP:*');
        if (check($exifTool, $info, $testname, $testnum)) {
            unlink $testfile;
        } else {
            print 'not ';
        }
        print "ok $testnum\n";
        $exifTool->Options(PrintConv => 0);
    }
}

# test 24: Delete all tags except two specific XMP family 1 groups
{
    ++$testnum;
    my @writeInfo = (
        [ 'all' => undef ],
        [ 'xmp-dc:all'  => undef, Replace => 2 ],
        [ 'xmp-xmprights:all' => undef, Replace => 2 ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum,
                                   't/images/IPTC-XMP.jpg', ['XMP:all']);
    print "ok $testnum\n";
}

# test 25: Delete all tags except XMP
{
    ++$testnum;
    my @writeInfo = (
        [ 'all' => undef ],
        [ 'xmp:all' => undef, Replace => 2 ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum,
                                   't/images/IPTC-XMP.jpg', ['-file:all']);
    print "ok $testnum\n";
}

# test 26: Test IPTC special characters
{
    ++$testnum;
    my @writeInfo = (
        ['IPTC:CopyrightNotice' => "\xc2\xa9 2008 Phil Harvey"],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum,
                                   't/images/Writer.jpg', 1);
    print "ok $testnum\n";
}

# test 27: Extract information from SVG image
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/XMP.svg', {Duplicates => 1});
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 28: Test creating new XMP-plus information
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $testfile = "t/${testname}_${testnum}_failed.xmp";
    unlink $testfile;
    $exifTool->SetNewValue('XMP:ImageType' => 'Video');
    $exifTool->SetNewValue('LicenseeImageNotes-en' => 'english notes');
    $exifTool->SetNewValue('LicenseeImageNotes-de' => 'deutsche anmerkungen');
    $exifTool->SetNewValue('LicenseeImageNotes' => 'default notes');
    $exifTool->SetNewValue('LicenseeName' => 'Phil');
    $exifTool->SetNewValue('CopyrightStatus' => 'public');
    $exifTool->SetNewValue('Custom1-en' => 'a');
    $exifTool->SetNewValue('Custom1-en' => 'b');
    $exifTool->WriteInfo(undef,$testfile);
    print 'not ' unless testCompare("t/IPTC-XMP_$testnum.out",$testfile,$testnum);
    print "ok $testnum\n";
}


# end
