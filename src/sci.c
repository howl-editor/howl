/* Copyright 2012-2013 Nils Nordman <nino at nordman.org> */
/* License: MIT (see LICENSE) */

#include "main.h"

#include <gtk/gtk.h>
#include <Scintilla.h>
#include <ScintillaWidget.h>

#define ss(sci, number, arg1, arg2) \
  scintilla_send_message(sci, number, (uptr_t)(arg1), (sptr_t)(arg2))

intptr_t sci_send(void *sci, int message, intptr_t wParam, intptr_t lParam);

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
  if (value == NULL) return;
  lua_pushstring(L, value);
  lua_setfield(L, -2, name);
}

static void set_sfield_l(lua_State *L, const gchar *name, const gchar *value, size_t len)
{
  if (value == NULL || len == 0) return;
  lua_pushlstring(L, value, len);
  lua_setfield(L, -2, name);
}

static int setup_for_event(lua_State *l, GtkWidget *sci, gchar *name)
{
  int top = lua_gettop(l);
  lua_getglobal(l, "howl");
  if (lua_istable(l, -1)) {
    lua_getfield(l, -1, "Scintilla");
    if (lua_istable(l, -1)) {
      lua_getfield(l, -1, "dispatch");
      if (lua_isfunction(l, -1)) {
        lua_pushlightuserdata(l, sci);
        lua_pushstring(l, name);
        return top;
      }
    }
  }
  g_critical("Failed to lookup howl.Scintilla.dispatch: not configured");
  lua_settop(l, top);
  return -1;
}

static gboolean emit_event(lua_State *L, int nr_params, int top)
{
  gboolean halt = FALSE;

  if (lua_pcall(L, nr_params + 2, 1, 0) == 0)
    halt = lua_toboolean(L, -1);
  else
    g_critical("Failed to invoke howl.Scintilla.dispatch: %s", lua_tostring(L, -1));

  lua_settop(L, top);
  return halt;
 }

static void explain_key_code(lua_State *l, int code)
{
  int effective_code = code == 10 ? GDK_KEY_Return : code;
  gchar *key_name = gdk_keyval_name(effective_code);
  guint32 unicode_char = gdk_keyval_to_unicode(code);
  gchar utf8[6];
  gint nr_utf8 = 0;
  gchar *cptr;

  if (unicode_char)
    nr_utf8 = g_unichar_to_utf8(unicode_char, utf8);

  set_nfield(l, "key_code", code);

  if (key_name != NULL) {
    cptr = g_ascii_strdown(key_name, -1);
    set_sfield(l, "key_name", cptr);
    g_free(cptr);
  }

  if (nr_utf8 > 0) {
    set_sfield_l(l, "character", utf8, nr_utf8);
  }
}

static gboolean on_sci_notify(GtkWidget *widget, gint ctrl_id, struct SCNotification *n, lua_State *L)
{
  int code = n->nmhdr.code;
  int mods = n->modifiers;
  int top = setup_for_event(L, widget, "sci");

  if (top < 0)
    return FALSE;

  lua_newtable(L);
  set_nfield(L, "code", code);

  if (code == SCN_PAINTED) {
    /* fires a lot, ignore for now */
    lua_settop(L, top);
    return FALSE;
  }
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
      set_sfield_l(L, "text", n->text, n->length);
    }

    if (code == SCN_CHARADDED || code == SCN_KEY) {
      explain_key_code(L, n->ch);
    }
    else if (code == SCN_MODIFIED) {
      set_nfield(L, "type", n->modificationType);
      set_nfield(L, "length", n->length);
      set_nfield(L, "lines_affected", n->linesAdded);
      set_nfield(L, "fold_level_now", n->foldLevelNow);
      set_nfield(L, "fold_level_previous", n->foldLevelPrev);
      set_nfield(L, "token", n->token);
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
  return emit_event(L, 1, top);
}

static gboolean on_sci_key_press(GtkWidget *widget, GdkEventKey *key, lua_State *L)
{
  int top = setup_for_event(L, widget, "key-press");

  if (top < 0)
    return FALSE;

  lua_newtable(L);
  explain_key_code(L, key->keyval);
  set_bfield(L, "shift", key->state & GDK_SHIFT_MASK);
  set_bfield(L, "control", key->state & GDK_CONTROL_MASK);
  set_bfield(L, "alt", key->state & GDK_MOD1_MASK);
  set_bfield(L, "super", key->state & GDK_SUPER_MASK);
  set_bfield(L, "meta", key->state & GDK_META_MASK);

  return emit_event(L, 1, top);
}

static int sci_new(lua_State *L)
{
  GtkWidget *sci = scintilla_new();
  g_signal_connect(sci, "key-press-event", G_CALLBACK(on_sci_key_press), L);
  g_signal_connect(sci, SCINTILLA_NOTIFY, G_CALLBACK(on_sci_notify), L);
  lua_pushlightuserdata(L, sci);
  return 1;
}

intptr_t sci_send(void *sci, int message, intptr_t wParam, intptr_t lParam) {
  return scintilla_send_message((ScintillaObject *)sci, message, wParam, lParam);
}

static struct luaL_Reg sci_reg[] = {
  {"new", sci_new},
  {NULL, NULL}
};

void sci_init(lua_State *L, const gchar *app_root)
{
  lua_pushstring(L, "sci");
  lua_newtable(L);
  luaL_register(L, NULL, sci_reg);
  lua_settable(L, -3);
}

void sci_close()
{
  scintilla_release_resources();
}
