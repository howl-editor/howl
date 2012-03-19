GTK = gtk+-3.0
GTK_CFLAGS := $(shell pkg-config --cflags ${GTK})
GTK_LIBS := $(shell pkg-config --libs ${GTK})

LUAJIT_VER = LuaJIT-2.0.0-beta9
LUAJIT = deps/$(LUAJIT_VER)
LUAJIT_CFLAGS = -I$(LUAJIT)/src
LUAJIT_ARCHIVE = $(LUAJIT)/src/libluajit.a
LUAJIT_URL = http://luajit.org/download/$(LUAJIT_VER).tar.gz

SCINTILLA_VER = scintilla304
SCINTILLA_URL = http://prdownloads.sourceforge.net/scintilla/$(SCINTILLA_VER).tgz?download
SCINTILLA = deps/$(SCINTILLA_VER)
SCINTILLA_CFLAGS = -I$(SCINTILLA)/include -DGTK=1
SCINTILLA_ARCHIVE = $(SCINTILLA)/bin/scintilla.a
SCINTILLA_DEFS = GTK=1 GTK3=1

CFLAGS = -Wall $(LUAJIT_CFLAGS) $(SCINTILLA_CFLAGS) $(GTK_CFLAGS)
ARCHIVES = $(LUAJIT_ARCHIVE) $(SCINTILLA_ARCHIVE)
LIBS = -lm -ldl ${GTK_LIBS} -lstdc++
LD_FLAGS = -Wl,-E
OBJECTS = gtk_ui.o main.o

vilu: ${OBJECTS} vilu.h
	  ${CC} -g -o vilu ${CFLAGS} ${OBJECTS} ${ARCHIVES} ${LIBS} ${LD_FLAGS}

${OBJECTS}: %.o : %.c vilu.h
	  ${CC} -c $< ${CFLAGS}

$(SCINTILLA):
	  wget -q -O - $(SCINTILLA_URL) | tar xzf - -C deps
	  mv deps/scintilla $(SCINTILLA)

scintilla-build: $(SCINTILLA)
	  cd ${SCINTILLA}/gtk && make $(SCINTILLA_DEFS)

$(LUAJIT):
	  wget -q -O - $(LUAJIT_URL) | tar xzf - -C deps

luajit-build: $(LUAJIT)
	  cd ${LUAJIT} && make

deps: scintilla-build luajit-build

clean:
	  -rm -f ${OBJECTS}
