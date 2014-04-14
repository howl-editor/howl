PREFIX ?= /usr/local

GTK = gtk+-3.0
GTK_CFLAGS = $(shell pkg-config --cflags $(GTK))
GTK_LIBS = $(shell pkg-config --libs $(GTK) gmodule-2.0)

LUAJIT_VER = LuaJIT-2.0.3
LUAJIT_CHECKSUM = f14e9104be513913810cd59c8c658dc0
LUAJIT = deps/${LUAJIT_VER}
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://nordman.org/mirror/luajit/$(LUAJIT_VER).tar.gz

SCINTILLA_VER = scintilla341
SCINTILLA_CHECKSUM = d01e031bec3f72d1c5fd6f716f14e0ed
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

SCI_GEN = tools/sci_gen.lua
SCI_GEN_TARGET = ../lib/howl/scintilla.lua

CFLAGS = -Wall -O2 -g $(LUAJIT_CFLAGS) $(SCINTILLA_CFLAGS) $(GTK_CFLAGS)
ARCHIVES = $(LUAJIT_ARCHIVE) $(SCINTILLA_ARCHIVE)
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

deps-download: $(LUAJIT) $(SCINTILLA) $(LPEG)

deps-purge:
	rm -rf $(LUAJIT) $(LPEG) $(SCINTILLA)

clean:
	-rm -f ${OBJECTS}

scigen: $(LUAJIT_ARCHIVE) $(SCINTILLA)
	$(LUAJIT)/src/luajit $(SCI_GEN) $(SCINTILLA_IFACE) $(SCI_GEN_TARGET)

bytecode: howl
	-@find ../lib ../bundles -name '*.bc' | xargs rm
	@find ../lib ../bundles -name '*.lua' -o -name '*.moon' | xargs ./howl --compile

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
