/* Copyright 2014 Nils Nordman <nino at nordman.org> */
/* License: MIT (see LICENSE) */

#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

int process_exited_normally(int status) { return WIFEXITED(status);  }
int process_exit_status(int status) { return WEXITSTATUS(status);  }
int process_was_signalled(int status) { return WIFSIGNALED(status);  }
int process_get_term_sig(int status) { return WTERMSIG(status);  }

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
int sig_STKFLT = SIGSTKFLT;
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
int sig_POLL = SIGPOLL;
int sig_PWR = SIGPWR;
int sig_SYS = SIGSYS;
