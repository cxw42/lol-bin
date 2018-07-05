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

# Show the package size after updating.
all: osg other livecoding.exe
	du -cks --exclude='.git/*' .

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

livecoding.exe: ${LOLBUILD}/livecoding.exe
	### livecoding.exe ###############################################
	cp $< $@

