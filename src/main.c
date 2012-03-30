#include "vilu.h"

lua_State *L;
gchar *app_root;

static int _argc;
static char **_argv;

static void lua_start(void)
{
  gchar *start_script;
  int status, i;

  start_script = g_build_filename(app_root, "lib", "vilu", "init.lua", NULL);

  status = luaL_loadfile(L, start_script);
  if (status) {
    fprintf(stderr, "Couldn't load file: %s\n", lua_tostring(L, -1));
    exit(1);
  }

  g_free(start_script);

  lua_pushstring(L, (char *)app_root);
  lua_newtable(L);
  for(i = 0; i < _argc; ++i) {
    lua_pushnumber(L, i + 1);
    lua_pushstring(L, _argv[i]);
    lua_settable(L, -3);
  }
  status = lua_pcall(L, 2, 0, 0);
  if (status) {
      g_error("Failed to run script: %s\n", lua_tostring(L, -1));
  }
}

static gchar *get_app_root(const gchar *invocation_path)
{
  gchar *cwd, *relative_path, *root;

  cwd = g_get_current_dir();
  relative_path = g_path_get_dirname(invocation_path);
  root = g_build_filename(cwd, relative_path, "..", NULL);
  g_free(cwd);
  g_free(relative_path);
  return root;
}

static lua_State *open_lua_state(void)
{
  lua_State *l = luaL_newstate();
  luaL_openlibs(l);
  luaopen_lpeg(l);
  luaopen_lfs(l);
  return l;
}

int main(int argc, char *argv[])
{
  int status;

  _argc = argc;
  _argv = argv;
  app_root = get_app_root(argv[0]);
  L = open_lua_state();
  status = ui_run(argc, argv, L, lua_start);
  lua_close(L);

  g_free(app_root);

  return status;
}
