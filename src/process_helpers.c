/* Copyright 2012-2015 The Howl Developers */
/* License: MIT (see LICENSE.md at the top-level directory of the distribution) */

#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>

int process_exited_normally(int status) { return WIFEXITED(status);  }
int process_exit_status(int status) { return WEXITSTATUS(status);  }
int process_was_signalled(int status) { return WIFSIGNALED(status);  }
int process_get_term_sig(int status) { return WTERMSIG(status);  }

/* Run in the child between fork and exec. A new session makes the child the
 * leader of its own process group, so that it can be signalled along with
 * anything it starts. A session rather than just a group since a background
 * group on Howl's terminal would be stopped when reading from /dev/tty. */
void process_child_setup(void *data) { setsid(); }

int sig_HUP = SIGHUP;
int sig_INT = SIGINT;
int sig_QUIT = SIGQUIT;
int sig_ILL = SIGILL;
int sig_TRAP = SIGTRAP;
int sig_ABRT = SIGABRT;
int sig_BUS = SIGBUS;
int sig_FPE = SIGFPE;
int sig_KILL = SIGKILL;
int sig_USR1 = SIGUSR1;
int sig_SEGV = SIGSEGV;
int sig_USR2 = SIGUSR2;
int sig_PIPE = SIGPIPE;
int sig_ALRM = SIGALRM;
int sig_TERM = SIGTERM;
int sig_CHLD = SIGCHLD;
int sig_CONT = SIGCONT;
int sig_STOP = SIGSTOP;
int sig_TSTP = SIGTSTP;
int sig_TTIN = SIGTTIN;
int sig_TTOU = SIGTTOU;
int sig_URG = SIGURG;
int sig_XCPU = SIGXCPU;
int sig_XFSZ = SIGXFSZ;
int sig_VTALRM = SIGVTALRM;
int sig_PROF = SIGPROF;
int sig_WINCH = SIGWINCH;
int sig_SYS = SIGSYS;
