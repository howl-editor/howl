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
  return 0;
}
