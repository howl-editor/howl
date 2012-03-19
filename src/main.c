#include "vilu.h"

lua_State *L;

void do_lua(void)
{
    int status;

    status = luaL_loadfile(L, "script.lua");
    if (status) {
        fprintf(stderr, "Couldn't load file: %s\n", lua_tostring(L, -1));
        exit(1);
    }

    /* Ask Lua to run our little script */
    status = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (status) {
        fprintf(stderr, "Failed to run script: %s\n", lua_tostring(L, -1));
        exit(1);
    }
}

int main(int argc, char *argv[])
{
  int status;

  L = luaL_newstate();
  luaL_openlibs(L);
  status = ui_run(argc, argv, L, do_lua);
  lua_close(L);
  return status;
}
