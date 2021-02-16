.PHONY: all install

all: $(shell find front/src -type f) front/node_modules
	npm run build --prefix front

front/node_modules: front/package.json
	npm ci --prefix front
	@ touch $@

install:
	mkdir -p $(INSTALL_LUADIR)/cartridge-app/
	cp front/build/bundle.lua $(INSTALL_LUADIR)/cartridge-app/bundle.lua
