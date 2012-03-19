#include <stdlib.h>
#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

typedef void (*ViluCallback)(void);
int ui_run(int argc, char *argv[], lua_State *L, ViluCallback callback);

void * _ui_window_new();
void * _ui_view_new(void *window);
