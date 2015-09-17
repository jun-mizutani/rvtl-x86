;-------------------------------------------------------------------------
;  file : syserror.inc
;  2005/06/04
; Copyright (C) 2001-2005 Jun Mizutani <mizutani.jun@nifty.ne.jp>
; Read LICENSE file for full copyright information (GNU GPL)
;-------------------------------------------------------------------------

%include        "errno.inc"

%ifndef __SYSERR_INC
%define __SYSERR_INC

;==============================================================
section .text

SysCallError:
                push    eax
                push    ebx
                push    ecx
                push    edi
                or      eax, eax
                jns     .exit
                neg     eax
                mov     ebx, eax
                mov     ecx, num_sys_error
                shr     ecx, 3
                mov     edi, sys_error_tbl
        .loop:
                cmp     ebx, [edi]
                jne     .next
                mov     eax, [edi+4]
                call    OutAsciiZ
                call    NewLine
                jmp     short .exit
        .next:
                add     edi, 8
                loop    .loop
                neg     ebx
                mov     eax, ebx
                call    PrintHex8
                call    NewLine
    .exit:
                pop     edi
                pop     ecx
                pop     ebx
                pop     eax
                ret

;==============================================================
section .data

sys_error_tbl:
        dd  EPERM          ,    msg_EPERM
        dd  ENOENT         ,    msg_ENOENT
        dd  ESRCH          ,    msg_ESRCH
        dd  EINTR          ,    msg_EINTR
        dd  EIO            ,    msg_EIO
        dd  ENXIO          ,    msg_ENXIO
        dd  E2BIG          ,    msg_E2BIG
        dd  ENOEXEC        ,    msg_ENOEXEC
        dd  EBADF          ,    msg_EBADF
        dd  ECHILD         ,    msg_ECHILD
        dd  EAGAIN         ,    msg_EAGAIN
        dd  ENOMEM         ,    msg_ENOMEM
        dd  EACCES         ,    msg_EACCES
        dd  EFAULT         ,    msg_EFAULT
        dd  ENOTBLK        ,    msg_ENOTBLK
        dd  EBUSY          ,    msg_EBUSY
        dd  EEXIST         ,    msg_EEXIST
        dd  EXDEV          ,    msg_EXDEV
        dd  ENODEV         ,    msg_ENODEV
        dd  ENOTDIR        ,    msg_ENOTDIR
        dd  EISDIR         ,    msg_EISDIR
        dd  EINVAL         ,    msg_EINVAL
        dd  ENFILE         ,    msg_ENFILE
        dd  EMFILE         ,    msg_EMFILE
        dd  ENOTTY         ,    msg_ENOTTY
        dd  ETXTBSY        ,    msg_ETXTBSY
        dd  EFBIG          ,    msg_EFBIG
        dd  ENOSPC         ,    msg_ENOSPC
        dd  ESPIPE         ,    msg_ESPIPE
        dd  EROFS          ,    msg_EROFS
        dd  EMLINK         ,    msg_EMLINK
        dd  EPIPE          ,    msg_EPIPE
        dd  EDOM           ,    msg_EDOM
        dd  ERANGE         ,    msg_ERANGE
        dd  EDEADLK        ,    msg_EDEADLK
        dd  ENAMETOOLONG   ,    msg_ENAMETOOLONG
        dd  ENOLCK         ,    msg_ENOLCK
        dd  ENOSYS         ,    msg_ENOSYS
        dd  ENOTEMPTY      ,    msg_ENOTEMPTY
        dd  ELOOP          ,    msg_ELOOP
        dd  EWOULDBLOCK    ,    msg_EWOULDBLOCK
        dd  ENOMSG         ,    msg_ENOMSG
        dd  EIDRM          ,    msg_EIDRM
        dd  ECHRNG         ,    msg_ECHRNG
        dd  EL2NSYNC       ,    msg_EL2NSYNC
        dd  EL3HLT         ,    msg_EL3HLT
        dd  EL3RST         ,    msg_EL3RST
        dd  ELNRNG         ,    msg_ELNRNG
        dd  EUNATCH        ,    msg_EUNATCH
        dd  ENOCSI         ,    msg_ENOCSI
        dd  EL2HLT         ,    msg_EL2HLT
        dd  EBADE          ,    msg_EBADE
        dd  EBADR          ,    msg_EBADR
        dd  EXFULL         ,    msg_EXFULL
        dd  ENOANO         ,    msg_ENOANO
        dd  EBADRQC        ,    msg_EBADRQC
        dd  EBADSLT        ,    msg_EBADSLT
        dd  EDEADLOCK      ,    msg_EDEADLOCK
        dd  EBFONT         ,    msg_EBFONT
        dd  ENOSTR         ,    msg_ENOSTR
        dd  ENODATA        ,    msg_ENODATA
        dd  ETIME          ,    msg_ETIME
        dd  ENOSR          ,    msg_ENOSR
        dd  ENONET         ,    msg_ENONET
        dd  ENOPKG         ,    msg_ENOPKG
        dd  EREMOTE        ,    msg_EREMOTE
        dd  ENOLINK        ,    msg_ENOLINK
        dd  EADV           ,    msg_EADV
        dd  ESRMNT         ,    msg_ESRMNT
        dd  ECOMM          ,    msg_ECOMM
        dd  EPROTO         ,    msg_EPROTO
        dd  EMULTIHOP      ,    msg_EMULTIHOP
        dd  EDOTDOT        ,    msg_EDOTDOT
        dd  EBADMSG        ,    msg_EBADMSG
        dd  EOVERFLOW      ,    msg_EOVERFLOW
        dd  ENOTUNIQ       ,    msg_ENOTUNIQ
        dd  EBADFD         ,    msg_EBADFD
        dd  EREMCHG        ,    msg_EREMCHG
        dd  ELIBACC        ,    msg_ELIBACC
        dd  ELIBBAD        ,    msg_ELIBBAD
        dd  ELIBSCN        ,    msg_ELIBSCN
        dd  ELIBMAX        ,    msg_ELIBMAX
        dd  ELIBEXEC       ,    msg_ELIBEXEC
        dd  EILSEQ         ,    msg_EILSEQ
        dd  ERESTART       ,    msg_ERESTART
        dd  ESTRPIPE       ,    msg_ESTRPIPE
        dd  EUSERS         ,    msg_EUSERS
        dd  ENOTSOCK       ,    msg_ENOTSOCK
        dd  EDESTADDRREQ   ,    msg_EDESTADDRREQ
        dd  EMSGSIZE       ,    msg_EMSGSIZE
        dd  EPROTOTYPE     ,    msg_EPROTOTYPE
        dd  ENOPROTOOPT    ,    msg_ENOPROTOOPT
        dd  EPROTONOSUPPORT,    msg_EPROTONOSUPPORT
        dd  ESOCKTNOSUPPORT,    msg_ESOCKTNOSUPPORT
        dd  EOPNOTSUPP     ,    msg_EOPNOTSUPP
        dd  EPFNOSUPPORT   ,    msg_EPFNOSUPPORT
        dd  EAFNOSUPPORT   ,    msg_EAFNOSUPPORT
        dd  EADDRINUSE     ,    msg_EADDRINUSE
        dd  EADDRNOTAVAIL  ,    msg_EADDRNOTAVAIL
        dd  ENETDOWN       ,    msg_ENETDOWN
        dd  ENETUNREACH    ,    msg_ENETUNREACH
        dd  ENETRESET      ,    msg_ENETRESET
        dd  ECONNABORTED   ,    msg_ECONNABORTED
        dd  ECONNRESET     ,    msg_ECONNRESET
        dd  ENOBUFS        ,    msg_ENOBUFS
        dd  EISCONN        ,    msg_EISCONN
        dd  ENOTCONN       ,    msg_ENOTCONN
        dd  ESHUTDOWN      ,    msg_ESHUTDOWN
        dd  ETOOMANYREFS   ,    msg_ETOOMANYREFS
        dd  ETIMEDOUT      ,    msg_ETIMEDOUT
        dd  ECONNREFUSED   ,    msg_ECONNREFUSED
        dd  EHOSTDOWN      ,    msg_EHOSTDOWN
        dd  EHOSTUNREACH   ,    msg_EHOSTUNREACH
        dd  EALREADY       ,    msg_EALREADY
        dd  EINPROGRESS    ,    msg_EINPROGRESS
        dd  ESTALE         ,    msg_ESTALE
        dd  EUCLEAN        ,    msg_EUCLEAN
        dd  ENOTNAM        ,    msg_ENOTNAM
        dd  ENAVAIL        ,    msg_ENAVAIL
        dd  EISNAM         ,    msg_EISNAM
        dd  EREMOTEIO      ,    msg_EREMOTEIO
        dd  EDQUOT         ,    msg_EDQUOT
        dd  ENOMEDIUM      ,    msg_ENOMEDIUM
        dd  EMEDIUMTYPE    ,    msg_EMEDIUMTYPE
        dd  EHASHCOLLISION ,    msg_EHASHCOLLISION
