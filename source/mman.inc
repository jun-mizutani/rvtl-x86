;=========================================================================
; file : mman.inc
; 2001/01/08
; derived from  : linux-2.4.0-test12/include/asm-i386/mman.h
;=========================================================================

%ifndef __MMAN_H__
%define __MMAN_H__

%assign     PROT_READ       0x1     ; page can be read
%assign     PROT_WRITE      0x2     ; page can be written
%assign     PROT_EXEC       0x4     ; page can be executed
%assign     PROT_NONE       0x0     ; page can not be accessed

%assign     MAP_SHARED      0x01    ; Share changes
%assign     MAP_PRIVATE     0x02    ; Changes are private
%assign     MAP_TYPE        0x0f    ; Mask for type of mapping
%assign     MAP_FIXED       0x10    ; Interpret addr exactly
%assign     MAP_ANONYMOUS   0x20    ; don't use a file

%assign     MAP_GROWSDOWN   0x0100  ; stack-like segment
%assign     MAP_DENYWRITE   0x0800  ; ETXTBSY
%assign     MAP_EXECUTABLE  0x1000  ; mark it as an executable
%assign     MAP_LOCKED      0x2000  ; pages are locked
%assign     MAP_NORESERVE   0x4000  ; don't check for reservations

%assign     MS_ASYNC        1       ; sync memory asynchronously
%assign     MS_INVALIDATE   2       ; invalidate the caches
%assign     MS_SYNC         4       ; synchronous memory sync

%assign     MCL_CURRENT     1       ; lock all current mappings
%assign     MCL_FUTURE      2       ; lock all future mappings

%assign     MADV_NORMAL     0x0     ; default page-in behavior
%assign     MADV_RANDOM     0x1     ; page-in minimum required
%assign     MADV_SEQUENTIAL 0x2     ; read-ahead aggressively
%assign     MADV_WILLNEED   0x3     ; pre-fault pages
%assign     MADV_DONTNEED   0x4     ; discard these pages

; compatibility flags
%assign     MAP_ANON    MAP_ANONYMOUS
%assign     MAP_FILE    0

; from linux/arch/i386/kernel/sys_i386.c

struc mmap_arg_struct
    .addr       resd    1;
    .len        resd    1;
    .prot       resd    1;
    .flags      resd    1;
    .fd         resd    1;
    .offset     resd    1;
endstruc

%endif
