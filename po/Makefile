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
	rm -f *~ *.[oas] *.mo TAGS

%.mo: %.po
	msgfmt -o $@ $<

$(POTFILE): $(PL_FILES)
	perl_checker -q --generate-pot $@ $(PL_FILES)


update_n_merge: $(PGOAL).pot merge

merge:
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge -C "$$n" "$$n" $(PGOAL).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

