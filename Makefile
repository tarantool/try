PACKAGE = tarantool-try
DESCRIBE = $(subst -, ,$(shell (git describe --long --always))) 0
VERSION = $(word 1,$(DESCRIBE))
RELEASE = $(word 2,$(DESCRIBE))
RPMROOT = ${HOME}/rpmbuild
TARBALL = $(RPMROOT)/SOURCES/$(PACKAGE).tar.gz
SPEC = $(RPMROOT)/SPECS/$(PACKAGE).spec

FILES = try/ start.lua README.md

all: rpm

$(SPEC):
	mkdir -p $(RPMROOT)/SPECS
	cp rpm/try.spec $@
	sed -i -e 's/^Version: [0-9.]*$$/Version: $(VERSION)/' -e 's/^Release: [0-9]*$$/Release: $(RELEASE)/' $@

$(TARBALL): $(FILES) rpm/try.spec
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
	rm -f $(TARBALL) $(SPEC)

template:
	make -C templates

.PHONY : all clean
