PREFIX ?= /usr/local

GTK = gtk+-3.0
GTK_CFLAGS = $(shell pkg-config --cflags $(GTK))
GTK_LIBS = $(shell pkg-config --libs $(GTK) gobject-introspection-1.0 gmodule-2.0 libffi)

LUAJIT_VER = LuaJIT-2.0.2
LUAJIT_CHECKSUM = 112dfb82548b03377fbefbba2e0e3a5b
LUAJIT = deps/${LUAJIT_VER}
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://nordman.org/mirror/luajit/$(LUAJIT_VER).tar.gz

SCINTILLA_VER = scintilla337
SCINTILLA_CHECKSUM = 8243f3a58c05fe4036f378dde0611c67
SCINTILLA_URL = http://prdownloads.sourceforge.net/scintilla/$(SCINTILLA_VER).tgz?download
SCINTILLA = deps/$(SCINTILLA_VER)
SCINTILLA_IFACE = $(SCINTILLA)/include/Scintilla.iface
SCINTILLA_CFLAGS = -I$(SCINTILLA)/include -DGTK=1
SCINTILLA_ARCHIVE = $(SCINTILLA)/bin/scintilla.a
SCINTILLA_DEFS = GTK=1 GTK3=1 LEXOBJS=

LPEG_VER = lpeg-0.10.2
LPEG_CHECKSUM = 1402433f02e37ddadff04a3d4118b026
LPEG = deps/$(LPEG_VER)
LPEG_OBJECT = $(LPEG)/lpeg.o
LPEG_URL = http://nordman.org/mirror/lpeg/$(LPEG_VER).tar.gz

LGI_VER = 0.7.2
LGI_CHECKSUM = f41902695c3d8ef40312d7c654885bf3
LGI_URL = https://github.com/pavouk/lgi/archive/$(LGI_VER).tar.gz
LGI = deps/lgi-$(LGI_VER)
LGI_ARCHIVE = $(LGI)/lgi/lgi.a

SCI_GEN = tools/sci_gen.lua
SCI_GEN_TARGET = ../lib/howl/scintilla.lua

CFLAGS = -Wall -O2 -g $(LUAJIT_CFLAGS) $(SCINTILLA_CFLAGS) $(GTK_CFLAGS)
ARCHIVES = $(LUAJIT_ARCHIVE) $(SCINTILLA_ARCHIVE) $(LGI_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
LD_FLAGS = -Wl,-E
OBJECTS = main.o
DEP_OBJECTS = $(LPEG_OBJECT)

all: howl bytecode

howl: ${OBJECTS} main.h $(ARCHIVES) $(DEP_OBJECTS) Makefile
	${CC} -o howl ${CFLAGS} ${OBJECTS} $(DEP_OBJECTS) ${ARCHIVES} ${LIBS} ${LD_FLAGS}

${OBJECTS}: %.o : %.c main.h $(SCINTILLA) $(LUAJIT)
	${CC} -c $< ${CFLAGS}

$(LPEG):
	@tools/download $(LPEG_URL) $(LPEG_CHECKSUM) tar xzf {file} -C deps

$(LPEG_OBJECT): $(LPEG) $(LUAJIT)
	cd ${LPEG} && $(MAKE) lpeg.o LUADIR=../../$(LUAJIT)/src

$(SCINTILLA):
	@tools/download $(SCINTILLA_URL) $(SCINTILLA_CHECKSUM) tar xzf {file} -C deps
	@mv deps/scintilla $(SCINTILLA)
	@perl -piorig -e 's/LINK_LEXER\(\w+\);//' $(SCINTILLA)/src/Catalogue.cxx

$(SCINTILLA_ARCHIVE): $(SCINTILLA)
	cd ${SCINTILLA}/gtk && make $(SCINTILLA_DEFS)

$(LUAJIT):
	@tools/download $(LUAJIT_URL) $(LUAJIT_CHECKSUM) tar xzf {file} -C deps
	@perl -piorig -e 's/LUA_IDSIZE\s*\d+/LUA_IDSIZE 120/' $(LUAJIT)/src/luaconf.h

$(LUAJIT_ARCHIVE): $(LUAJIT)
	cd ${LUAJIT} && $(MAKE) XCFLAGS="-DLUAJIT_ENABLE_LUA52COMPAT"

$(LGI):
	@tools/download $(LGI_URL) $(LGI_CHECKSUM) tar xzf {file} -C deps

$(LGI_ARCHIVE): $(LGI)
	cd ${LGI}/lgi && $(MAKE) LUA_CFLAGS=$(LUAJIT_CFLAGS)
	ar rs $(LGI_ARCHIVE) ${LGI}/lgi/*.o

deps: scintilla-build luajit-build lpeg-build scintillua-build

deps-purge:
	rm -rf $(LGI) $(LUAJIT) $(LPEG) $(SCINTILLA)

clean:
	-rm -f ${OBJECTS}

scigen: $(LUAJIT_ARCHIVE) $(SCINTILLA)
	$(LUAJIT)/src/luajit $(SCI_GEN) $(SCINTILLA_IFACE) $(SCI_GEN_TARGET)

bytecode: howl
	-@find ../lib ../bundles -name '*.bc' | xargs rm
	@find ../lib ../bundles -name '*.lua' -o -name '*.moon' | xargs ./howl --compile

lgi-update: $(LGI)
	rm -rf ../lib/ext/lgi/*
	cp $(LGI)/lgi/*.lua ../lib/ext/lgi/
	cp -r $(LGI)/lgi/override ../lib/ext/lgi/
	cp -r $(LGI)/README.md ../lib/ext/lgi/
	cp -r $(LGI)/LICENSE ../lib/ext/lgi/

install: howl
	@echo Installing to $(DESTDIR)$(PREFIX)..
	@mkdir -p $(DESTDIR)$(PREFIX)/bin/
	@mkdir -p $(DESTDIR)$(PREFIX)/share/howl/
	@mkdir -p $(DESTDIR)$(PREFIX)/share/howl/spec

	@cp -p howl $(DESTDIR)$(PREFIX)/bin/
	@cp -p ../bin/howl-spec $(DESTDIR)$(PREFIX)/bin/
	@cp -rp ../bundles $(DESTDIR)$(PREFIX)/share/howl
	@cp -rp ../lib $(DESTDIR)$(PREFIX)/share/howl
	@cp -rp ../spec/support $(DESTDIR)$(PREFIX)/share/howl/spec
	@cp -rp ../share/* $(DESTDIR)$(PREFIX)/share/
	@echo All done.

uninstall:
	@echo Uninstalling from $(DESTDIR)$(PREFIX)..
	@rm -v $(DESTDIR)$(PREFIX)/bin/howl
	@rm -vr $(DESTDIR)$(PREFIX)/share/howl
	@rm -v $(DESTDIR)$(PREFIX)/share/applications/howl.desktop
	@rm -v $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/howl.svg
	@echo All done.
