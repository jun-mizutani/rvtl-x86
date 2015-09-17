;---------------------------------------------------------------------
; file          : stdio.inc
; created       : 2003/10/25, 2005/6/19, 2010/02/28
; assembler     : nasm 2.05.01
; description   : standerd input/output version 1.1
;
;Copyright (C) 2000-2010 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;---------------------------------------------------------------------

%ifndef __STDIO_INC
%define __STDIO_INC

%ifndef __SYSCALL_INC
%include "syscall.inc"
%endif

;------------------------------------
; exit with 0
Exit:
                xor     ebx, ebx            ; exit with code 0
                mov     eax, ebx
                inc     eax                 ; 1:sys_exit
                int     0x80

;------------------------------------
; exit with ebx
ExitN:
               mov    ebx, eax              ; exit with code ebx
               mov    eax, 1                ; sys_exit
               int    0x80


;------------------------------------
; print string to stdout
; eax : buffer top address
; edx : no of char to output
OutString:
                pusha
                mov     ecx, eax
    .out        mov     eax, SYS_write
                xor     ebx, ebx
                inc     ebx                 ; to stdout
                int     0x80
                popa
                ret

;------------------------------------
; print pascal string to stdout
; ebx : buffer top address
OutPString:
                pusha
                xor     edx, edx
                mov     dl, [ebx]
                inc     ebx
                mov     ecx, ebx
                jmp     short  OutString.out

;------------------------------------
; print asciiz string
; eax : pointer to string
OutAsciiZ:
                pusha
                push    eax
                call    StrLen
                mov     edx, eax            ; set length
                pop     ecx                 ; set address (eax-->ecx)
                jmp     short  OutString.out

;------------------------------------
; get length of asciiz string
; eax : top address
; eax : return length
StrLen:
                push    ecx
                push    edi
                mov     edi, eax
                push    eax
                xor     eax, eax
                xor     ecx, ecx
                dec     ecx
         repne  scasb
                pop     ecx
                sub     edi, ecx
                mov     eax, edi
                dec     eax
                pop     edi
                pop     ecx
                ret

;------------------------------------
; print 1 character to stdout
; eax : put char
OutChar:
                pusha
                push    eax                 ; work buffer on stack
                mov     eax, SYS_write
                xor     ebx, ebx
                inc     ebx                 ; 1:to stdout
                mov     edx, ebx            ; 1 char
                mov     ecx, esp
                int     0x80
                pop     eax
                popa
                ret

;------------------------------------
; print 4 characters in eax to stdout
;   destroyed : eax
OutChar4:
                push    ecx
                mov     ch, 0x04
                mov     cl, 0x08
    .loop:      and     al, 0x7F            ; 7bit only
                test    al, al
                jz      .dot
                cmp     al, 0x20
                jae     .output
    .dot:       mov     al, '.'
    .output:    call    OutChar
                shr     eax, cl
                dec     ch
                jnz     .loop
                pop     ecx
                ret

;------------------------------------
; new line
;   all registers are preserved.
NewLine:
                push    eax
                mov     al, 0AH
                call    OutChar
                pop     eax
                ret

;------------------------------------
; Backspace
;   destroyed : al
BackSpace:
               mov    al, 0x08
               call   OutChar
               mov    al, ' '
               call   OutChar
               mov    al, 0x08
               call   OutChar
               ret

;------------------------------------
; print binary number
;   eax : number
;   ecx : bit
PrintBinary:
                pusha
                mov     ebx, eax
                mov     esi, 32
                or      ecx, ecx        ; ecx > 0 ?
                jle     .exit           ; no ecx<=0
                cmp     ecx, esi
                jg      .toobig
                mov     edx, ecx        ; extract lower bits
                sub     esi, ecx        ; 32
                mov     ecx, esi
                shl     ebx, cl
                mov     ecx, edx
                jmp     short .loop
        .toobig:
                mov     ecx, 32
        .loop:
                mov     eax, '0'
                shl     ebx, 1
                jnc     .print_zero
                inc     eax
        .print_zero:
                call    OutChar
                loop    .loop
        .exit:  popa
                ret

;------------------------------------
; print ecx digit octal number
;   eax : number
;   ecx : digit
PrintOctal:
                pusha
                or      ecx, ecx
                je      .exit
                mov     edx, ecx            ; 桁数カウンタ
    .push:      mov     ebx, eax
                and     ebx, byte 7
                shr     eax, 3
                push    ebx                 ; 剰余(下位桁)をPUSH
                loop    .push
                mov     ecx, edx            ; 桁数カウンタ
    .pop:       pop     eax                 ; 上位桁から POP
                add     al, '0'             ; 文字コードに変更
                call    OutChar             ; 出力
                loop    .pop
    .exit:      popa
                ret

;------------------------------------
; print 2 digit hex number (lower 8 bit of eax)
;   eax : number
;   destroyed : edx
PrintHex2:
                mov     dl, 2
                jmp     short PrintHex

;------------------------------------
; print 4 digit hex number (lower 16 bit of eax)
;   eax : number
;   destroyed : edx
PrintHex4:
                mov    dl, 4
                jmp    short PrintHex

;------------------------------------
; print 8 digit hex number (eax)
;   eax : number
;   destroyed : edx
PrintHex8:
                mov    dl, 8

