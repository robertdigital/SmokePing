SHELL = /bin/sh
VERSION = 1.38
IGNORE = ~|CVS|var/|smokeping-$(VERSION)/smokeping-$(VERSION)|cvsignore|rej|orig|DEAD|pod2htm[di]\.tmp
GROFF = groff
.PHONY: man html txt ref examples check-examples patch killdoc doc tar rename-man symlinks remove-symlinks
.SUFFIXES:
.SUFFIXES: .pm .pod .txt .html .man .1 .3 .5 .7

DOCS = $(filter-out smokeping_config,$(wildcard doc/*.pod)) doc/smokeping_examples.pod # section 7
DOCSCONFIG := doc/smokeping_config.pod # section 5
PM :=  lib/ISG/ParseConfig.pm lib/Smokeping.pm lib/Smokeping/Examples.pm
PODPROBE :=  $(wildcard lib/Smokeping/probes/*.pm)
PODMATCH :=  $(wildcard lib/Smokeping/matchers/*.pm)

DOCSBASE = $(subst .pod,,$(DOCS))
MODBASE = $(subst .pm,,$(subst lib/,doc/,$(PM))) \
	$(subst .pm,,$(subst lib/,doc/,$(PODPROBE))) \
	$(subst .pm,,$(subst lib/,doc/,$(PODMATCH)))
PROGBASE = doc/smokeping doc/smokeping.cgi
DOCSCONFIGBASE = doc/smokeping_config

BASE = $(DOCSBASE) $(MODBASE) $(PROGBASE) $(DOCSCONFIGBASE)

MAN = $(addsuffix .3,$(MODBASE)) $(addsuffix .5,$(DOCSCONFIGBASE)) $(addsuffix .7,$(DOCSBASE)) $(addsuffix .1,$(PROGBASE))
TXT = $(addsuffix .txt,$(BASE))
HTML= $(addsuffix .html,$(BASE))

POD2MAN = pod2man --release=$(VERSION) --center=SmokePing $<
MAN2TXT = $(GROFF) -man -Tascii $< > $@
# pod2html apparently needs to be in the target directory to get L<> links right
POD2HTML= cd $(dir $@); top=$(shell echo $(dir $@)|sed 's,[^/]*/,../,g'); pod2html --infile=$(CURDIR)/$< --outfile=$(notdir $@) --noindex --htmlroot=. --podroot=. --podpath=$${top}doc --title=$*
# we go to this trouble to ensure that MAKEPOD only uses modules in the installation directory
MAKEPOD= perl -Ilib -I/usr/pack/rrdtool-1.0.47-to/lib/perl -mSmokeping -e 'Smokeping::main()' -- --makepod
GENEX= perl -Ilib -I/usr/pack/rrdtool-1.0.47-to/lib/perl -mSmokeping -e 'Smokeping::main()' -- --gen-examples

doc/%.7: doc/%.pod
	$(POD2MAN) --section 7 > $@
doc/%.5: doc/%.pod
	$(POD2MAN) --section 5 > $@

doc/Smokeping.3: lib/Smokeping.pm
	$(POD2MAN) --section 3 > $@
doc/Smokeping/Examples.3: lib/Smokeping/Examples.pm
	$(POD2MAN) --section 3 > $@

doc/Smokeping/probes/%.pod: lib/Smokeping/probes/%.pm
	$(MAKEPOD) Smokeping::probes::$* > $@

doc/Smokeping/probes/%.3: doc/Smokeping/probes/%.pod
	$(POD2MAN) --section 3 > $@
doc/Smokeping/matchers/%.3: lib/Smokeping/matchers/%.pm
	$(POD2MAN) --section 3 > $@
doc/ISG/%.3: lib/ISG/%.pm
	$(POD2MAN) --section 3 > $@
doc/smokeping.1: bin/smokeping.dist
	$(POD2MAN) --section 1 > $@
doc/smokeping.cgi.1: htdocs/smokeping.cgi.dist
	$(POD2MAN) --section 1 > $@

doc/%.html: doc/%.pod
	$(POD2HTML)
doc/Smokeping.html: lib/Smokeping.pm
	$(POD2HTML)
doc/Smokeping/Examples.html: lib/Smokeping/Examples.pm
	$(POD2HTML)
doc/Smokeping/matchers/%.html: lib/Smokeping/matchers/%.pm
	$(POD2HTML)
doc/ISG/%.html: lib/ISG/%.pm
	$(POD2HTML)
doc/smokeping.html: bin/smokeping.dist
	$(POD2HTML)
doc/smokeping.cgi.html: htdocs/smokeping.cgi.dist
	$(POD2HTML)

doc/%.txt: doc/%.1
	$(MAN2TXT)
doc/%.txt: doc/%.3
	$(MAN2TXT)
doc/%.txt: doc/%.5
	$(MAN2TXT)
doc/%.txt: doc/%.7
	$(MAN2TXT)

man: $(MAN)

html: symlinks $(HTML) remove-symlinks

txt: $(TXT)

rename-man: $(MAN)
	for j in probes matchers; do \
	  for i in doc/Smokeping/$$j/*.3; do \
	    mv $$i `echo $$i | sed s,$$j/,$$j/Smokeping::$$j::,`; \
	  done; \
	done
	mv doc/ISG/ParseConfig.3 doc/ISG/ISG::ParseConfig.3
	mv doc/Smokeping/Examples.3 doc/Smokeping/Smokeping::Examples.3

ref: doc/smokeping_config.pod

symlinks:
	-ln -s bin/smokeping.dist doc/smokeping.pod
	-ln -s htdocs/smokeping.cgi.dist doc/smokeping.cgi.pod

remove-symlinks:
	-rm doc/smokeping.pod
	-rm doc/smokeping.cgi.pod

examples:
	$(GENEX)

check-examples:
	$(GENEX) --check

doc/smokeping_config.pod: lib/Smokeping.pm
	$(MAKEPOD) > $@
doc/smokeping_examples.pod: lib/Smokeping/Examples.pm etc/config.dist
	$(GENEX)
patch:
	perl -i~ -p -e 's/VERSION="\d.*?"/VERSION="$(VERSION)"/' lib/Smokeping.pm 
	perl -i~ -p -e 's/Smokeping \d.*?;/Smokeping $(VERSION);/' bin/smokeping.dist htdocs/smokeping.cgi.dist

killdoc:
	-rm doc/*.[1357] doc/*.txt doc/*.html doc/Smokeping/* doc/Smokeping/probes/* doc/Smokeping/matchers/* doc/ISG/* doc/examples/* doc/smokeping_examples.pod doc/smokeping_config.pod

doc:    killdoc ref examples man html txt rename-man

tar:	doc patch
	-ln -s . smokeping-$(VERSION)
	find smokeping-$(VERSION)/* -type f -follow -o -type l | egrep -v '$(IGNORE)' | gtar -T - -czvf smokeping-$(VERSION).tar.gz
	rm smokeping-$(VERSION)
	
dist:   tar
	mv smokeping-$(VERSION).tar.gz /home/oetiker/public_html/webtools/smokeping/pub/
	cp CHANGES /home/oetiker/public_html/webtools/smokeping/pub/CHANGES
