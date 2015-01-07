#------------------------------------------------------------------------------
# File:         TestLib.pm
#
# Description:  Utility routines for testing ExifTool modules
#
# Revisions:    Feb. 19/04 - P. Harvey Created
#               Feb. 26/04 - P. Harvey Name temporary file ".failed" and erase
#                            it if the test passes
#               Feb. 27/04 - P. Harvey Change print format and allow ExifTool
#                            object to be passed instead of tags hash ref.
#               Oct. 30/04 - P. Harvey Split testCompare() into separate sub.
#               May  18/05 - P. Harvey Tolerate round-off errors in floats.
#               Feb. 02/08 - P. Harvey Allow different timezones in time values
#------------------------------------------------------------------------------

package t::TestLib;

use strict;
require 5.002;
require Exporter;
use Image::ExifTool qw(ImageInfo);

use vars qw($VERSION @ISA @EXPORT);
$VERSION = '1.09';
@ISA = qw(Exporter);
@EXPORT = qw(check writeCheck testCompare binaryCompare testVerbose);

sub closeEnough($$);

#------------------------------------------------------------------------------
# compare 2 binary files
# Inputs: 0) file name 1, 1) file name 2
# Returns: 1 if files are identical
sub binaryCompare($$)
{
    my ($file1, $file2) = @_;
    my $success = 1;
    open(TESTFILE1, $file1) or return 0;
    unless (open(TESTFILE2, $file2)) {
        close(TESTFILE1);
        return 0;
    }
    binmode(TESTFILE1);
    binmode(TESTFILE2);
    my ($buf1, $buf2);
    while (read(TESTFILE1, $buf1, 65536)) {
        read(TESTFILE2, $buf2, 65536) or $success = 0, last;
        $buf1 eq $buf2 or $success = 0, last;
    }
    read(TESTFILE2, $buf2, 65536) and $success = 0;
    close(TESTFILE1);
    close(TESTFILE2);
    return $success
}

#------------------------------------------------------------------------------
# Compare 2 files and return true and erase the 2nd file if they are the same
# Inputs: 0) file1, 1) file2
# Returns: true if files are the same
sub testCompare($$$)
{
    my ($stdfile, $testfile, $testnum) = @_;
    my $success = 0;
    my $linenum;
    
    my $oldSep = $/;   
    $/ = "\x0a";        # set input line separator
    if (open(FILE1, $stdfile)) {
        if (open(FILE2, $testfile)) {
            $success = 1;
            my ($line1, $line2);
            my $linenum = 0;
            foreach (<FILE1>) {
                ++$linenum;
                $line1 = $_;
                $line2 = <FILE2>;
                if (defined $line2) {
                    next if $line1 eq $line2;
                    next if closeEnough($line1, $line2);
                }
                $success = 0;
                last;
            }
            if ($success) {
                # make sure there is nothing left in file2
                $line2 = <FILE2>;
                if ($line2) {
                    ++$linenum;
                    $success = 0;
                }
            }
            unless ($success) {
                warn "\n  Test $testnum differs beginning at line $linenum:\n";
                defined $line1 or $line1 = '(null)';
                defined $line2 or $line2 = '(null)';
                chomp $line1;
                chomp $line2;
                warn qq{    Test gave: "$line2"\n};
                warn qq{    Should be: "$line1"\n};
            }
            close(FILE2);
        }
        close(FILE1);
    }
    $/ = $oldSep;       # restore input line separator
    
    # erase .failed file if test was successful
    $success and unlink $testfile;
    
    return $success
}

