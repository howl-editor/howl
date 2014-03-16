/* Copyright 2012-2013 Nils Nordman <nino at nordman.org> */
/* License: MIT (see LICENSE) */

#include "main.h"
#include <gio/gio.h>
#include <string.h>
#include <Scintilla.h>
#include <ScintillaWidget.h>

static void lua_run(int argc, char *argv[], const gchar *app_root, lua_State *L)
{
  gchar *start_script;
  int status, i;

  start_script = g_build_filename(app_root, "lib", "howl", "init.lua", NULL);
  status = luaL_loadfile(L, start_script);
  g_free(start_script);

  if (status) {
    fprintf(stderr, "Couldn't load file: %s\n", lua_tostring(L, -1));
    exit(1);
  }

  lua_pushstring(L, (char *)app_root);
  lua_newtable(L);
  for(i = 0; i < argc; ++i) {
    lua_pushnumber(L, i + 1);
    lua_pushstring(L, argv[i]);
    lua_settable(L, -3);
  }
  status = lua_pcall(L, 2, 0, 0);
  if (status) {
      g_critical("Failed to run script: %s\n", lua_tostring(L, -1));
      exit(1);
  }
}

static gchar *get_app_root(const gchar *invocation_path)
{
  gchar *path;
  GFile *root, *app, *parent, *share_dir;

  app = g_file_new_for_path(invocation_path);
  parent = g_file_get_parent(app);
  root = g_file_get_parent(parent);
  share_dir = g_file_get_child(root, "share/howl");

  if (g_file_query_exists(share_dir, NULL)) {
    g_object_unref(root);
    root = share_dir;
  }

  path = g_file_get_path(root);
  g_object_unref(app);
  g_object_unref(parent);
  g_object_unref(root);
  return path;
}

static lua_State *open_lua_state(const gchar *app_root)
{
  lua_State *l = luaL_newstate();
  luaL_openlibs(l);

  /* lpeg */
  luaopen_lpeg(l);
  lua_pop(l, 1);

  return l;
}

int main(int argc, char *argv[])
{
  if (argc >= 2 && strcmp(argv[1], "--compile") == 0) {
#if !GLIB_CHECK_VERSION(2, 36, 0)
    g_type_init();
#endif
  }
  else {
    gtk_init(&argc, &argv);
  }
  gchar *app_root = get_app_root(argv[0]);
  lua_State *L = open_lua_state(app_root);
  lua_run(argc, argv, app_root, L);
  lua_close(L);
  g_free(app_root);
  scintilla_release_resources();
  return 0;
}