;------------------------------------
; print hex number
;   eax : number     edx : digit
PrintHex:
                push    eax
                push    ecx
                push    ebx
                xor     ecx, ecx
                mov     cl, dl
    .loop1:     mov     bl, al
                and     bl, 0x0F
                shr     eax, 4
                or      bl, 0x30
                cmp     bl, 0x3A
                jb      .skip
                add     bl, 0x41 - 0x3A     ; A-F
    .skip:
                push    ebx
                loop    .loop1
                mov     cl, dl
    .loop2:     pop     eax
                call    OutChar
                loop    .loop2
                pop     ebx
                pop     ecx
                pop     eax
                ret

;------------------------------------
; Output Unsigned Number to stdout
; eax : number
PrintLeftU:
                pusha
                xor     ecx, ecx            ; 桁数カウンタ
                xor     edi, edi            ; 正を仮定
                jmp     short PrintLeft.positive

;------------------------------------
; Output Number to stdout
; eax : number
PrintLeft:
                pusha
                xor     ecx, ecx            ; 桁数カウンタ
                xor     edi, edi            ; 正を仮定
                test    eax, eax
                jns     .positive
                inc     edi                 ; 負に設定
                neg     eax
    .positive:  mov     ebx, 10
    .PL1:       xor     edx, edx            ; 上位桁を 0 に
                div     ebx                 ; 10 で除算
                push    edx                 ; 剰余(下位桁)をPUSH
                inc     ecx                 ; 桁数更新
                test    eax, eax            ; 終了か?
                jnz     .PL1
    .PL2:       test    edi, edi
                je      .pos
                mov     al, '-'             ; 文字コードに変更
                call    OutChar             ; 出力
    .pos:       pop     eax                 ; 上位桁から POP
                add     al, '0'             ; 文字コードに変更
                call    OutChar             ; 出力
                loop    .pos
                popa
                ret

;------------------------------------
; Output Number to stdout
; ecx:column
; eax:number
PrintRight0:
                pusha
                mov     ebp, '0'
                jmp     short PrintRightU.pr0

;------------------------------------
; Output Unsigned Number to stdout
; ecx:column
; eax:number
PrintRightU:
                pusha
                mov     ebp, ' '
    .pr0:       mov     esi, ecx            ; 表示桁数を esi に
                xor     ecx, ecx            ; 桁数カウンタ
                xor     edi, edi            ; 正を仮定
                jmp     short PrintRight.positive

;------------------------------------
; Output Number to stdout
; ecx:column
; eax:number
PrintRight:
                pusha
                mov     ebp, ' '
    .pr0:       mov     esi, ecx            ; 表示桁数を esi に
                xor     ecx, ecx            ; 桁数カウンタ
                xor     edi, edi            ; 正を仮定
                test    eax, eax
                jns     .positive
                dec     esi
                inc     edi                 ; 負を設定
                neg     eax
    .positive:
                mov     ebx, 10
    .pr1:       xor     edx, edx            ; 上位桁を 0 に
                div     ebx                 ; 10 で除算
                push    edx                 ; 剰余(下位桁)をPUSH
                inc     ecx                 ; 桁数更新
                test    eax, eax            ; 終了か?
                jnz     .pr1
                sub     esi, ecx            ; esi にスペース数
                jbe     .done               ; 表示桁数を超える
                xchg    esi, ecx            ; ecx にスペース数
    .space:     mov     eax, ebp            ; スペースか 0
                call    OutChar             ; スペース出力
                loop    .space
                xchg    esi, ecx            ; ecx に表示桁数
    .done:
                jmp     short PrintLeft.PL2

;------------------------------------
; input 1 character from stdin
; eax : get char
InChar:
                push    ebx
                push    ecx
                push    edx
                push    eax                 ; work buffer on stack
                mov     eax, SYS_read
                xor     ebx, ebx            ; 0:from stdin
                mov     ecx, esp            ; into Input Buffer
                mov     edx, ebx
                inc     edx                 ; 1 char
                int     0x80                ; call kernel
                pop     eax
                pop     edx
                pop     ecx
                pop     ebx
                ret

;------------------------------------
; Input Line
; eax : BufferSize
; ebx : Buffer Address
; return       eax : no. of char
;
InputLine0:
               push   edi
               push   ecx
               push   edx
               mov    edx, eax
               mov    edi, ebx       ; Input Buffer
               xor    ecx, ecx
   .in_char:
               call   InChar
               cmp    al, 0x08       ; BS ?
               jnz    .in_char2
               test   ecx, ecx
               jz     .in_char2
               call   BackSpace      ; backspace
               dec    ecx
               jmp    short .in_char
   .in_char2:
               cmp    al, 0x0A       ; enter ?
               jz     .in_exit

   .in_printable:
               call   OutChar
               mov    [edi + ecx], al
               inc    ecx
               cmp    ecx, edx       ;
               jae    .in_toolong
               jmp    short .in_char
   .in_toolong:
               dec    ecx
               call   BackSpace
               jmp    short .in_char

   .in_exit:
               mov    dword [edi + ecx], 0
               inc    ecx
               call   NewLine
               mov    eax, ecx
               pop    ecx
               pop    edi
               ret

%endif
