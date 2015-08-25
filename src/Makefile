PREFIX ?= /usr/local

UNAME_S := $(shell uname -s)

GTK = gtk+-3.0
GTK_CFLAGS = $(shell pkg-config --cflags $(GTK))
GTK_LIBS = $(shell pkg-config --libs $(GTK) gmodule-2.0 gio-unix-2.0)

LUAJIT_VER = LuaJIT-2.0.4
LUAJIT_CHECKSUM = dd9c38307f2223a504cbfb96e477eca0
LUAJIT = deps/${LUAJIT_VER}
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://luajit.org/download/$(LUAJIT_VER).tar.gz

LPEG_VER = lpeg-0.10.2
LPEG_CHECKSUM = 1402433f02e37ddadff04a3d4118b026
LPEG = deps/$(LPEG_VER)
LPEG_OBJECT = $(LPEG)/lpeg.o
LPEG_URL = http://nordman.org/mirror/lpeg/$(LPEG_VER).tar.gz

CFLAGS = -Wall -O2 -g $(LUAJIT_CFLAGS) $(GTK_CFLAGS) -DHOWL_PREFIX=$(PREFIX)
ARCHIVES = $(LUAJIT_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
ifeq ($(UNAME_S),Darwin)
	LD_FLAGS = -Wl,-export_dynamic -pagezero_size 10000 -image_base 100000000
else
	LD_FLAGS = -Wl,-E
endif
OBJECTS = main.o process_helpers.o
DEP_OBJECTS = $(LPEG_OBJECT)

all: howl bytecode

howl: ${OBJECTS} main.h $(ARCHIVES) $(DEP_OBJECTS) Makefile
	${CC} -o howl ${OBJECTS} $(DEP_OBJECTS) ${ARCHIVES} ${LIBS} ${LD_FLAGS}

${OBJECTS}: %.o : %.c main.h $(LUAJIT)
	${CC} -c $< ${CFLAGS}

$(LPEG):
	@tools/download $(LPEG_URL) $(LPEG_CHECKSUM) tar xzf {file} -C deps

$(LPEG_OBJECT): $(LPEG) $(LUAJIT)
	cd ${LPEG} && $(MAKE) lpeg.o LUADIR=../../$(LUAJIT)/src

$(LUAJIT):
	@tools/download $(LUAJIT_URL) $(LUAJIT_CHECKSUM) tar xzf {file} -C deps
	@perl -piorig -e 's/LUA_IDSIZE\s*\d+/LUA_IDSIZE 120/' $(LUAJIT)/src/luaconf.h

$(LUAJIT_ARCHIVE): $(LUAJIT)
	cd ${LUAJIT} && $(MAKE) XCFLAGS="-DLUAJIT_ENABLE_LUA52COMPAT"

deps-download: $(LUAJIT) $(LPEG)

deps-purge:
	rm -rf $(LUAJIT) $(LPEG)

deps-clean:
	@rm $(LPEG_OBJECT) || true
	@cd $(LUAJIT) && $(MAKE) clean

clean:
	-rm -f ${OBJECTS}

bytecode: howl
	-@find ../lib ../bundles -name '*.bc' | xargs rm
	@find ../lib ../bundles -name '*.lua' -o -name '*.moon' | xargs ./howl --compile

install: all
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
