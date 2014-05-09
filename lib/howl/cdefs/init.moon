-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'

ffi.cdef [[
void *malloc(size_t size);
void free(void *ptr);
int strncmp(const char *s1, const char *s2, size_t n);

typedef int pid_t;
int kill(pid_t pid, int sig);

/* process helpers */
int process_exited_normally(int status);
int process_exit_status(int status);
int process_was_signalled(int status) { return WIFSIGNALED(status);  }
int process_get_term_sig(int status) { return WTERMSIG(status);  }

int sig_HUP;
int sig_INT;
int sig_QUIT;
int sig_ILL;
int sig_TRAP;
int sig_ABRT;
int sig_BUS;
int sig_FPE;
int sig_KILL;
int sig_USR1;
int sig_SEGV;
int sig_USR2;
int sig_PIPE;
int sig_ALRM;
int sig_TERM;
int sig_STKFLT;
int sig_CHLD;
int sig_CONT;
int sig_STOP;
int sig_TSTP;
int sig_TTIN;
int sig_TTOU;
int sig_URG;
int sig_XCPU;
int sig_XFSZ;
int sig_VTALRM;
int sig_PROF;
int sig_WINCH;
int sig_POLL;
int sig_PWR;
int sig_SYS;
]]

return {
  const_char_p: ffi.typeof 'const char *'
  char_p: ffi.typeof 'char *'
  char_arr: ffi.typeof 'char[?]'

  glib: require 'howl.cdefs.glib'
  gobject: require 'howl.cdefs.gobject'
}
