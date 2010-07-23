License

Creates a PlayStation 3 compatible M2TS from a MKV
Copyright (c) 2009 Flexion.Org, http://flexion.org/

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

Introduction

Creates a PlayStation 3 compatible M2TS from a MKV, assuming video is H.264 
and audio is AC3 or DTS with as little re-encoding as possible. Any subtitles in 
the MKV are preserved in the M2TS although the PS3 can't display subtitles in 
M2TS containers. Optionally splits the M2TS, if it is greater than 4GB, to 
maintain FAT32 compatibility. Unlike other MKV to M2TS solutions, this script
doesn't create any intermediate files during the conversion.

This script works on Ubuntu Linux, should work on any other Linux/Unix flavour 
and possibly Mac OS X providing you have the required tools installed.

Usage

  ./MKV-to-M2TS.sh movie.mkv [--split] [--help]

You can also pass the following optional parameter
  --split : If required, the .M2TS output will be split at a boundary less than 
            4GB for FAT32 compatibility
  --help  : This help.

Requirements

 - aften, bash, chmod, cat, cut, dcadec, echo, file, grep, mktemp, mkvextract, 
   mkvinfo, mkvmerge, rm, sed, stat, which, tsMuxeR.
   
Known Limitations

 - The PS3 can't play DTS audio streams in M2TS containers, therefore DTS audio
   is transcoded to AC3.
 - Audio and subtitle language names are not preserved, everything is 'und'

Source Code

You can grab the source from Launchpad. Contributions are welcome :-)

 - https://code.launchpad.net/~flexiondotorg

References

 - http://sticky123.blogspot.com/2008/03/remuxing-mkv-to-m2ts-on-linux.html
 - http://ubuntuforums.org/showthread.php?t=1029760
 - http://www.bitburners.com/articles/create-avchd-discs-with-subtitles-using-tsmuxer/4047/comment-page-1/
 - http://www.spikedsoftware.co.uk/blog/index.php/2009/04/04/bashing-mkvs-into-m2ts/
 - http://github.com/JakeWharton/mkvdts2ac3

v1.1 2009, 11th May.
 - Added a patch contributed by David Solbach that guesses the fps of the H.264
   video stream if the MKV field is not set. Thanks David :-)

v1.0 2009, 23rd April.
 - Initial release
