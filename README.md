# lua-osg-livecoding binary package - Cygwin x64

This package is hosted on scene.org and at <https://github.com/cxw42/lol-bin>.

## Running

 1. Install Cygwin, x64.  Make sure to install at least the following
    packages.  Note that X11 is not required.
    - `lua`
    - `7-zip`
 1. Unzip this somewhere convenient, preserving directory structure (`7z x`).
 1. Fire up a shell and `cd` into the directory where you unzipped.
 1. `./runme.sh`.

To change the default size or position of the window, edit `runme.sh` and
change the `OSG_WINDOW` line.

## Running samples

The `samples` directory has a number of samples in it.  To run one:

    LOL_SHOW_WARNINGS=y LOL_RUN=samples/texture.lua ./runme.sh 

(or whatever filename, for `LOL_RUN`).

When you run a sample, the camera manipulator will be off by default.  To
turn it on so you can manually pan/zoom/rotate the view, say `camon`
at the livecoding command line.

## More information

 - General info is available at (or following links from)
  <https://demozoo.org/productions/176625/> and
  <https://www.pouet.net/prod.php?which=71351>.
 - Source is at <https://bitbucket.org/inclinescene/lua-osg-livecoding>.

### Legal

Copyright (c) 2017--2018 cxw/Incline.  CC-BY-SA 3.0.
