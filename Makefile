# lol-bin Makefile
# Copyright (c) 2018 cxw/Incline
#
# This updates lol-bin from ../lua-osg-livecoding/build-gcc and
# ../osg/build-gcc.  It is not the file you're looking for :) .
# It is used by cxw in preparing binary releases.

.PHONY: all osg other

OSG=../osg/build-gcc
LOL=../lua-osg-livecoding
LOLBUILD=${LOL}/build-gcc

# DLLs we use
DLLS=	/usr/bin/cygcdt-5.dll \
	/usr/bin/cygcgraph-6.dll \
	/usr/bin/cygcrypto-1.0.0.dll \
	/usr/bin/cygexpat-1.dll \
	/usr/bin/cyggcc_s-seh-1.dll \
	/usr/bin/cyggvc-6.dll \
	/usr/bin/cygltdl-7.dll \
	/usr/bin/cyglua-5.2.dll \
	/usr/bin/cygpathplan-4.dll \
	/usr/bin/cygstdc++-6.dll \
	/usr/bin/cygz.dll \
	/usr/bin/cygportaudio-2.dll \
	/usr/bin/cygsndfile-1.dll \
	/usr/bin/cygFLAC-8.dll \
	/usr/bin/cyggsm-1.dll \
	/usr/bin/cygogg-0.dll \
	/usr/bin/cygvorbis-0.dll \
	/usr/bin/cygvorbisenc-2.dll \

# Show the package size after updating.
all: zygwin
	du -cks --exclude='.git/*' .

# Call ourselves "zygwin" to avoid conflict with an existing cygwin installation
zygwin: osg other livecoding.exe
	cp `which cygwin1.dll` bin/zygwin1.dll
	# ldd dependencies
	cp ${DLLS} bin
	#
	find . \( -name \*.exe -o -name \*.dll -o -name \*.so \) -print0 | \
		xargs -0 -n1 sed -i 's/cygwin1\.dll/zygwin1.dll/g'

# Copy and strip OSG DLLs
osg:
	### OSG DLLs #####################################################
	find ${OSG}/bin -name '*.dll' -printf "%P\0" | \
		xargs -0 -n1 sh -c \
		'D="bin/$$0"; S="${OSG}/bin/$$0"; \
		[ \! $$S -nt $$D ] && exit; echo "$$0"; \
		strip -o "$$D" "$$S"'

# Copy other files
other:
	### Other files ##################################################
	cp -R ${LOL}/{assets,legal,lua,samples} .

#
livecoding.exe: ${LOLBUILD}/livecoding.exe
	### livecoding.exe ###############################################
	cp $< $@

