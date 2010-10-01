DESTDIR=
prefix=/usr/local
bindir=$(prefix)/bin
libdir=$(prefix)/share/baconbird
PERL=$(shell which perl)

MAINFILE=baconbird
MODULE_DIRS=BaconBird WWW
PERL_MODULES=Moose Net::Twitter WWW::Shorten URI::Find HTML::Strip stfl

CP=cp
MKDIR=mkdir -p
RM=rm -rf
INSTALL=install

.PHONY: baconbird install

baconbird: 
	@echo -n "Checking for dependencies..."
	@perl depcheck.pl $(PERL_MODULES)
	@echo "OK"

install:
	$(CP) $(MAINFILE) $(MAINFILE).tmp
	$(PERL) -pi -e 's|^use lib "."|use lib "$(libdir)"|' $(MAINFILE).tmp
	$(PERL) -pi -e 's|^#!.+|#!$(PERL)|' $(MAINFILE).tmp
	$(MKDIR) $(DESTDIR)$(bindir) $(DESTDIR)$(libdir)
	$(INSTALL) -m 0755 $(MAINFILE).tmp $(DESTDIR)$(bindir)/$(MAINFILE)
	$(CP) -r $(MODULE_DIRS) $(DESTDIR)$(libdir)
	$(RM) $(MAINFILE).tmp