num_sys_error   equ  $ - sys_error_tbl

msg_EPERM:           db "[EPERM] Operation not permitted",0
msg_ENOENT:          db "[ENOENT] No such file or directory",0
msg_ESRCH:           db "[ESRCH] No such process",0
msg_EINTR:           db "[EINTR] Interrupted system call",0
msg_EIO:             db "[EIO] I/O error",0
msg_ENXIO:           db "[ENXIO] No such device or address",0
msg_E2BIG:           db "[E2BIG] Arg list too long",0
msg_ENOEXEC:         db "[ENOEXEC] Exec format error",0
msg_EBADF:           db "[EBADF] Bad file number",0
msg_ECHILD:          db "[ECHILD] No child processes",0
msg_EAGAIN:          db "[EAGAIN] Try again",0
msg_ENOMEM:          db "[ENOMEM] Out of memory",0
msg_EACCES:          db "[EACCES] Permission denied",0
msg_EFAULT:          db "[EFAULT] Bad address",0
msg_ENOTBLK:         db "[ENOTBLK] Block device required",0
msg_EBUSY:           db "[EBUSY] Device or resource busy",0
msg_EEXIST:          db "[EEXIST] File exists",0
msg_EXDEV:           db "[EXDEV] Cross-device link",0
msg_ENODEV:          db "[ENODEV] No such device",0
msg_ENOTDIR:         db "[ENOTDIR] Not a directory",0
msg_EISDIR:          db "[EISDIR] Is a directory",0
msg_EINVAL:          db "[EINVAL] Invalid argument",0
msg_ENFILE:          db "[ENFILE] File table overflow",0
msg_EMFILE:          db "[EMFILE] Too many open files",0
msg_ENOTTY:          db "[ENOTTY] Not a typewriter",0
msg_ETXTBSY:         db "[ETXTBSY] Text file busy",0
msg_EFBIG:           db "[EFBIG] File too large",0
msg_ENOSPC:          db "[ENOSPC] No space left on device",0
msg_ESPIPE:          db "[ESPIPE] Illegal seek",0
msg_EROFS:           db "[EROFS] Read-only file system",0
msg_EMLINK:          db "[EMLINK] Too many links",0
msg_EPIPE:           db "[EPIPE] Broken pipe",0
msg_EDOM:            db "[EDOM] Math argument out of domain of func",0
msg_ERANGE:          db "[ERANGE] Math result not representable",0
msg_EDEADLK:         db "[EDEADLK] Resource deadlock would occur",0
msg_ENAMETOOLONG:    db "[ENAMETOOLONG] File name too long",0
msg_ENOLCK:          db "[ENOLCK] No record locks available",0
msg_ENOSYS:          db "[ENOSYS] Function not implemented",0
msg_ENOTEMPTY:       db "[ENOTEMPTY] Directory not empty",0
msg_ELOOP:           db "[ELOOP] Too many symbolic links encountered",0
msg_EWOULDBLOCK:     db "[EWOULDBLOCK] Operation would block",0
msg_ENOMSG:          db "[ENOMSG] No message of desired type",0
msg_EIDRM:           db "[EIDRM] Identifier removed",0
msg_ECHRNG:          db "[ECHRNG] Channel number out of range",0
msg_EL2NSYNC:        db "[EL2NSYNC] Level 2 not synchronized",0
msg_EL3HLT:          db "[EL3HLT] Level 3 halted",0
msg_EL3RST:          db "[EL3RST] Level 3 reset",0
msg_ELNRNG:          db "[ELNRNG] Link number out of range",0
msg_EUNATCH:         db "[EUNATCH] Protocol driver not attached",0
msg_ENOCSI:          db "[ENOCSI] No CSI structure available",0
msg_EL2HLT:          db "[EL2HLT] Level 2 halted",0
msg_EBADE:           db "[EBADE] Invalid exchange",0
msg_EBADR:           db "[EBADR] Invalid request descriptor",0
msg_EXFULL:          db "[EXFULL] Exchange full",0
msg_ENOANO:          db "[ENOANO] No anode",0
msg_EBADRQC:         db "[EBADRQC] Invalid request code",0
msg_EBADSLT:         db "[EBADSLT] Invalid slot",0
msg_EDEADLOCK:       db "[EDEADLOCK] Resource deadlock would occur",0
msg_EBFONT:          db "[EBFONT] Bad font file format",0
msg_ENOSTR:          db "[ENOSTR] Device not a stream",0
msg_ENODATA:         db "[ENODATA] No data available",0
msg_ETIME:           db "[ETIME] Timer expired",0
msg_ENOSR:           db "[ENOSR] Out of streams resources",0
msg_ENONET:          db "[ENONET] Machine is not on the network",0
msg_ENOPKG:          db "[ENOPKG] Package not installed",0
msg_EREMOTE:         db "[EREMOTE] Object is remote",0
msg_ENOLINK:         db "[ENOLINK] Link has been severed",0
msg_EADV:            db "[EADV] Advertise error",0
msg_ESRMNT:          db "[ESRMNT] Srmount error",0
msg_ECOMM:           db "[ECOMM] Communication error on send",0
msg_EPROTO:          db "[EPROTO] Protocol error",0
msg_EMULTIHOP:       db "[EMULTIHOP] Multihop attempted",0
msg_EDOTDOT:         db "[EDOTDOT] RFS specific error",0
msg_EBADMSG:         db "[EBADMSG] Not a data message",0
msg_EOVERFLOW:       db "[EOVERFLOW] Value too large for defined data type",0
msg_ENOTUNIQ:        db "[ENOTUNIQ] Name not unique on network",0
msg_EBADFD:          db "[EBADFD] File descriptor in bad state",0
msg_EREMCHG:         db "[EREMCHG] Remote address changed",0
msg_ELIBACC:         db "[ELIBACC] Can not access a needed shared library",0
msg_ELIBBAD:         db "[ELIBBAD] Accessing a corrupted shared library",0
msg_ELIBSCN:         db "[ELIBSCN] .lib section in a.out corrupted",0
msg_ELIBMAX:         db "[ELIBMAX] Attempting to link in too many shared libraries",0
msg_ELIBEXEC:        db "[ELIBEXEC] Cannot exec a shared library directly",0
msg_EILSEQ:          db "[EILSEQ] Illegal byte sequence",0
msg_ERESTART:        db "[ERESTART] Interrupted system call should be restarted",0
msg_ESTRPIPE:        db "[ESTRPIPE] Streams pipe error",0
msg_EUSERS:          db "[EUSERS] Too many users",0
msg_ENOTSOCK:        db "[ENOTSOCK] Socket operation on non-socket",0
msg_EDESTADDRREQ:    db "[EDESTADDRREQ] Destination address required",0
msg_EMSGSIZE:        db "[EMSGSIZE] Message too long",0
msg_EPROTOTYPE:      db "[EPROTOTYPE] Protocol wrong type for socket",0
msg_ENOPROTOOPT:     db "[ENOPROTOOPT] Protocol not available",0
msg_EPROTONOSUPPORT: db "[EPROTONOSUPPORT] Protocol not supported",0
msg_ESOCKTNOSUPPORT: db "[ESOCKTNOSUPPORT] Socket type not supported",0
msg_EOPNOTSUPP:      db "[EOPNOTSUPP] Operation not supported on transport endpoint",0
msg_EPFNOSUPPORT:    db "[EPFNOSUPPORT] Protocol family not supported",0
msg_EAFNOSUPPORT:    db "[EAFNOSUPPORT] Address family not supported by protocol",0
msg_EADDRINUSE:      db "[EADDRINUSE] Address already in use",0
msg_EADDRNOTAVAIL:   db "[EADDRNOTAVAIL] Cannot assign requested address",0
msg_ENETDOWN:        db "[ENETDOWN] Network is down",0
msg_ENETUNREACH:     db "[ENETUNREACH] Network is unreachable",0
msg_ENETRESET:       db "[ENETRESET] Network dropped connection because of reset ",0
msg_ECONNABORTED:    db "[ECONNABORTED] Software caused connection abort",0
msg_ECONNRESET:      db "[ECONNRESET] Connection reset by peer",0
msg_ENOBUFS:         db "[ENOBUFS] No buffer space available",0
msg_EISCONN:         db "[EISCONN] Transport endpoint is already connected",0
msg_ENOTCONN:        db "[ENOTCONN] Transport endpoint is not connected",0
msg_ESHUTDOWN:       db "[ESHUTDOWN] Cannot send after transport endpoint shutdown",0
msg_ETOOMANYREFS:    db "[ETOOMANYREFS] Too many references: cannot splice",0
msg_ETIMEDOUT:       db "[ETIMEDOUT] Connection timed out",0
msg_ECONNREFUSED:    db "[ECONNREFUSED] Connection refused",0
msg_EHOSTDOWN:       db "[EHOSTDOWN] Host is down",0
msg_EHOSTUNREACH:    db "[EHOSTUNREACH] No route to host",0
msg_EALREADY:        db "[EALREADY] Operation already in progress",0
msg_EINPROGRESS:     db "[EINPROGRESS] Operation now in progress",0
msg_ESTALE:          db "[ESTALE] Stale NFS file handle",0
msg_EUCLEAN:         db "[EUCLEAN] Structure needs cleaning",0
msg_ENOTNAM:         db "[ENOTNAM] Not a XENIX named type file",0
msg_ENAVAIL:         db "[ENAVAIL] No XENIX semaphores available",0
msg_EISNAM:          db "[EISNAM] Is a named type file",0
msg_EREMOTEIO:       db "[EREMOTEIO] Remote I/O error",0
msg_EDQUOT:          db "[EDQUOT] Quota exceeded",0
msg_ENOMEDIUM:       db "[ENOMEDIUM] No medium found",0
msg_EMEDIUMTYPE:     db "[EMEDIUMTYPE] Wrong medium type",0
msg_EHASHCOLLISION:  db "[EHASHCOLLISION] Number of hash collisons exceeds maximum generation counter value.",0

%endif
