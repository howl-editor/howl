#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include <gtk/gtk.h>
#include <glib.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* External dependencies hookups */
int luaopen_lpeg (lua_State *L);
int luaopen_lfs (lua_State *L);
int luaopen_lgi_corelgilua51 (lua_State* L);
