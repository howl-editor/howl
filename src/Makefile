GTK = gtk+-3.0
GTK_CFLAGS := $(shell pkg-config --cflags ${GTK})
GTK_LIBS := $(shell pkg-config --libs ${GTK} gobject-introspection-1.0)

LUAJIT_VER = LuaJIT-2.0.0-beta11
LUAJIT = deps/$(LUAJIT_VER)
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://luajit.org/download/$(LUAJIT_VER).tar.gz

SCINTILLA_VER = scintilla323
SCINTILLA_URL = http://prdownloads.sourceforge.net/scintilla/$(SCINTILLA_VER).tgz?download
SCINTILLA = deps/$(SCINTILLA_VER)
SCINTILLA_IFACE = $(SCINTILLA)/include/Scintilla.iface
SCINTILLA_CFLAGS = -I$(SCINTILLA)/include -DGTK=1
SCINTILLA_ARCHIVE = $(SCINTILLA)/bin/scintilla.a
SCINTILLA_DEFS = GTK=1 GTK3=1 LEXOBJS=

LPEG_VER = lpeg-0.10.2
LPEG = deps/$(LPEG_VER)
LPEG_OBJECT = $(LPEG)/lpeg.o
LPEG_URL = http://www.inf.puc-rio.br/~roberto/lpeg/$(LPEG_VER).tar.gz

LFS_VER = luafilesystem-1.5.0
LFS_URL = https://github.com/downloads/keplerproject/luafilesystem/$(LFS_VER).tar.gz
LFS = deps/$(LFS_VER)
LFS_OBJECT = deps/$(LFS_VER)/src/lfs.o

LGI_VER = lgi-0.6.2
LGI_URL = https://github.com/downloads/pavouk/lgi/$(LGI_VER).tar.gz
LGI = deps/$(LGI_VER)
LGI_ARCHIVE = deps/$(LGI_VER)/lgi/lgi.a

SCI_GEN = tools/sci_gen.lua
SCI_GEN_TARGET = ../lib/lunar/scintilla.lua

CFLAGS = -Wall -O2 $(LUAJIT_CFLAGS) $(SCINTILLA_CFLAGS) $(GTK_CFLAGS)
ARCHIVES = $(LUAJIT_ARCHIVE) $(SCINTILLA_ARCHIVE) $(LGI_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
LD_FLAGS = -Wl,-E
OBJECTS = main.o sci.o
DEP_OBJECTS = $(LPEG)/lpeg.o $(SCINTILLUA_LEXER) $(LFS_OBJECT)

lunar: ${OBJECTS} lunar.h $(DEP_OBJECTS) $(ARCHIVES) Makefile
	  ${CC} -o lunar ${CFLAGS} ${OBJECTS} $(DEP_OBJECTS) ${ARCHIVES} ${LIBS} ${LD_FLAGS}

${OBJECTS}: %.o : %.c lunar.h $(SCINTILLA) $(LUAJIT)
	  ${CC} -c $< ${CFLAGS}

$(LPEG):
	  wget -q -O - $(LPEG_URL) | tar xzf - -C deps

$(LPEG_OBJECT): $(LPEG) $(LUAJIT)
	  cd ${LPEG} && $(MAKE) lpeg.o LUADIR=../../$(LUAJIT)/src

$(SCINTILLA):
	  wget -q -O - $(SCINTILLA_URL) | tar xzf - -C deps
	  mv deps/scintilla $(SCINTILLA)
	  perl -piorig -e 's/LINK_LEXER\(\w+\);//' $(SCINTILLA)/src/Catalogue.cxx

$(SCINTILLA_ARCHIVE): $(SCINTILLA)
	  cd ${SCINTILLA}/gtk && make $(SCINTILLA_DEFS)

$(LUAJIT):
	  wget -q -O - $(LUAJIT_URL) | tar xzf - -C deps

$(LUAJIT_ARCHIVE): $(LUAJIT)
	  cd ${LUAJIT} && $(MAKE) XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT

$(LFS):
	  wget -q -O - $(LFS_URL) | tar xzf - -C deps

$(LFS_OBJECT): $(LFS)
	  cd ${LFS} && $(MAKE) LUA_INC=../../$(LUAJIT)/src

$(LGI):
	  wget -q -O - $(LGI_URL) | tar xzf - -C deps

$(LGI_ARCHIVE): $(LGI)
	  cd ${LGI}/lgi && $(MAKE) LUA_CFLAGS=$(LUAJIT_CFLAGS)
	  ar rs $(LGI_ARCHIVE) ${LGI}/lgi/*.o

deps: scintilla-build luajit-build lpeg-build scintillua-build $(LFS_OBJECT)

clean:
	  -rm -f ${OBJECTS}

scigen: $(LUAJIT_ARCHIVE) $(SCINTILLA)
	  $(LUAJIT)/src/luajit $(SCI_GEN) $(SCINTILLA_IFACE) $(SCI_GEN_TARGET)

lgi-update:
	  rm -rf ../lib/ext/lgi/*
	  cp $(LGI)/lgi/*.lua ../lib/ext/lgi/
	  cp -r $(LGI)/lgi/override ../lib/ext/lgi/
	  cp -r $(LGI)/README.md ../lib/ext/lgi/
	  cp -r $(LGI)/LICENSE ../lib/ext/lgi/
