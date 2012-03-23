#include "vilu.h"

#include <gtk/gtk.h>

#include <Scintilla.h>
#include <ScintillaWidget.h>

static GtkApplication *app;
static gchar *lexer_dir;

void on_activate(GtkWidget *widget, gpointer callback_data );

const char *load_file(const char *path) {
  FILE *f;
  char *buf;
  buf  = (char *)malloc(10000);
  f = fopen(path, "r");
  fread(buf, 10000, 1, f);
  fclose(f);
  return buf;
}

static void initialize_scintilla(ScintillaObject *sci)
{
  scintilla_send_message(sci, SCI_STYLESETBACK, 32, 0x880000);
  scintilla_send_message(sci, SCI_STYLESETFORE, 32, 0x00bbbb);
  scintilla_send_message(sci, SCI_STYLECLEARALL, 0, 0);
  scintilla_send_message(sci, SCI_SETCARETFORE, 0xffffff, 0);
  scintilla_send_message(sci, SCI_GRABFOCUS, 0, 0);

  scintilla_send_message(sci, SCI_SETLEXERLANGUAGE, 0, "lpeg");
  scintilla_send_message(sci, SCI_SETPROPERTY, "lexer.lpeg.home", lexer_dir);
  scintilla_send_message(sci, SCI_SETPROPERTY, "lexer.lpeg.color.theme", "dark");
}

void * _ui_window_new()
{
  GtkWidget *window;
  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_application_add_window (GTK_APPLICATION(app), GTK_WINDOW (window));
  gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
  gtk_widget_show_all (window);
  return (void *)window;
}

void * _ui_view_new(void *ptr)
{
  GtkWidget *window;
  GtkWidget *sci;

  window = (GtkWidget *)ptr;
  sci = GTK_WIDGET(scintilla_new());
  gtk_container_add (GTK_CONTAINER (window), sci);
  gtk_widget_show_all(sci);

  initialize_scintilla((ScintillaObject *)sci);

  SciFnDirect pSciMsg = (SciFnDirect)scintilla_send_message(sci, SCI_GETDIRECTFUNCTION, 0, 0);
  sptr_t dp = (sptr_t)scintilla_send_message(sci, SCI_GETDIRECTPOINTER, 0, 0);
  scintilla_send_message(sci, SCI_PRIVATELEXERCALL, SCI_GETDIRECTFUNCTION, pSciMsg);
  scintilla_send_message(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, dp);
  scintilla_send_message(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, "ruby");
  const char * file = load_file("/tmp/test.rb");
  scintilla_send_message(sci, SCI_SETTEXT, 0, file);

  return (void *)sci;
}

void on_activate(GtkWidget *app, gpointer callback)
{
  ((ViluCallback)callback)();
}

int ui_run(int argc, char *argv[], lua_State *L, ViluCallback callback)
{
  int status;

  lexer_dir = g_build_filename(app_root, "..", "lexers", NULL);
  app = gtk_application_new("org.nordman.vilu", 0);
  g_signal_connect( app, "activate", G_CALLBACK(on_activate), callback);
  status = g_application_run (G_APPLICATION (app), argc, argv);
  g_free(lexer_dir);
  return status;
}
