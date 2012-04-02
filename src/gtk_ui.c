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

static void set_bfield(lua_State *L, const gchar *name, gboolean value)
{
  lua_pushboolean(L, value);
  lua_setfield(L, -2, name);
}

static void set_nfield(lua_State *L, const gchar *name, lua_Number value)
{
  lua_pushnumber(L, value);
  lua_setfield(L, -2, name);
}

static void set_sfield(lua_State *L, const gchar *name, const gchar *value)
{
  lua_pushstring(L, value);
  lua_setfield(L, -2, name);
}

static int setup_for_event(lua_State *l, gchar *name)
{
  int top = lua_gettop(l);
  lua_getglobal(l, "event");
  if (lua_istable(l, -1)) {
    lua_getfield(l, -1, "emit");
    if (lua_isfunction(l, -1)) {
      lua_pushstring(l, name);
      lua_newtable(l);
      return top;
    }
  }
  g_critical("Failed to lookup event.emit: not configured");
  lua_settop(l, top);
  return -1;
}

static gboolean emit_event(lua_State *l, int top)
{
  gboolean halt = FALSE;

  if (lua_pcall(L, 2, 1, 0) == 0)
    halt = lua_toboolean(L, -1);
  else
    g_critical("Failed to invoke event.emit: %s", lua_tostring(L, -1));

  lua_settop(L, top);
  return halt;
 }

static void explain_key_code(lua_State *l, int code)
{
  gchar *key_name = gdk_keyval_name(code);
  guint32 unicode_char = gdk_keyval_to_unicode(code);
  gchar utf8[6];
  gint nr_utf8 = 0;
  gchar *cptr;

  if (unicode_char)
    nr_utf8 = g_unichar_to_utf8(unicode_char, utf8);

  set_nfield(l, "key_code", code);

  cptr = g_ascii_strdown(key_name, -1);
  set_sfield(l, "key_name", cptr);
  g_free(cptr);

  if (nr_utf8 > 0) {
    lua_pushlstring(l, utf8, nr_utf8);
    lua_setfield(l, -2, "character");
  }
}

static gboolean on_sci_notify(GtkWidget *widget, gint ctrl_id, struct SCNotification *n, gpointer nil)
{
  int code = n->nmhdr.code;
  int mods = n->modifiers;
  int top = setup_for_event(L, "sci");

  if (top < 0)
    return FALSE;

    set_nfield(L, "code", code);

  if (code == SCN_PAINTED) {} /* fires a lot */
  else if (code == SCN_UPDATEUI) {
    set_nfield(L, "updated", n->updated);
  }
  else {
    /* not applicable for all, but for too many to special case */
    set_nfield(L, "position", n->position);

    if (code == SCN_CHARADDED || code == SCN_KEY || code == SCN_DOUBLECLICK ||
        code == SCN_HOTSPOTCLICK || code == SCN_HOTSPOTDOUBLECLICK ||
        code == SCN_HOTSPOTRELEASECLICK || code == SCN_INDICATORCLICK ||
        code == SCN_INDICATORRELEASE || code == SCN_MARGINCLICK) {

      set_bfield(L, "shift", mods & SCMOD_SHIFT);
      set_bfield(L, "control", mods & SCMOD_CTRL);
      set_bfield(L, "alt", mods & SCMOD_ALT);
      set_bfield(L, "super", mods & SCMOD_SUPER);
      set_bfield(L, "meta", mods & SCMOD_META);
    }

    if (code == SCN_MODIFIED || code == SCN_DOUBLECLICK) {
      set_nfield(L, "line", n->line);
    }

    if (code == SCN_MODIFIED || code == SCN_USERLISTSELECTION ||
        code == SCN_AUTOCSELECTION || code == SCN_URIDROPPED) {
      set_sfield(L, "text", n->text);
    }

    if (code == SCN_CHARADDED || code == SCN_KEY) {
      explain_key_code(L, n->ch);
    }
    else if (code == SCN_MODIFIED) {
      set_nfield(L, "type", n->modificationType);
      set_nfield(L, "length", n->length);
      set_nfield(L, "lines-added", n->linesAdded);
      set_nfield(L, "fold-level-now", n->foldLevelNow);
      set_nfield(L, "fold-level-previous", n->foldLevelPrev);
    }
    else if (code == SCN_USERLISTSELECTION) {
      set_nfield(L, "list-type", n->listType);
    }
    else if (code == SCN_MARGINCLICK) {
      set_nfield(L, "margin", n->margin);
    }
    else if (code == SCN_DWELLSTART || code == SCN_DWELLEND) {
      set_nfield(L, "x", n->x);
      set_nfield(L, "y", n->y);
    }
  }
  return emit_event(L, top);
}

static gboolean on_sci_key_press(GtkWidget *widget, GdkEventKey *key, gpointer nil)
{
  int top = setup_for_event(L, "key-press");

  if (top < 0)
    return FALSE;

  explain_key_code(L, key->keyval);
  set_bfield(L, "shift", key->state & GDK_SHIFT_MASK);
  set_bfield(L, "control", key->state & GDK_CONTROL_MASK);
  set_bfield(L, "alt", key->state & GDK_MOD1_MASK);
  set_bfield(L, "super", key->state & GDK_SUPER_MASK);
  set_bfield(L, "meta", key->state & GDK_META_MASK);

  return emit_event(L, top);
}

void * window_new()
{
  GtkWidget *window;
  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
  gtk_widget_show_all(window);
  g_signal_connect(window, "destroy", G_CALLBACK(on_window_closed), NULL);
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
  g_signal_connect(sci, "key-press-event", G_CALLBACK(on_sci_key_press), NULL);
  g_signal_connect(sci, SCINTILLA_NOTIFY, G_CALLBACK(on_sci_notify), NULL);
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
