;Copyright (C) 2001 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;Read LICENSE file for full copyright information (GNU GPL)
;
; file          : errorno.inc
; comment       : derived from linux-2.4.1/include/asm-i386/errorno.h

%ifndef __ERRNO_INC
%define __ERRNO_INC

%assign EPERM            1      ; Operation not permitted
%assign ENOENT           2      ; No such file or directory
%assign ESRCH            3      ; No such process
%assign EINTR            4      ; Interrupted system call
%assign EIO              5      ; I/O error
%assign ENXIO            6      ; No such device or address
%assign E2BIG            7      ; Arg list too long
%assign ENOEXEC          8      ; Exec format error
%assign EBADF            9      ; Bad file number
%assign ECHILD          10      ; No child processes
%assign EAGAIN          11      ; Try again
%assign ENOMEM          12      ; Out of memory
%assign EACCES          13      ; Permission denied
%assign EFAULT          14      ; Bad address
%assign ENOTBLK         15      ; Block device required
%assign EBUSY           16      ; Device or resource busy
%assign EEXIST          17      ; File exists
%assign EXDEV           18      ; Cross-device link
%assign ENODEV          19      ; No such device
%assign ENOTDIR         20      ; Not a directory
%assign EISDIR          21      ; Is a directory
%assign EINVAL          22      ; Invalid argument
%assign ENFILE          23      ; File table overflow
%assign EMFILE          24      ; Too many open files
%assign ENOTTY          25      ; Not a typewriter
%assign ETXTBSY         26      ; Text file busy
%assign EFBIG           27      ; File too large
%assign ENOSPC          28      ; No space left on device
%assign ESPIPE          29      ; Illegal seek
%assign EROFS           30      ; Read-only file system
%assign EMLINK          31      ; Too many links
%assign EPIPE           32      ; Broken pipe
%assign EDOM            33      ; Math argument out of domain of func
%assign ERANGE          34      ; Math result not representable
%assign EDEADLK         35      ; Resource deadlock would occur
%assign ENAMETOOLONG    36      ; File name too long
%assign ENOLCK          37      ; No record locks available
%assign ENOSYS          38      ; Function not implemented
%assign ENOTEMPTY       39      ; Directory not empty
%assign ELOOP           40      ; Too many symbolic links encountered
%assign EWOULDBLOCK     EAGAIN  ; Operation would block
%assign ENOMSG          42      ; No message of desired type
%assign EIDRM           43      ; Identifier removed
%assign ECHRNG          44      ; Channel number out of range
%assign EL2NSYNC        45      ; Level 2 not synchronized
%assign EL3HLT          46      ; Level 3 halted
%assign EL3RST          47      ; Level 3 reset
%assign ELNRNG          48      ; Link number out of range
%assign EUNATCH         49      ; Protocol driver not attached
%assign ENOCSI          50      ; No CSI structure available
%assign EL2HLT          51      ; Level 2 halted
%assign EBADE           52      ; Invalid exchange
%assign EBADR           53      ; Invalid request descriptor
%assign EXFULL          54      ; Exchange full
%assign ENOANO          55      ; No anode
%assign EBADRQC         56      ; Invalid request code
%assign EBADSLT         57      ; Invalid slot
%assign EDEADLOCK       EDEADLK
%assign EBFONT          59      ; Bad font file format
%assign ENOSTR          60      ; Device not a stream
%assign ENODATA         61      ; No data available
%assign ETIME           62      ; Timer expired
%assign ENOSR           63      ; Out of streams resources
%assign ENONET          64      ; Machine is not on the network
%assign ENOPKG          65      ; Package not installed
%assign EREMOTE         66      ; Object is remote
%assign ENOLINK         67      ; Link has been severed
%assign EADV            68      ; Advertise error
%assign ESRMNT          69      ; Srmount error
%assign ECOMM           70      ; Communication error on send
%assign EPROTO          71      ; Protocol error
%assign EMULTIHOP       72      ; Multihop attempted
%assign EDOTDOT         73      ; RFS specific error
%assign EBADMSG         74      ; Not a data message
%assign EOVERFLOW       75      ; Value too large for defined data type
%assign ENOTUNIQ        76      ; Name not unique on network
%assign EBADFD          77      ; File descriptor in bad state
%assign EREMCHG         78      ; Remote address changed
%assign ELIBACC         79      ; Can not access a needed shared library
%assign ELIBBAD         80      ; Accessing a corrupted shared library
%assign ELIBSCN         81      ; .lib section in a.out corrupted
%assign ELIBMAX         82      ; Attempting to link in too many shared libraries
%assign ELIBEXEC        83      ; Cannot exec a shared library directly
%assign EILSEQ          84      ; Illegal byte sequence
%assign ERESTART        85      ; Interrupted system call should be restarted
%assign ESTRPIPE        86      ; Streams pipe error
%assign EUSERS          87      ; Too many users
%assign ENOTSOCK        88      ; Socket operation on non-socket
%assign EDESTADDRREQ    89      ; Destination address required
%assign EMSGSIZE        90      ; Message too long
%assign EPROTOTYPE      91      ; Protocol wrong type for socket
%assign ENOPROTOOPT     92      ; Protocol not available
%assign EPROTONOSUPPORT 93      ; Protocol not supported
%assign ESOCKTNOSUPPORT 94      ; Socket type not supported
%assign EOPNOTSUPP      95      ; Operation not supported on transport endpoint

%assign EPFNOSUPPORT    96      ; Protocol family not supported
%assign EAFNOSUPPORT    97      ; Address family not supported by protocol
%assign EADDRINUSE      98      ; Address already in use
%assign EADDRNOTAVAIL   99      ; Cannot assign requested address
%assign ENETDOWN        100     ; Network is down
%assign ENETUNREACH     101     ; Network is unreachable
%assign ENETRESET       102     ; Network dropped connection because of reset
%assign ECONNABORTED    103     ; Software caused connection abort
%assign ECONNRESET      104     ; Connection reset by peer
%assign ENOBUFS         105     ; No buffer space available
%assign EISCONN         106     ; Transport endpoint is already connected
%assign ENOTCONN        107     ; Transport endpoint is not connected
%assign ESHUTDOWN       108     ; Cannot send after transport endpoint shutdown
%assign ETOOMANYREFS    109     ; Too many references: cannot splice
%assign ETIMEDOUT       110     ; Connection timed out
%assign ECONNREFUSED    111     ; Connection refused
%assign EHOSTDOWN       112     ; Host is down
%assign EHOSTUNREACH    113     ; No route to host
%assign EALREADY        114     ; Operation already in progress
%assign EINPROGRESS     115     ; Operation now in progress
%assign ESTALE          116     ; Stale NFS file handle
%assign EUCLEAN         117     ; Structure needs cleaning
%assign ENOTNAM         118     ; Not a XENIX named type file
%assign ENAVAIL         119     ; No XENIX semaphores available
%assign EISNAM          120     ; Is a named type file
%assign EREMOTEIO       121     ; Remote I/O error
%assign EDQUOT          122     ; Quota exceeded
%assign ENOMEDIUM       123     ; No medium found
%assign EMEDIUMTYPE     124     ; Wrong medium type
%assign EHASHCOLLISION  125     ; Number of hash collisons exceeds maximum generation counter value.

%endif
