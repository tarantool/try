PACKAGE = tarantool-try-module
DESCRIBE = $(subst -, ,$(shell (git describe || echo 1.0-1))) 0
VERSION = $(word 1,$(DESCRIBE))
RELEASE = $(word 2,$(DESCRIBE))
RPMROOT = ${HOME}/rpmbuild
TARBALL = $(RPMROOT)/SOURCES/$(PACKAGE).tar.gz
SPEC = $(RPMROOT)/SPECS/$(PACKAGE).spec

FILES = container/ templates/ public/ \
	start_try_tarantool.lua try_tarantool.lua README.md

all: rpm

$(SPEC):
	mkdir -p $(RPMROOT)/SPECS
	cp try.spec $@
	sed -i -e 's/^Version: [0-9.]*$$/Version: $(VERSION)/' -e 's/^Release: [0-9]*$$/Release: $(RELEASE)/' $@

$(TARBALL): $(FILES) try.spec
	mkdir -p $(RPMROOT)/SOURCES
	$(eval TEMPDIR := $(shell mktemp -d))
	mkdir $(TEMPDIR)/$(PACKAGE)
	cp -ar $(FILES) $(TEMPDIR)/$(PACKAGE)
	cd $(TEMPDIR) && tar -cvzf $@ $(PACKAGE)/
	rm -rf $(TEMPDIR)

rpm: clean $(TARBALL) $(SPEC)
	rpmbuild -bb $(SPEC) --clean
	rm -f $(TARBALL) $(SPEC)
	@echo "RPM package is built in $(RPMROOT)"

clean:
	rm -f $(RPMROOT)/RPMS/*/$(PACKAGE)-$(VERSION)-$(RELEASE).*.rpm

.PHONY : all clean
