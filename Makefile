include Makefile.config

DESTDIR=
libdir=/usr/lib
bindir=/usr/bin
sbindir=/usr/sbin
rootsbindir=/sbin
libexecdir=/usr/libexec
desktopdir=/usr/share/applications
autostartdir=/usr/share/autostart
xinitdir=/etc/X11/xinit.d
iconsdir=/usr/lib/libDrakX/icons
pixmapsdir=/usr/share/libDrakX/pixmaps

BIN_TOOLS= 
SBIN_TOOLS= drakx-update-background
ROOTSBIN_TOOLS = display_driver_helper
INLIBDEST_DIRS = lib/xf86misc

all: $(INLIBDEST_DIRS)
	install -d auto
	(find lib -name '*.pm'; find tools -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	for i in po $(INLIBDEST_DIRS); do 	make -C $$i; done
	make -C po
	make -C polkit

check:
	@for p in `find lib -name *.pm`; do perl -cw -I$(libdir)/libDrakX $$p || exit 1; done
	@for p in tools/*; do head -n1 $$p | grep perl || continue; perl -cw $$p || exit 1; done

install:
	install -d $(DESTDIR){$(libdir),$(bindir),$(sbindir),$(rootsbindir),$(desktopdir),$(autostartdir),$(xinitdir),$(iconsdir),$(pixmapsdir),$(libexecdir)}

	install -d $(INLIBDEST_DIRS:%=$(DESTDIR)$(libdir)/libDrakX//%)
	cp -a lib/*.pm $(DESTDIR)$(libdir)/libDrakX/
	find auto -follow -name .exists -o -name "*.bs" | xargs rm -f
	cp -rfL auto $(DESTDIR)$(libdir)/libDrakX

	(cd lib; for i in */; do install -d $(DESTDIR)$(libdir)/libDrakX/$$i ; install -m 644 $$i/*.pm $(DESTDIR)$(libdir)/libDrakX/$$i/;done)
	(cd tools; \
	  [[ -n "$(BIN_TOOLS)" ]] && install -m755 $(BIN_TOOLS) $(DESTDIR)$(bindir); \
	  [[ -n "$(ROOTSBIN_TOOLS)" ]] && install -m755 $(ROOTSBIN_TOOLS) $(DESTDIR)$(rootsbindir); \
	  install -m755 $(SBIN_TOOLS) $(DESTDIR)$(sbindir); \
	)
	install -m755 tools/keyboarddrake $(DESTDIR)$(libexecdir)/drakkeyboard
	install -m755 tools/mousedrake $(DESTDIR)$(libexecdir)/drakmouse
	install -m755 tools/XFdrake $(DESTDIR)$(libexecdir)/drakx11
	# Some compatibility name wrappers
	ln -sf drakkeyboard $(DESTDIR)$(bindir)/keyboarddrake
	ln -sf drakmouse $(DESTDIR)$(bindir)/mousedrake
	ln -sf drakx11 $(DESTDIR)$(bindir)/XFdrake
	ln -sf drakx11 $(DESTDIR)$(bindir)/Xdrakres
	#install -m644 $(wildcard data/*.desktop) $(DESTDIR)$(desktopdir)
	#install -m644 $(wildcard data/icons/*.png) $(DESTDIR)$(iconsdir)
	install -m644 $(wildcard data/pixmaps/*.png) $(DESTDIR)$(pixmapsdir)
	make -C po install
	make -C polkit install

clean:
	make -C po clean
	make -C polkit clean

dist:
	 git archive --prefix=$(NAME)-$(VERSION)/ HEAD | xz -v > $(NAME)-$(VERSION).tar.xz
	 git tag $(NAME)-$(VERSION)



.PHONY: ChangeLog

log: ChangeLog

changelog: ChangeLog

ChangeLog:
	@if test -d "$$PWD/.git"; then \
	  git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n" > $@.tmp \
	  && mv -f $@.tmp $@ \
	  && git commit ChangeLog -m 'generated changelog' \
	  && if [ -e ".git/svn" ]; then \
	    git svn dcommit ; \
	    fi \
	  || (rm -f  $@.tmp; \
	 echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
	 (test -f $@ || echo git-log is required to generate this file >> $@)); \
	else \
	 svn2cl --accum --authors ../common/username.xml; \
	 rm -f *.bak;  \
	fi;
