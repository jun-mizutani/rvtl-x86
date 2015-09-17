;=========================================================================
; file : signal.inc
;=========================================================================
%ifndef __SIGNAL_INC
%define __SIGNAL_INC

%assign NSIG        32

%assign SIGHUP       1
%assign SIGINT       2
%assign SIGQUIT      3
%assign SIGILL       4
%assign SIGTRAP      5
%assign SIGABRT      6
%assign SIGIOT       6
%assign SIGBUS       7
%assign SIGFPE       8
%assign SIGKILL      9
%assign SIGUSR1     10
%assign SIGSEGV     11
%assign SIGUSR2     12
%assign SIGPIPE     13
%assign SIGALRM     14
%assign SIGTERM     15
%assign SIGSTKFLT   16
%assign SIGCHLD     17
%assign SIGCONT     18
%assign SIGSTOP     19
%assign SIGTSTP     20
%assign SIGTTIN     21
%assign SIGTTOU     22
%assign SIGURG      23
%assign SIGXCPU     24
%assign SIGXFSZ     25
%assign SIGVTALRM   26
%assign SIGPROF     27
%assign SIGWINCH    28
%assign SIGIO       29
%assign SIGPOLL     SIGIO
;
%assign SIGLOST     29

%assign SIGPWR      30
%assign SIGUNUSED   31

; These should not be considered constants from userland.
%assign SIGRTMIN    32
%assign SIGRTMAX    31  ; (NSIG-1)

%assign SA_NOCLDSTOP    0x00000001
%assign SA_NOCLDWAIT    0x00000002 ; not supported yet
%assign SA_SIGINFO      0x00000004
%assign SA_ONSTACK      0x08000000
%assign SA_RESTART      0x10000000
%assign SA_NODEFER      0x40000000
%assign SA_RESETHAND    0x80000000

%assign SA_NOMASK       SA_NODEFER
%assign SA_ONESHOT      SA_RESETHAND
%assign SA_INTERRUPT    0x20000000 ; dummy -- ignored

%assign SA_RESTORER     0x04000000

; * sigaltstack controls

%assign SS_ONSTACK  1
%assign SS_DISABLE  2

%assign MINSIGSTKSZ 2048
%assign SIGSTKSZ    8192

%assign SIG_BLOCK       0   ; for blocking signals
%assign SIG_UNBLOCK     1   ; for unblocking signals
%assign SIG_SETMASK     2   ; for setting the signal mask

%assign SIG_DFL         0   ; default signal handling
%assign SIG_IGN         1   ; ignore signal
%assign SIG_ERR         -1  ; error return from signal

struc sigaltstack
    .ss_sp          resd    1;
    .ss_flags       resd    1;
    .ss_size        resd    1;
endstruc

struc sigaction
    .sighandler     resd    1
    .sa_mask        resd    1
    .sa_flags       resd    1
    .sa_restorer    resd    1
endstruc

%endif
