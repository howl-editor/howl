#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include <glib.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

void sci_init(lua_State *L, const gchar *app_root);
void sci_close();

/* External dependencies hookups */
int luaopen_lpeg (lua_State *L);
int luaopen_lfs (lua_State *L);
int luaopen_lgi_corelgilua51 (lua_State* L);
