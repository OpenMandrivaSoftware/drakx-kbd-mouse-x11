include ../Makefile.config

# Installation directories
localedir = $(DESTDIR)/usr/share/locale

PGOAL = $(NAME)

# perl files to search translatable strings in
PL_FILES:= $(filter-out ../tools/display_driver_helper,$(wildcard ../tools/*)) ../lib/*.pm ../lib/*/*.pm

POFILES = $(shell ls *.po)
MOFILES = $(POFILES:%.po=%.mo)
POTFILE= $(PGOAL).pot
LANGS = $(POFILES:%.po=%)

PREFIX = $(RPM_BUILD_ROOT)/usr
DATADIR = $(PREFIX)/share
LOCALEDIR=$(DATADIR)/locale

all: $(MOFILES)

install: all
	for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	rm -f *~ *.[oas] *.mo POTFILES.in TAGS

%.mo: %.po
	msgfmt -o $@ $<

$(POTFILE): $(PL_FILES) POTFILES.in
	intltool-update --gettext-package non-perl --pot
	perl_checker -q --generate-pot .$@ $(PL_FILES)
	msgcat -w 2048 --use-first .$@ non-perl.pot > $@
	rm -f non-perl.pot ..$@ .$@

POTFILES.in:
	(cd .. ; /bin/ls -1 polkit/*.policy.in; ) > POTFILES.in

update_n_merge: $(PGOAL).pot merge

merge: $(PGOAL).pot
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge -C "$$n" "$$n" $(PGOAL).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

# there are better ways to do this, but..
merge_mageia_translations: $(NAME).pot
	@for n in $(POFILES); do \
		echo "Merging $$n translations from Mageia"; \
		mv "$$n" "$$n.orig"; \
		git checkout --theirs mageia/master "$$n"; \
		if [ $$? -ne 0 ]; then \
			sed -e '/^$$/q' "$$n" > "$$n.header"; \
			sed -e 's#ageia#oondrake#g' -i "$$n"; \
			msgcat --use-first -o "$$n.temp" -t utf-8 -s "$$n.orig" "$$n"; \
			git checkout --theirs software/master "$$n"; \
			msgcat --use-first -o "$$n.orig" "$$n.header" "$$n.temp"; \
			rm "$$n.temp" "$$n.header"; \
		fi; \
		mv "$$n.orig" "$$n"; \
		msgmerge "$$n" $^ > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done
