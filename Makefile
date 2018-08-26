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

# Output directories
C=./cygwin
	# for running within Cygwin
Z=./standalone
	# for running on a system without Cygwin

# Cygwin-provided DLLs we use
CYGDLLS= \
	/usr/bin/cygbz2-1.dll \
	/usr/bin/cygcdt-5.dll \
	/usr/bin/cygcgraph-6.dll \
	/usr/bin/cygcrypto-1.0.0.dll \
	/usr/bin/cygexpat-1.dll \
	/usr/bin/cygFLAC-8.dll \
	/usr/bin/cygfreetype-6.dll \
	/usr/bin/cyggcc_s-seh-1.dll \
	/usr/bin/cyggsm-1.dll \
	/usr/bin/cyggvc-6.dll \
	/usr/bin/cygltdl-7.dll \
	/usr/bin/cyglua-5.2.dll \
	/usr/bin/cygogg-0.dll \
	/usr/bin/cygpathplan-4.dll \
	/usr/bin/cygpng16-16.dll \
	/usr/bin/cygportaudio-2.dll \
	/usr/bin/cygsndfile-1.dll \
	/usr/bin/cygstdc++-6.dll \
	/usr/bin/cygvorbis-0.dll \
	/usr/bin/cygvorbisenc-2.dll \
	/usr/bin/cygz.dll

.PHONY: build-cygwin build-standalone osg other zip all zip-norebuild

# Show the package size after updating.
all: build-cygwin build-standalone
	@du -cks --exclude='.git/*' ${C} | head -1
	@du -cks --exclude='.git/*' ${Z} | head -1

zip: all zip-norebuild

zip-norebuild:
	tar cvf - ${C} | lzip -9c > ${C}.tar.lzip
	tar cvf - ${Z} | lzip -9c > ${Z}.tar.lzip
	@ls -lh ${C}.tar.lzip ${Z}.tar.lzip

build-cygwin: osg other ${C}/livecoding.exe

# Copy and strip OSG DLLs into ${C}
osg:
	### OSG DLLs #####################################################
	@mkdir -p "${C}"
	find ${OSG}/bin -name '*.dll' -printf "%P\0" | \
		xargs -0 -n1 sh -c \
		'D="${C}/bin/$$0"; S="${OSG}/bin/$$0"; \
		mkdir -p "$$(dirname "$$D")"; \
		[ \! $$S -nt $$D ] && exit; echo "$$0"; \
		strip -o "$$D" "$$S"'

# Copy other files into ${C}
other:
	### Other files ##################################################
	@mkdir -p "${C}"
	cp -Rf ${LOL}/{assets,legal,lua,samples} ${C}
	cp -Rf lua-5.2 ${C}
	cp runme* default.view ${C}
	rm -f ${C}/.livecoding.history

#
${C}/livecoding.exe: ${LOLBUILD}/livecoding.exe
	### livecoding.exe ###############################################
	@mkdir -p "${C}"
	strip -o $@ $<

build-standalone: build-cygwin
	@mkdir -p "${Z}"
	@# Grab osg, other, livecoding from the cygwin tree
	cp -Rf ${C}/* ${Z}

	@# Grab the Cygwin dependenciees
	mkdir -p "${Z}/bin"
	cp "$$(which cygwin1.dll)" "${Z}/bin/zygwin1.dll"
	cp ${CYGDLLS} ${Z}/bin

	@# Call ourselves "zygwin" to avoid conflict with an existing
	@# cygwin installation
	find ${Z} \( -name \*.exe -o -name \*.dll -o -name \*.so \) -print0 | \
		xargs -0 -n1 sed -i 's/cygwin1\.dll/zygwin1.dll/g'

	rm -f ${Z}/.livecoding.history

