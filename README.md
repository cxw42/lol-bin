# lua-osg-livecoding binary package - Cygwin x64

This package is hosted on scene.org and at <https://github.com/cxw42/lol-bin>.

## Running the cygwin package

 1. Install Cygwin, x64.  Make sure to install at least the following
    packages: `lua`, `w32api`, `7-zip`, `libsndfile`, `portaudio`, `gdal`,
    `lzip`
    (Note that X11 is not required.)
 1. Download `cygwin.tar.lzip`.
 1. Fire up a cygwin shell and change to the directory where you downloaded
    `cygwin.tar.lzip`.
 1. Unzip, preserving directory structure:

        lzip -dc < cygwin.tar.lzip | tar xvf -

    This will create a `cygwin` directory.
 1. `cd cygwin`
 1. `./runme.sh` to launch `livecoding.exe` with the correct settings and
    paths.  Or, to start a shell in which everything is ready, `./runme.sh -i`,
    and then `./livecoding` from the resulting shell.

To change the default size or position of the window, edit `runme.sh` and
change the `OSG_WINDOW` line.

## Running samples

The `samples` directory has a number of samples in it.  To run one:

    ./runme.sh -r samples/texture.lua

(or whatever filename after `-r`).

When you run a sample, the camera manipulator will be off by default.  To
turn it on so you can manually pan/zoom/rotate the view, say `camon`
at the livecoding command line, or specify `-o` when you run `runme.sh`.

## More information

 - General info is available at (or following links from)
  <https://demozoo.org/productions/176625/> and
  <https://www.pouet.net/prod.php?which=71351>.
 - Source is at <https://bitbucket.org/inclinescene/lua-osg-livecoding>.

### Legal

Copyright (c) 2017--2018 cxw/Incline.  CC-BY-SA 3.0.  In any derivative work,
mention or link to <https://bitbucket.org/inclinescene/public> and
<http://devwrench.com>.  Some files have less restrictive copyrights, so
copyright statements within the individual files override this general
statement.

The song `assets/Kevin_MacLeod_-_The_Rule.ogg` is
"The Rule" by Kevin MacLeod (<https://incompetech.com>) and is
licensed under Creative Commons: By Attribution 3.0
<http://creativecommons.org/licenses/by/3.0/>.

The font file `assets/AnonymousPro.ttf` is the Anonymous Pro font,
Copyright (c) 2009, Mark Simonson (<http://www.ms-studio.com>,
mark@marksimonson.com).
This Font Software is licensed under the
[SIL Open Font License Version 1.1 (26 February 2007)](legal/OFL.txt).
This license is also available with a FAQ at: <http://scripts.sil.org/OFL>.
