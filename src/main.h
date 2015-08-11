/* Copyright 2012-2015 The Howl Developers */
/* License: MIT (see LICENSE.md at the top-level directory of the distribution) */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <glib.h>
#include <gtk/gtk.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* External dependencies hookups */
int luaopen_lpeg (lua_State *L);
