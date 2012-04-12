#
# Makefile for compiling lgi core module in standard-Lua variant
#
# Author: Pavel Holejsovsky <pavel.holejsovsky@gmail.com>
# License: MIT
#

PREFIX = /usr/local
LUA_LIBDIR = $(PREFIX)/lib/lua/5.1
LUA_SHAREDIR = $(PREFIX)/share/lua/5.1

GINAME = gobject-introspection-1.0
VERSION_FILE = version.lua

ifneq ($(filter CYGWIN%, $(shell uname -s)),)
CORE = corelgilua51.dll
LIBFLAG = -shared
LIBS += -llua
else
CORE = corelgilua51.so
LIBFLAG = -shared
CCSHARED = -fPIC
endif

OBJS = buffer.o callable.o core.o gi.o marshal.o object.o record.o

COPTFLAGS = -Wall -O2 -g
CFLAGS = $(CCSHARED) $(COPTFLAGS) $(LUA_CFLAGS) $(shell pkg-config --cflags $(GINAME))
LIBS += $(shell pkg-config --libs $(GINAME))
LDFLAGS = $(LIBFLAG)
DEPCHECK = .depcheck

# Precondition check
$(DEPCHECK) : Makefile
	pkg-config --exists '$(GINAME) >= 0.10.8' --print-errors
	touch $@

.PHONY : all clean install

all : $(CORE) $(VERSION_FILE)
clean :
	rm -f $(CORE) $(OBJS)

$(CORE) : $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

$(VERSION_FILE) : Makefile ../Makefile
	echo "return '$(VERSION)'" > $@

buffer.o : buffer.c lgi.h $(DEPCHECK)
callable.o : callable.c lgi.h $(DEPCHECK)
core.o : core.c lgi.h $(DEPCHECK)
gi.o : gi.c lgi.h $(DEPCHECK)
marshal.o : marshal.c lgi.h $(DEPCHECK)
object.o : object.c lgi.h $(DEPCHECK)
record.o : record.c lgi.h $(DEPCHECK)

OVERRIDES = $(wildcard override/*.lua)
CORESOURCES = $(wildcard *.lua)

install : $(CORE) $(VERSION_FILE)
	mkdir -p $(DESTDIR)$(LUA_LIBDIR)/lgi
	cp $(CORE) $(DESTDIR)$(LUA_LIBDIR)/lgi
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)
	cp ../lgi.lua $(DESTDIR)$(LUA_SHAREDIR)
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)/lgi
	cp $(CORESOURCES) $(VERSION_FILE) $(DESTDIR)$(LUA_SHAREDIR)/lgi
	mkdir -p $(DESTDIR)$(LUA_SHAREDIR)/lgi/override
	cp $(OVERRIDES) $(DESTDIR)$(LUA_SHAREDIR)/lgi/override