#------------------------------------------------------------------------------
# Return true if two test lines are close enough
# Inputs: 1) line 1, 2) line 2
# Returns: true if lines are similar enough to pass test
sub closeEnough($$)
{
    my ($line1, $line2) = @_;

    # of course, the version number will change...
    return 1 if $line1 =~ /^(.*ExifTool.*)\b\d{1,2}\.\d{2}\b(.*)/s and
               ($line2 eq "$1$Image::ExifTool::VERSION$Image::ExifTool::RELEASE$2" or
                $line2 eq "$1$Image::ExifTool::VERSION$2");

    # allow different FileModifyDate's
    return 1 if $line1 =~ /File\s?Modif.*Date/ and
                $line2 =~ /File\s?Modif.*Date/;

    # analyze every token in the line, and allow rounding
    # or format differences in floating point numbers
    my @toks1 = split /\s+/, $line1;
    my @toks2 = split /\s+/, $line2;
    my $lenChanged = 0;
    for (;;) {
        return 1 unless @toks1 or @toks2;   # all tokens were OK
        last unless @toks1 and @toks2;
        my $tok1 = shift @toks1;
        my $tok2 = shift @toks2;
        next if $tok1 eq $tok2;
        # can't compare any more if either line was truncated (ie. ends with '[...]')
        return $lenChanged if $tok1 =~ /\Q[...]\E$/ or $tok2 =~ /\Q[...]\E$/;
        # allow times with different timezones
        if ($tok1 =~ /^(\d{2}:\d{2}:\d{2})(Z|[-+]\d{2}:\d{2})$/) {
            my $date = $1;  # remove timezone
            next if $tok2 =~ /^(\d{2}:\d{2}:\d{2})(Z|[-+]\d{2}:\d{2})$/ and $date eq $1;
        }
        # check to see if both tokens are floating point numbers (with decimal points!)
        $tok1 =~ s/[^\d.]+$//; $tok2 =~ s/[^\d.]+$//;   # remove trailing units
        last unless Image::ExifTool::IsFloat($tok1) and
                    Image::ExifTool::IsFloat($tok2) and
                    $tok1 =~ /\./ and $tok2 =~ /\./;
        last if $tok1 == 0 or $tok2 == 0;
        # numbers are bad if not the same to 5 significant figures
        if (abs(($tok1-$tok2)/($tok1+$tok2)) > 1e-5) {
            # (but allow last digit to be different due to round-off errors)
            my ($int1, $int2);
            ($int1 = $tok1) =~ tr/0-9//dc;
            ($int2 = $tok2) =~ tr/0-9//dc;
            if (length($int1) != length($int2)) {
                if (length($int1) > length($int2)) {
                    $int1 = substr($int1, 0, length($int2));
                } else {
                    $int2 = substr($int2, 0, length($int1));
                }
            }
            last if abs($int1-$int2) > 1.00001;
        }
        # set flag if length changed
        $lenChanged = 1 if length($tok1) ne length($tok2);
    }
    return 0;
}

#------------------------------------------------------------------------------
# Compare extracted information against a standard output file
# Inputs: 0) [optional] ExifTool object reference
#         1) tag hash reference, 2) test name, 3) test number
#         4) test number for comparison file (if different than this test)
# Returns: 1 if check passed
sub check($$$;$$)
{
    my $exifTool = shift if ref $_[0] ne 'HASH';
    my ($info, $testname, $testnum, $stdnum) = @_;
    return 0 unless $info;
    $stdnum = $testnum unless defined $stdnum;
    my $testfile = "t/${testname}_$testnum.failed";
    my $stdfile = "t/${testname}_$stdnum.out";
    open(FILE, ">$testfile") or return 0;
    
    # use one type of linefeed so this test works across platforms
    my $oldSep = $\;
    $\ = "\x0a";        # set output line separator
    
    # get a list of found tags
    my @tags;
    if ($exifTool) {
        # sort tags by group to make it a bit prettier
        @tags = $exifTool->GetTagList($info, 'Group0');
    } else {
        @tags = sort keys %$info;
    }
#
# Write information to file (with filename "TESTNAME_#.failed")
#
    foreach (@tags) {
        my $val = $$info{$_};
        if (ref $val eq 'SCALAR') {
            if ($$val =~ /^Binary data/) {
                $val = "($$val)";
            } else {
                $val = '(Binary data ' . length($$val) . ' bytes)';
            }
        } elsif (ref $val eq 'ARRAY') {
            $val = join(', ', @$val);
        } else {
            # make sure there are no linefeeds in output
            $val =~ tr/\x0a\x0d/;/;
            # translate unknown characters
           # $val =~ tr/\x01-\x1f\x80-\xff/\./;
            $val =~ tr/\x01-\x1f\x7f/./;
            # remove NULL chars
            $val =~ s/\x00//g;
        }
        # (no "\n" needed since we set the output line separator above)
        if ($exifTool) {
            my $groups = join ', ', $exifTool->GetGroup($_);
            my $tagID = $exifTool->GetTagID($_);
            my $desc = $exifTool->GetDescription($_);
            print FILE "[$groups] $tagID - $desc: $val";
        } else {
            print FILE "$_: $val";
        }
    }
    close(FILE);
    
    $\ = $oldSep;       # restore output line separator
#
# Compare the output file to the output from the standard test (TESTNAME_#.out)
#
    return testCompare($stdfile, $testfile, $testnum);
}

