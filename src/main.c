/* Copyright 2012-2015 The Howl Developers */
/* License: MIT (see LICENSE.md at the top-level directory of the distribution) */

#include "main.h"
#include <gio/gio.h>
#include <string.h>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

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
  gchar *called_as = (g_file_test("/proc/self/exe", G_FILE_TEST_IS_SYMLINK)) ?
                      g_file_read_link("/proc/self/exe", NULL) :
                      g_strdup(invocation_path);

  /* Invoked from $PATH on non-linux system */
  if (strcmp(called_as, "howl") == 0) {
    g_free(called_as);
    called_as = g_strconcat(TOSTRING(HOWL_PREFIX), "/bin/howl", NULL);
  }

  gchar *path;
  GFile *root, *app, *parent, *share_dir;

  app = g_file_new_for_path(called_as);
  parent = g_file_get_parent(app);
  root = g_file_get_parent(parent);
  share_dir = g_file_get_child(root, "share/howl");

  if (g_file_query_exists(share_dir, NULL)) {
    g_object_unref(root);
    root = share_dir;
  }
  else {
    g_object_unref(share_dir);
  }

  path = g_file_get_path(root);
  g_free(called_as);
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

#include <glib-object.h>
GType howl_gobject_type_from_instance(gpointer instance) {
  return G_TYPE_FROM_INSTANCE(instance);
}

int main(int argc, char *argv[])
{
  if (argc >= 2 && strcmp(argv[1], "--compile") == 0) {
#if !GLIB_CHECK_VERSION(2, 36, 0)
    g_type_init();
#endif
  }
  else {
    gtk_init();
  }

  gchar *app_root = get_app_root(argv[0]);
  lua_State *L = open_lua_state(app_root);
  lua_run(argc, argv, app_root, L);
  lua_close(L);
  g_free(app_root);
  return 0;
}
