# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/ExifTool.t'

######################### We start with some black magic to print on failure.

# Change "1..N" below to so that N matches last test number

BEGIN { $| = 1; print "1..22\n"; $Image::ExifTool::noConfig = 1; }
END {print "not ok 1\n" unless $loaded;}

# test 1: Load ExifTool
use Image::ExifTool 'ImageInfo';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use t::TestLib;

my $testname = 'ExifTool';
my $testnum = 1;

# test 2: extract information from JPG file using name
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/ExifTool.jpg');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 3: TIFF file using file reference and ExifTool object with options
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 1, Unknown => 1);
    open(TESTFILE, 't/images/ExifTool.tif');
    my $info = $exifTool->ImageInfo(\*TESTFILE);
    close(TESTFILE);
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 4: test the Group option to extract EXIF info only
{
    ++$testnum;
    my $info = ImageInfo('t/images/Canon.jpg', {Group0 => 'EXIF'});
    print 'not ' unless check($info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 5: extract specified tags only
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
# don't test DateFormat because strftime output varies with locale
#    $exifTool->Options(DateFormat => '%H:%M:%S %a. %b. %e, %Y');
    my @tags = ('CreateDate', 'DateTimeOriginal', 'ModifyDate');
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg', \@tags);
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 6: test the 4 different ways to exclude tags...
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Exclude => 'ImageWidth');
    my @tagList = ( '-ImageHeight', '-Make' );
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg', '-FileSize',
                        \@tagList, {Group0 => '-MakerNotes'});
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# tests 7/8: test ExtractInfo(), GetInfo(), CombineInfo()
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 0);  # don't allow duplicates
    $exifTool->ExtractInfo('t/images/Canon.jpg');
    my $info1 = $exifTool->GetInfo({Group0 => 'MakerNotes'});
    my $info2 = $exifTool->GetInfo({Group0 => 'EXIF'});
    my $info = $exifTool->CombineInfo($info1, $info2);
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";

    # combine information in different order
    ++$testnum;
    $info = $exifTool->CombineInfo($info2, $info1);
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 9: test group options across different families
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg',
                    { Group1 => 'Canon', Group2 => '-Camera' });
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# tests 10/11: test ExtractInfo() and GetInfo()
# (uses output from test 5 for comparison)
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
# don't test DateFormat because strftime output is system dependent
#    $exifTool->Options(DateFormat => '%H:%M:%S %a. %b. %e, %Y');
    $exifTool->ExtractInfo('t/images/Canon.jpg');
    my @tags = ('createdate', 'datetimeoriginal', 'modifydate');
    my $info = $exifTool->GetInfo(\@tags);
    my $good = 1;
    my @expectedTags = ('CreateDate', 'DateTimeOriginal', 'ModifyDate');
    for (my $i=0; $i<scalar(@tags); ++$i) {
        $tags[$i] = $expectedTags[$i] or $good = 0;
    }
    print 'not ' unless $good;
    print "ok $testnum\n";

    ++$testnum;
    print 'not ' unless check($exifTool, $info, $testname, $testnum, 5);
    print "ok $testnum\n";
}

# tests 12/13: check precidence of tags extracted from groups
# (Note: these tests should produce the same output as 7/8,
#  so the .out files from tests 7/8 are used)
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 0);  # don't allow duplicates
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg',{Group0=>['MakerNotes','EXIF']});
    print 'not ' unless check($exifTool, $info, $testname, $testnum, 7);
    print "ok $testnum\n";

    # combine information in different order
    ++$testnum;
    $info = $exifTool->ImageInfo('t/images/Canon.jpg',{Group0=>['EXIF','MakerNotes']});
    print 'not ' unless check($exifTool, $info, $testname, $testnum, 8);
    print "ok $testnum\n";
}

# tests 14/15/16: test GetGroups()
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo('t/images/Canon.jpg');
    my @groups = $exifTool->GetGroups(2);
    my $not;
    foreach ('Camera','ExifTool','Image','Time') {
        $_ eq shift @groups or $not = 1;
    }
    @groups and $not = 1;
    print 'not ' if $not;
    print "ok $testnum\n";
    
    ++$testnum;
    my $info = $exifTool->GetInfo({Group0 => 'EXIF'});
    @groups = $exifTool->GetGroups($info,0);
    print 'not ' unless @groups==1 and $groups[0] eq 'EXIF';
    print "ok $testnum\n";

    ++$testnum;
    my $testfile = "t/ExifTool_$testnum";
    open(TESTFILE,">$testfile.failed");
    my $oldSep = $/;   
    $/ = "\x0a";        # set input line separator
    $exifTool->ExtractInfo('t/images/Canon.jpg');
    my $family = 1;
    @groups = $exifTool->GetGroups($family);
    my $group;
    foreach $group (@groups) {
        next if $group eq 'ExifTool';
        print TESTFILE "---- $group ----\n";
        my $info = $exifTool->GetInfo({"Group$family" => $group});
        foreach (sort $exifTool->GetTagList($info)) {
            print TESTFILE "$_ : $$info{$_}\n";
        } 
    }
    $/ = $oldSep;       # restore input line separator
    close(TESTFILE);
    print 'not ' unless testCompare("$testfile.out","$testfile.failed",$testnum);
    print "ok $testnum\n";
}

# test 17: Test verbose output
{
    ++$testnum;
    print 'not ' unless testVerbose($testname, $testnum, 't/images/Canon.jpg', 3);
    print "ok $testnum\n";
}

# tests 18/19: Test Group# option with multiple groups and no duplicates
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 0);  # don't allow duplicates
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg',
                    { Group0 => ['MakerNotes','EXIF'] });
    print 'not ' unless check($exifTool, $info, $testname, $testnum, 7);
    print "ok $testnum\n";

    ++$testnum;
    $info = $exifTool->ImageInfo('t/images/Canon.jpg',
                    { Group0 => ['EXIF','MakerNotes'] });
    print 'not ' unless check($exifTool, $info, $testname, $testnum, 8);
    print "ok $testnum\n";
}

# test 20: Test extracting a single, non-priority tag with duplicates set to 0
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Duplicates => 0);
    my $info = $exifTool->ImageInfo('t/images/Canon.jpg', 'EXIF:WhiteBalance');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 21: Test extracting ICC_Profile as a block
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo('t/images/ExifTool.tif', 'ICC_Profile');
    print 'not ' unless check($exifTool, $info, $testname, $testnum);
    print "ok $testnum\n";
}

# test 22: Test InsertTagValues
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my @foundTags;
    $exifTool->ImageInfo('t/images/ExifTool.jpg', \@foundTags);
    my $str = $exifTool->InsertTagValues(\@foundTags, '$ifd0:model - $1ciff:model');
    my $testfile = "t/ExifTool_$testnum";
    open(TESTFILE,">$testfile.failed");
    my $oldSep = $/;   
    $/ = "\x0a";        # set input line separator
    print TESTFILE $str, "\n";
    $/ = $oldSep;       # restore input line separator
    close(TESTFILE);
    print 'not ' unless testCompare("$testfile.out","$testfile.failed",$testnum);
    print "ok $testnum\n";
}

# end
