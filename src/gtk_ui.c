#include "vilu.h"

#include <gtk/gtk.h>

#include <Scintilla.h>
#include <ScintillaWidget.h>

static gchar *lexer_dir;
static int window_count = 0;

#define ss(sci, number, arg1, arg2) \
  scintilla_send_message(sci, number, (uptr_t)(arg1), (sptr_t)(arg2))

static void initialize_scintilla(ScintillaObject *sci)
{
  ss(sci, SCI_STYLESETBACK, 32, 0x880000);
  ss(sci, SCI_STYLESETFORE, 32, 0x00bbbb);
  ss(sci, SCI_STYLECLEARALL, 0, 0);
  ss(sci, SCI_SETCARETFORE, 0xffffff, 0);

  ss(sci, SCI_SETLEXERLANGUAGE, 0, "lpeg");
  ss(sci, SCI_SETPROPERTY, "lexer.lpeg.home", lexer_dir);
}

static void on_window_closed(GtkWidget *widget, gpointer data)
{
  if (--window_count == 0)
    gtk_main_quit();
}

static void set_key_modifier(lua_State *L, gchar *name, guint state, guint mask)
{
  lua_pushboolean(L, state & mask);
  lua_setfield(L, -2, name);
}

static gboolean on_key_press(GtkWidget *widget, GdkEvent *event, gpointer nil)
{
  int top = lua_gettop(L);
  GdkEventKey *key = (GdkEventKey *)event;
  gchar * key_name = gdk_keyval_name(key->keyval);
  guint32 unicode_char = gdk_keyval_to_unicode(key->keyval);
  gchar utf8[6];
  gint nr_utf8 = 0;
  gchar *cptr;

  if (unicode_char)
    nr_utf8 = g_unichar_to_utf8(unicode_char, utf8);

  lua_getglobal(L, "event");
  if (lua_istable(L, -1)) {
    lua_getfield(L, -1, "emit");
    if (lua_isfunction(L, -1)) {
      lua_pushstring(L, "key-press");
      lua_newtable(L);

      lua_pushnumber(L, key->keyval);
      lua_setfield(L, -2, "code");

      cptr = g_ascii_strdown(key_name, -1);
      lua_pushstring(L, cptr);
      g_free(cptr);
      lua_setfield(L, -2, "name");

      if (nr_utf8 > 0) {
        lua_pushlstring(L, utf8, nr_utf8);
        lua_setfield(L, -2, "utf8_string");
      }

      set_key_modifier(L, "control", key->state, GDK_CONTROL_MASK);
      set_key_modifier(L, "shift", key->state, GDK_SHIFT_MASK);
      set_key_modifier(L, "super", key->state, GDK_SUPER_MASK);
      set_key_modifier(L, "hyper", key->state, GDK_HYPER_MASK);
      set_key_modifier(L, "meta", key->state, GDK_META_MASK);

      if (lua_pcall(L, 2, 1, 0) == 0) {
        gboolean halt = lua_toboolean(L, -1);
        lua_settop(L, top);
        return halt;
      }
      else {
        g_critical("Failed to invoke event.emit: %s", lua_tostring(L, -1));
      }
    }
  }
  else {
    g_critical("Failed to invoke event.emit: not configured");
  }

  lua_settop(L, top);
  return FALSE;
}

void * window_new()
{
  GtkWidget *window;
  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
  gtk_widget_show_all(window);
  g_signal_connect (window, "destroy", G_CALLBACK(on_window_closed), NULL);
  window_count++;
  return (void *)window;
}

void * text_view_new(void *ptr)
{
  GtkWidget *window;
  GtkWidget *sci;

  window = (GtkWidget *)ptr;
  sci = GTK_WIDGET(scintilla_new());
  gtk_container_add (GTK_CONTAINER (window), sci);
  g_signal_connect(sci, "key-press-event", G_CALLBACK(on_key_press), NULL);
  gtk_widget_show_all(sci);

  initialize_scintilla((ScintillaObject *)sci);
  return (void *)sci;
}

intptr_t text_view_sci(void *view, int message, intptr_t wParam, intptr_t lParam) {
  return scintilla_send_message((ScintillaObject *)view, message, wParam, lParam);
}

int ui_run(int argc, char *argv[], lua_State *L, ViluCallback callback)
{
  lexer_dir = g_build_filename(app_root, "lexers", NULL);
  gtk_init(&argc, &argv);
  callback();
  gtk_main();
  g_free(lexer_dir);
  scintilla_release_resources();
  return 0;
}
