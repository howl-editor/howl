GTK = gtk+-3.0
GTK_CFLAGS := $(shell pkg-config --cflags ${GTK})
GTK_LIBS := $(shell pkg-config --libs ${GTK} gobject-introspection-1.0)

LUAJIT_VER = LuaJIT-2.0.0-beta9
LUAJIT = deps/$(LUAJIT_VER)
LUAJIT_SRC_DIR = $(realpath $(LUAJIT)/src)
LUAJIT_CFLAGS = -I$(LUAJIT_SRC_DIR)
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://luajit.org/download/$(LUAJIT_VER).tar.gz

LPEG_VER = lpeg-0.10.2
LPEG = deps/$(LPEG_VER)
LPEG_OBJECT = $(LPEG)/lpeg.o
LPEG_URL = http://www.inf.puc-rio.br/~roberto/lpeg/$(LPEG_VER).tar.gz

LFS_VER = luafilesystem-1.5.0
LFS_URL = https://github.com/downloads/keplerproject/luafilesystem/$(LFS_VER).tar.gz
LFS = deps/$(LFS_VER)
LFS_OBJECT = deps/$(LFS_VER)/src/lfs.o

LGI_VER = lgi-0.5x
#LGI_URL = https://github.com/downloads/pavouk/lgi/$(LGI_VER).tar.gz
LGI_URL = http://nordman.org/download/$(LGI_VER).tgz
LGI = deps/$(LGI_VER)
LGI_ARCHIVE = deps/$(LGI_VER)/lgi/lgi.a

CFLAGS = -Wall -O2 $(LUAJIT_CFLAGS) $(GTK_CFLAGS)
ARCHIVES = $(LUAJIT_ARCHIVE) $(LGI_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
LD_FLAGS = -Wl,-E
OBJECTS = main.o
DEP_OBJECTS = $(LPEG)/lpeg.o $(LFS_OBJECT)

vilu: ${OBJECTS} vilu.h $(DEP_OBJECTS) $(ARCHIVES) Makefile
	  ${CC} -o vilu ${CFLAGS} ${OBJECTS} $(DEP_OBJECTS) ${ARCHIVES} ${LIBS} ${LD_FLAGS}

${OBJECTS}: %.o : %.c vilu.h
	  ${CC} -c $< ${CFLAGS}

$(LPEG):
	  wget -q -O - $(LPEG_URL) | tar xzf - -C deps

$(LPEG_OBJECT): $(LPEG) $(LUAJIT)
	  cd ${LPEG} && $(MAKE) lpeg.o LUADIR=../../$(LUAJIT)/src

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

clean:
	  -rm -f ${OBJECTS}
