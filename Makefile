include Makefile.config

DESTDIR=
libdir=/usr/lib
bindir=/usr/bin
sbindir=/usr/sbin
desktopdir=/usr/share/applications
autostartdir=/usr/share/autostart
xinitdir=/etc/X11/xinit.d
iconsdir=/usr/lib/libDrakX/icons
pixmapsdir=/usr/share/libDrakX/pixmaps

BIN_TOOLS= 
SBIN_TOOLS= keyboarddrake mousedrake XFdrake
INLIBDEST_DIRS = lib/xf86misc

all: $(INLIBDEST_DIRS)
	install -d auto
	(find lib -name '*.pm'; find tools -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	for i in po $(INLIBDEST_DIRS); do 	make -C $$i; done

check:
	@for p in `find lib -name *.pm`; do perl -cw -I$(libdir)/libDrakX $$p || exit 1; done
	@for p in tools/*; do perl -cw $$p || exit 1; done

install:
	install -d $(DESTDIR){$(libdir),$(bindir),$(sbindir),$(desktopdir),$(autostartdir),$(xinitdir),$(iconsdir),$(pixmapsdir)}

	install -d $(INLIBDEST_DIRS:%=$(DESTDIR)$(libdir)/libDrakX//%)
	cp -a lib/*.pm $(DESTDIR)$(libdir)/libDrakX/
	find auto -follow -name .exists -o -name "*.bs" | xargs rm -f
	cp -rfL auto $(DESTDIR)$(libdir)/libDrakX

	(cd lib; for i in */; do install -d $(DESTDIR)$(libdir)/libDrakX/$$i ; install -m 644 $$i/*.pm $(DESTDIR)$(libdir)/libDrakX/$$i/;done)
	(cd tools; \
	  [[ -n "$(BIN_TOOLS)" ]] && install -m755 $(BIN_TOOLS) $(DESTDIR)$(bindir); \
	  install -m755 $(SBIN_TOOLS) $(DESTDIR)$(sbindir); \
	)
	#install -m644 $(wildcard data/*.desktop) $(DESTDIR)$(desktopdir)
	#install -m644 $(wildcard data/icons/*.png) $(DESTDIR)$(iconsdir)
	install -m644 $(wildcard data/pixmaps/*.png) $(DESTDIR)$(pixmapsdir)
	make -C po install

clean:
	make -C po clean

dis:
	rm -rf $(NAME)-$(VERSION) ../$(NAME)-$(VERSION).tar*
	svn export -q . $(NAME)-$(VERSION)
	find $(NAME)-$(VERSION) -name .cvsignore |xargs rm -rf
	tar cf ../$(NAME)-$(VERSION).tar $(NAME)-$(VERSION)
	bzip2 -9f ../$(NAME)-$(VERSION).tar
	rm -rf $(NAME)-$(VERSION)

.PHONY: ChangeLog

ChangeLog: ../common/username.xml
	svn2cl --accum --strip-prefix=soft/drakx-kbd-mouse-x11/trunk --authors ../../soft/common/username.xml
	rm -f ChangeLog.bak
	svn commit -m "Generated by cvs2cl the `LC_TIME=C date '+%d_%b'`" ChangeLog
