Summary: perl module for image data extraction 
Name: perl-Image-ExifTool
Version: 7.39
Release: 1
License: Artistic/GPL
Group: Development/Libraries/Perl
URL: http://owl.phy.queensu.ca/~phil/exiftool/
Source0: Image-ExifTool-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
ExifTool is a customizable set of Perl modules plus an application script
for reading and writing meta information in image, audio and video files,
including the maker note information of many digital cameras by various
manufacturers such as Canon, Casio, FujiFilm, HP, JVC/Victor, Kodak, Leaf,
Minolta/Konica-Minolta, Nikon, Olympus/Epson, Panasonic/Leica, Pentax/Asahi,
Ricoh, Sanyo, Sigma/Foveon and Sony.

Below is a list of file types and meta information formats currently
supported by ExifTool (r = read, w = write, c = create):

                File Types                 |    Meta Information
  ---------------------------------------  |  --------------------
  3FR   r       ITC   r       PPM   r/w    |  EXIF           r/w/c
  ACR   r       JNG   r/w     PPT   r      |  GPS            r/w/c
  AI    r       JP2   r/w     PS    r/w    |  IPTC           r/w/c
  AIFF  r       JPEG  r/w     PSD   r/w    |  XMP            r/w/c
  APE   r       K25   r       QTIF  r      |  MakerNotes     r/w/c
  ARW   r       KDC   r       RA    r      |  Photoshop IRB  r/w/c
  ASF   r       M4A   r       RAF   r/w    |  ICC Profile    r/w/c
  AVI   r       MEF   r/w     RAM   r      |  MIE            r/w/c
  BMP   r       MIE   r/w/c   RAW   r/w    |  JFIF           r/w/c
  BTF   r       MIFF  r       RIFF  r      |  Ducky APP12    r/w/c
  CR2   r/w     MNG   r/w     RM    r      |  CIFF           r/w
  CRW   r/w     MOS   r/w     SR2   r      |  AFCP           r/w
  CS1   r/w     MOV   r       SRF   r      |  JPEG 2000      r
  DCM   r       MP3   r       SVG   r      |  DICOM          r
  DCR   r       MP4   r       SWF   r      |  Flash          r
  DIVX  r       MPC   r       THM   r/w    |  FlashPix       r
  DNG   r/w     MPG   r       TIFF  r/w    |  QuickTime      r
  DOC   r       MRW   r/w     VRD   r/w/c  |  GeoTIFF        r
  EPS   r/w     NEF   r/w     WAV   r      |  PrintIM        r
  ERF   r/w     OGG   r       WDP   r/w    |  ID3            r
  FLAC  r       ORF   r/w     WMA   r      |  Kodak Meta     r
  FLV   r       PBM   r/w     WMV   r      |  Ricoh RMETA    r
  FPX   r       PDF   r/w     X3F   r      |  Picture Info   r
  GIF   r/w     PEF   r/w     XLS   r      |  Adobe APP14    r
  HDP   r/w     PGM   r/w     XMP   r/w/c  |  APE            r
  HTML  r       PICT  r                    |  Vorbis         r
  ICC   r/w/c   PNG   r/w                  |  (and more)

See html/index.html for more details about ExifTool features.

%prep
%setup -n Image-ExifTool-%{version}

%build
perl Makefile.PL INSTALLDIRS=vendor

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall DESTDIR=%{?buildroot:%{buildroot}}
find $RPM_BUILD_ROOT -name perllocal.pod | xargs rm

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes html
/usr/lib/perl5/*
%{_mandir}/*/*
%{_bindir}/*

%changelog
* Tue May 09 2006 - Niels Kristian Bech Jensen <nkbj@mail.tele.dk>
- Spec file fixed for Mandriva Linux 2006.
* Mon May 08 2006 - Volker Kuhlmann <VolkerKuhlmann@gmx.de>
- Spec file fixed for SUSE.
- Package available from: http://volker.dnsalias.net/soft/
* Sat Jun 19 2004 Kayvan Sylvan <kayvan@sylvan.com> - Image-ExifTool
- Initial build.