#------------------------------------------------------------------------------
# test writing feature by writing specified information to JPEG file
# Inputs: 0) list reference to lists of SetNewValue arguments
#         1) test name, 2) test number, 3) optional source file name,
#         4) true to only check tags which were written (or list ref for tags to check)
# Returns: 1 if check passed
sub writeCheck($$$;$$)
{
    my ($writeInfo, $testname, $testnum, $srcfile, $onlyWritten) = @_;
    $srcfile or $srcfile = "t/images/$testname.jpg";
    my ($ext) = ($srcfile =~ /\.(.+?)$/);
    my $testfile = "t/${testname}_${testnum}_failed.$ext";
    my $exifTool = new Image::ExifTool;
    my @tags;
    if (ref $onlyWritten eq 'ARRAY') {
        @tags = @$onlyWritten;
        undef $onlyWritten;
    }
    foreach (@$writeInfo) {
        $exifTool->SetNewValue(@$_);
        push @tags, $$_[0] if $onlyWritten;
    }
    unlink $testfile;
    $exifTool->WriteInfo($srcfile, $testfile);
    my $info = $exifTool->GetInfo('Error');
    foreach (keys %$info) { warn "$$info{$_}\n"; }
    $info = $exifTool->ImageInfo($testfile,{Duplicates=>1,Unknown=>1},@tags);
    my $rtnVal = check($exifTool, $info, $testname, $testnum);
    $rtnVal and unlink $testfile;
    return $rtnVal;
}

#------------------------------------------------------------------------------
# test verbose output
# Inputs: 0) test name, 1) test number, 2) Input file, 3) verbose level
# Returns: true if test passed
sub testVerbose($$$$)
{
    my ($testname, $testnum, $infile, $verbose) = @_;
    my $testfile = "t/${testname}_$testnum";
    # capture verbose output by redirecting STDOUT
    return 0 unless open(TMPFILE,">$testfile.tmp");
    ImageInfo($infile, { Verbose => $verbose, TextOut => \*TMPFILE });
    close(TMPFILE);
    # re-write output file to change newlines to be same as standard test file
    # (if I was a Perl guru, maybe I would know a better way to do this)
    open(TMPFILE,"$testfile.tmp");
    open(TESTFILE,">$testfile.failed");
    my $oldSep = $\;
    $\ = "\x0a";        # set output line separator
    while (<TMPFILE>) {
        chomp;          # remove existing newline
        print TESTFILE $_;  # re-write line using \x0a for newlines
    }
    $\ = $oldSep;       # restore output line separator
    close(TESTFILE);
    unlink("$testfile.tmp");
    return testCompare("$testfile.out","$testfile.failed",$testnum);
}


1; #end
