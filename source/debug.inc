;=========================================================================
; DEBUG
; file : debug.inc
; 2003/10/25
; Copyright (C) 2003 Jun Mizutani <mizutani.jun;nifty.ne.jp>
;=========================================================================
%ifndef __DEBUG_INC
%define __DEBUG_INC

%ifndef __STDIO_INC
%include "stdio.inc"
%endif

%define quote   '

; レジスタの値を表示するマクロ
; すべてのレジスタを非破壊で表示可能
; フラグレジスタは変化
; ラベルとして998:と999:を使っていることに注意】
;   ex. PRINTREG 'eax'

%macro  PRINTREG   1
        pusha
        push    eax
        mov     eax, %%L0
        call    OutAsciiZ
        pop      eax
        push     eax
        push    ecx
        mov     eax, %1
        mov     ecx, 12
        call    PrintRight
        call    PrintRightU
        mov     al, ':'
        call    OutChar
        pop     ecx
        pop     eax
        push    eax
        push    edx
        mov     eax, %1
        call    PrintHex8
        pop     edx
        mov     al, ' '
        call    OutChar
        pop     eax
        mov     eax, %1
        call    OutChar4
        call    NewLine
        popa
        jmp     short %%L1
%%L0:  db       quote %1 quote, 0
%%L1:
%endmacro

; レジスタの値を先頭アドレスとする文字列を表示するマクロ
; 文字列先頭アドレスの直接指定
;   ex. PRINTSTR esi
%macro  PRINTSTR   1
        pushfd
        pusha
        mov     eax, %1
        call    OutAsciiZ
        call    NewLine
        popa
        popfd
%endmacro

; レジスタが示すアドレスに格納された値を先頭アドレスとする文字列を
; 表示するマクロ
; 文字列先頭アドレスの間接指定
;   ex. PRINTSTRI esi
%macro  PRINTSTRI  1
        pushfd
        pusha
        mov     eax, [%1]
        call    OutAsciiZ
        call    NewLine
        popa
        popfd
%endmacro

; 指定した値を表示するマクロ
; すべてのレジスタを非破壊で表示可能
;   ex. CHECK 99
%macro CHECK 1
        pushfd
        push    eax
        mov     eax, %1
        call    PrintLeft
        call    NewLine
        pop     eax
        popfd
%endmacro

; キー入力待ち
%macro  PAUSE 0
        push    eax
        call    InChar
        pop     eax
%endmacro

%endif
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
</body>
