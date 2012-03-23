#include "vilu.h"

lua_State *L;
gchar *app_root;

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

gchar *get_app_root(const gchar *invocation_path)
{
  gchar *cwd, *relative_path, *root;

  cwd = g_get_current_dir();
  relative_path = g_path_get_dirname(invocation_path);
  root = g_build_filename(cwd, relative_path, NULL);
  g_free(cwd);
  g_free(relative_path);
  return root;
}

int main(int argc, char *argv[])
{
  int status;

  app_root = get_app_root(argv[0]);
  L = luaL_newstate();
  luaL_openlibs(L);
  status = ui_run(argc, argv, L, do_lua);
  lua_close(L);

  g_free(app_root);

  return status;
}
