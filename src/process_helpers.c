/* Copyright 2012-2015 The Howl Developers */
/* License: MIT (see LICENSE.md at the top-level directory of the distribution) */

#include <sys/types.h>
#ifndef _WIN32
#include <sys/wait.h>
#else
#define WIFEXITED(w)    ((w) < 128)
#define WEXITSTATUS(w)	(w)
#define WIFSIGNALED(w)  ((w) >= 128)
#define WTERMSIG(w)     ((w) - 128)

#define	SIGHUP	1	/* hangup */
#define	SIGINT	2	/* interrupt */
#define	SIGQUIT	3	/* quit */
#define	SIGILL	4	/* illegal instruction (not reset when caught) */
#define	SIGTRAP	5	/* trace trap (not reset when caught) */
#define	SIGABRT 6	/* used by abort */
#define	SIGIOT	SIGABRT	/* synonym for SIGABRT on most systems */
#define	SIGEMT	7	/* EMT instruction */
#define	SIGFPE	8	/* floating point exception */
#define	SIGKILL	9	/* kill (cannot be caught or ignored) */
#define	SIGBUS	10	/* bus error */
#define	SIGSEGV	11	/* segmentation violation */
#define	SIGSYS	12	/* bad argument to system call */
#define	SIGPIPE	13	/* write on a pipe with no one to read it */
#define	SIGALRM	14	/* alarm clock */
#define	SIGTERM	15	/* software termination signal from kill */
#define	SIGURG	16	/* urgent condition on IO channel */
#define	SIGSTOP	17	/* sendable stop signal not from tty */
#define	SIGTSTP	18	/* stop signal from tty */
#define	SIGCONT	19	/* continue a stopped process */
#define	SIGCHLD	20	/* to parent on child stop or exit */
#define	SIGCLD	20	/* System V name for SIGCHLD */
#define	SIGTTIN	21	/* to readers pgrp upon background tty read */
#define	SIGTTOU	22	/* like TTIN for output if (tp->t_local&LTOSTOP) */
#define	SIGIO	23	/* input/output possible signal */
#define	SIGPOLL	SIGIO	/* System V name for SIGIO */
#define	SIGXCPU	24	/* exceeded CPU time limit */
#define	SIGXFSZ	25	/* exceeded file size limit */
#define	SIGVTALRM 26	/* virtual time alarm */
#define	SIGPROF	27	/* profiling time alarm */
#define	SIGWINCH 28	/* window changed */
#define	SIGLOST 29	/* resource lost (eg, record-lock lost) */
#define	SIGPWR  SIGLOST	/* power failure */
#define	SIGUSR1 30	/* user defined signal 1 */
#define	SIGUSR2 31	/* user defined signal 2 */
#endif
#include <signal.h>

int process_exited_normally(int status) { return WIFEXITED(status);  }
int process_exit_status(int status) { return WEXITSTATUS(status);  }
int process_was_signalled(int status) { return WIFSIGNALED(status); }
int process_get_term_sig(int status) { return WTERMSIG(status); }

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
