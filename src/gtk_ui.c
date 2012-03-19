#include "vilu.h"
#include <gtk/gtk.h>

#include <Scintilla.h>
#include <SciLexer.h>
#include <ScintillaWidget.h>

static GtkApplication *app;

void on_activate(GtkWidget *widget, gpointer callback_data );

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
  GtkWidget *editor;

  window = (GtkWidget *)ptr;
  editor = GTK_WIDGET(scintilla_new());
  gtk_container_add (GTK_CONTAINER (window), editor);
  gtk_widget_show_all (editor);
  return (void *)editor;
}

const char *load_file(const char *path) {
  FILE *f;
  char *buf;
  buf  = (char *)malloc(10000);
  f = fopen(path, "r");
  fread(buf, 10000, 1, f);
  fclose(f);
  return buf;
}

void on_activate(GtkWidget *app, gpointer callback)
{
//  GtkWidget *window;
//  GtkWidget *editor;
//
//  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
//  gtk_application_add_window (GTK_APPLICATION(app), GTK_WINDOW (window));
//  gtk_window_set_default_size(GTK_WINDOW(window), 1024, 768);
//
//  editor = GTK_WIDGET(scintilla_new());
//  gtk_container_add (GTK_CONTAINER (window), editor);
//
//  gtk_widget_show_all (window);
//
//  const char * file = load_file("/tmp/test.rb");
//  scintilla_send_message(editor, SCI_SETLEXER, SCLEX_RUBY, NULL);
//  printf("lexer: %i\n", scintilla_send_message(editor, SCI_GETLEXER, 0, 0));
//  scintilla_send_message(editor, SCI_SETTEXT, 0, file);
//  scintilla_send_message(editor, SCI_STYLESETBACK, 32, 0x880000);
//  scintilla_send_message(editor, SCI_STYLESETFORE, 32, 0x00bbbb);
//  scintilla_send_message(editor, SCI_STYLECLEARALL, 0, 0);
  ((ViluCallback)callback)();
}

int ui_run(int argc, char *argv[], lua_State *L, ViluCallback callback)
{
  app = gtk_application_new("org.nordman.vilu", 0);
  g_signal_connect( app, "activate", G_CALLBACK(on_activate), callback);
  return g_application_run (G_APPLICATION (app), argc, argv);
}
