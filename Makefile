DESTDIR=
prefix=/usr/local
bindir=$(prefix)/bin
libdir=$(prefix)/share/baconbird
docdir=$(prefix)/share/doc/baconbird
PERL=$(shell which perl)
POD2HTML=pod2html

MAINFILE=baconbird
MODULE_DIRS=BaconBird WWW
PERL_MODULES=Moose Net::Twitter WWW::Shorten URI::Find HTML::Strip stfl IO::Socket::SSL URI::Find Config::General

HTMLFILE=doc/baconbird.html
PODFILE=doc/baconbird.pod

CP=cp
MKDIR=mkdir -p
RM=rm -rf
INSTALL=install

.PHONY: baconbird install doc clean

baconbird: 
	@echo -n "Checking for dependencies..."
	@perl depcheck.pl $(PERL_MODULES)
	@echo "OK"

install: doc
	$(CP) $(MAINFILE) $(MAINFILE).tmp
	$(PERL) -pi -e 's|^use lib "."|use lib "$(libdir)"|' $(MAINFILE).tmp
	$(PERL) -pi -e 's|^#!.+|#!$(PERL)|' $(MAINFILE).tmp
	$(MKDIR) $(DESTDIR)$(bindir) $(DESTDIR)$(libdir) $(DESTDIR)$(docdir)
	$(INSTALL) -m 0755 $(MAINFILE).tmp $(DESTDIR)$(bindir)/$(MAINFILE)
	$(CP) -r $(MODULE_DIRS) $(DESTDIR)$(libdir)
	$(RM) $(MAINFILE).tmp
	$(INSTALL) -m 0644 $(HTMLFILE) $(DESTDIR)$(docdir)

doc: $(HTMLFILE)

$(HTMLFILE): $(PODFILE)
	$(POD2HTML) $< > $@

clean:
	$(RM) $(HTMLFILE) *.tmp
