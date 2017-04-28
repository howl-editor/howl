PREFIX ?= /usr/local
UNAME_S := $(shell uname -s)
CWD := $(shell pwd)
ifneq (, $(findstring _NT-,$(UNAME_S)))
	WIN32 = 1
endif

GTK = gtk+-3.0
GTK_CFLAGS = $(shell pkg-config --cflags $(GTK))
GTK_LIBNAMES = $(GTK) gmodule-2.0 gio-unix-2.0
ifdef WIN32
	GTK_LIBNAMES = $(GTK) gmodule-2.0
endif
GTK_LIBS = $(shell pkg-config --libs $(GTK_LIBNAMES))

ifdef WIN32
	HOWL_EXE=howl.exe
else
	HOWL_EXE=howl
endif

LUAJIT_VER = LuaJIT-2.1.0-beta1
LUAJIT_CHECKSUM = 5a5bf71666e77cf6e7a1ae851127b834
LUAJIT = deps/${LUAJIT_VER}
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://nordman.org/mirror/luajit/$(LUAJIT_VER).tar.gz
ifdef WIN32
	LUAJIT_PATCHES = \
		001-luajit-ffi-win32-walk-all-modules.patch \
		002-luajit-win32-build-static.patch
endif

LPEG_VER = lpeg-0.10.2
LPEG_CHECKSUM = 1402433f02e37ddadff04a3d4118b026
LPEG = deps/$(LPEG_VER)
LPEG_OBJECT = $(LPEG)/lpeg.o
LPEG_URL = http://nordman.org/mirror/lpeg/$(LPEG_VER).tar.gz

MODPATH_ISS = deps/modpath.iss
MODPATH_ISS_CHECKSUM = a39bb32a15e0f4b90b38933e6ceb6a78
MODPATH_ISS_URL = https://www.legroom.net/files/software/modpath.iss

ISCC=iscc

CFLAGS = -Wall -O2 -g $(LUAJIT_CFLAGS) $(GTK_CFLAGS) -DHOWL_PREFIX=$(PREFIX)
ARCHIVES = $(LUAJIT_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
ifeq ($(UNAME_S),FreeBSD)
    LIBS = -lm ${GTK_LIBS} -lstdc++
endif
ifeq ($(UNAME_S),Darwin)
	LD_FLAGS = -Wl,-export_dynamic -pagezero_size 10000 -image_base 100000000
else
	LD_FLAGS = -Wl,-E
endif
ifdef WIN32
	# MSYS sets CC to cc, even though it doesn't actually exist.
	CC=gcc
	LIBS = -lm ${GTK_LIBS} -lstdc++ -lkernel32 -lgdi32
	LD_FLAGS = -Wl,--export-all
endif
OBJECTS = main.o process_helpers.o
DEP_OBJECTS = $(LPEG_OBJECT)

.PHONY: all bytecode deps-download deps-purge deps-clean clean install uninstall windist wininstall

all: ${HOWL_EXE} bytecode

${HOWL_EXE}: ${OBJECTS} main.h $(ARCHIVES) $(DEP_OBJECTS) Makefile
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
	cd ${LUAJIT} && for p in $(LUAJIT_PATCHES); do patch -Np1 -i $(CWD)/$$p; done

$(LUAJIT_ARCHIVE): $(LUAJIT)
	cd ${LUAJIT} && $(MAKE) XCFLAGS="-DLUAJIT_ENABLE_LUA52COMPAT"

$(MODPATH_ISS):
	@tools/download $(MODPATH_ISS_URL) $(MODPATH_ISS_CHECKSUM) cp {file} $(MODPATH_ISS)

deps-download: $(LUAJIT) $(LPEG)

deps-purge:
	rm -rf $(LUAJIT) $(LPEG) $(MODPATH_ISS)

deps-clean:
	@rm $(LPEG_OBJECT) || true
	@cd $(LUAJIT) && $(MAKE) clean

clean:
	-rm -f ${OBJECTS}

bytecode: howl
	-@find ../lib ../bundles -name '*.bc' | xargs rm
	@find ../lib ../bundles -name '*.lua' -o -name '*.moon' | xargs ./howl --compile
	@rm -rf windist wininst

install: all
	@echo Installing to $(DESTDIR)$(PREFIX)..
	@mkdir -p $(DESTDIR)$(PREFIX)/bin/
	@mkdir -p $(DESTDIR)$(PREFIX)/share/howl/
	@mkdir -p $(DESTDIR)$(PREFIX)/share/howl/spec

	@cp -p howl $(DESTDIR)$(PREFIX)/bin/
	@cp -p ../bin/howl-spec $(DESTDIR)$(PREFIX)/bin/
	@cp -rp ../bundles $(DESTDIR)$(PREFIX)/share/howl
	@cp -rp ../fonts $(DESTDIR)$(PREFIX)/share/howl
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

windist:
	rm -rf windist
	mkdir -p windist
	mkdir -p windist/lib

	$(MAKE) install PREFIX=windist
	for dll in `ldd howl.exe | grep mingw32 | cut -d= -f1 | cut -f1`; do \
		cp -v /mingw32/bin/$dll windist/bin; \
	done
	rm windist/bin/howl-spec
	cp -v /mingw32/bin/librsvg*.dll /mingw32/bin/gspawn-win32-helper* windist/bin
	cp -v howl.exe windist/bin
	cp -rv /mingw32/lib/gdk-pixbuf-2.0 windist/lib
	zip -r windist/howl.zip windist/bin windist/lib windist/share

wininst: $(MODPATH_ISS) windist
	$(ISCC) wininst.iss
