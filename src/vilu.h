#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include <glib.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

typedef void (*ViluCallback)(void);
int ui_run(int argc, char *argv[], lua_State *L, ViluCallback callback);

void * window_new();
void * text_view_new(void *window);
intptr_t text_view_sci(void *view, int message, intptr_t wParam, intptr_t lParam);

extern gchar *app_root;
