;-------------------------------------------------------------------------
;  Return of the Very Tiny Language
;  version : 3.02  2005/06/04
;  Copyright (C) 2002-2005 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;
;  file : vtlfb.inc
;         frame buffer extention
;-------------------------------------------------------------------------

                call    GetChar             ;
                cmp     al, 'b'
                je      .frame_buffer
    .error_exit:jmp     func_error

    .frame_buffer:
                call    GetChar             ;
                cmp     al, 'o'
                je      .func_fbo           ; fb open
                cmp     al, 'c'
                je      .func_fbc           ; fb close
                cmp     al, 'd'
                je      .func_fbd           ; fb dot
                cmp     al, 'f'
                je      .func_fbf           ; fb fill
                cmp     al, 'l'
                je      .func_fbl           ; fb line
                cmp     al, 'm'
                je      .func_fbm           ; fb mem_copy
                cmp     al, 'p'
                je      .func_fbp           ; fb put
                cmp     al, 'q'
                je      .func_fbq           ; fb put with mask
                cmp     al, 'r'
                je      .func_fbr           ; fb fill pattern
                cmp     al, 's'
                je      .func_fbs           ; fb set_screen
                cmp     al, 't'
                je      .func_fbt           ; fb put2
                jmp     short .error_exit

    .func_fbf:
                call    FrameBufferFill
                ret

    .func_fbc:
                call    fb_restore_sc       ; 保存済みの設定を復帰
                call    fb_unmap_screen
                call    fbdev_close
                js      .error
                ret
    .func_fbd:
                call    Dot
                ret
    .func_fbl:
                call    LineDraw
                ret
    .func_fbm:
                call    MemCopy
                ret
    .func_fbp:
                call    PatternTransfer
                ret

    .func_fbq:
                call    MPatternTransfer
                ret

    .func_fbr:
                call    PatternFill
                ret

    .func_fbs:
                call    fb_set_screen
                ret

    .func_fbt:
                call    PatternTransfer2
                ret

    .func_fbo:
                call    fbdev_open
    .error:     js      near SYS_Error
                call    fb_get_fscreen
                js      .error
                call    fb_get_screen
                js      .error
                call    fb_copy_scinfo
                call    fb_map_screen
                jns     .ok
                mov     ecx, eax
                neg     ecx
                cmp     ecx, 0xFF
                jbe     .error
    .ok         xor     ecx, ecx
                mov     cl, 'f'
                mov     [ebp+ecx*4], eax
                mov     cl, 'g'
                mov     dword[ebp+ecx*4], scinfo_data
                ret

;---------------------------------------------------------------------------
; eax : Y
; ebx : width(byte)
; edi : addr
; carry : 32bits/pixel(set)
StartPoint:
                push    ebx
                imul    ebx                 ; Y * width
                mov     ebx, [ebp +  4]     ; X
                shl     ebx, 1              ; 16bit/pixel
                mov     edx, [ebp + 28]     ; depth
                cmp     dl, 32
                jne     .bit_16
                shl     ebx, 1              ; 32bit/pixel
                add     eax, ebx            ; Y * width + X
                add     edi, eax            ; edi := addr + eax
                pop     ebx
                stc
                ret

    .bit_16:    add     eax, ebx            ; Y * width + X
                add     edi, eax            ; edi := addr + eax
                pop     ebx
                clc
                ret

;---------------------------------------------------------------------------
; ライン描画
; l[0] = addr   [ebp +  0]
; l[1] = x1     [ebp +  4]      ; l[2] = y1     [ebp +  8]
; l[3] = x2     [ebp + 12]      ; l[4] = y2     [ebp + 16]
; l[5] = color  [ebp + 20]
; l[6] = ScrX   [ebp + 24]
; l[7] = Depth  [ebp + 28]      ; 1ピクセルのバイト数
; l[8] = incr1  [ebp + 32]
; l[9] = incr2  [ebp + 36]

LineDraw:
                pusha
                cld
                xor     ebx, ebx
                mov     bl, 'l'             ; 引数は a[0] - a[2]
                mov     ebp, [ebp+ebx*4]    ; ebp : argument top
                mov     edi, [ebp]          ; buffer address (mem or fb)
                mov     ebx, [ebp + 24]     ; ScrX

                mov     ecx, [ebp + 12]     ; ecx = delta X (X2 - X1)
                sub     ecx, [ebp +  4]     ; ecx = X2 - X1
                jz      .VertLine           ; if (delta X=0) Vertical
                jns     .L01                ; JUMP IF X2 > X1

                neg     ecx                 ; deltaX = - deltaX
                mov     eax, [ebp + 12]     ; swap X1  X2
                xchg    eax, [ebp +  4]
                mov     [ebp + 12], eax

                mov     eax, [ebp + 16]     ; swap Y1  Y2
                xchg    eax, [ebp +  8]     ; Y1
                mov     [ebp + 16], eax

    .L01:       mov     eax, [ebp + 16]     ; eax = Y2-Y1
                sub     eax, [ebp +  8]     ; Y1
                jnz     .SlopeLine

    .HolizLine: inc     ecx                 ; DELTA X + 1 : # OF POINTS
                mov     eax, [ebp +  8]     ; Y1
                call    StartPoint          ; edi=addr + X + Y * width
                mov     eax, [ebp + 20]     ; color
                jb      .h32
                rep     stosw               ; 16bit
                jmp     short .exit0        ; finished
    .h32:       rep     stosd               ; 32bit
                jmp     short .exit0        ; finished

    .VertLine:  mov     eax, [ebp +  8]     ; Y1
                mov     esi, [ebp + 16]     ; Y2
                mov     ecx, esi
                sub     ecx, eax            ; Y2 - Y1
                jge     .LVL1
                neg     ecx
                mov     eax, esi
    .LVL1:      inc     ecx                 ; DELTA Y + 1 : # OF POINTS
                call    StartPoint          ; edi=addr + X + Y * width
                mov     eax, [ebp + 20]     ; color
                jb      .LVL32
    .LVL16:
                mov     [edi], ax
                add     edi, ebx            ; ebx:width
                loop    .LVL16
                jmp     short .exit0        ; finished
    .LVL32:
                mov     [edi], eax
                add     edi, ebx            ; ebx:width
                loop    .LVL32
    .exit0:     popa
                ret                         ; finished

    ;-------------------------------------------------
    ;      ENTRY : eax = DY   ebx = width (bytes/line)
    ;              ecx = dx
    .SlopeLine:
                jns     .L03                ; JUMP IF (Y2 > Y1)
                neg     eax                 ; DELTA Y
                neg     ebx                 ; BYTES/LINE

    .L03:       push    eax
                push    ecx
                cmp     eax, ecx            ; DELTA Y - DELTA X
                jle     .L04                ; JUMP IF DY <= dx ( SLOPE <= 1)
                xchg    eax, ecx

    .L04:       shl     eax, 1              ; eax := 2 * DY
                mov     [ebp + 32], eax     ; incr1 := 2 * DY
                sub     eax, ecx
                mov     esi, eax            ; esi := D = 2 * DY - dx
                sub     eax, ecx

                mov     [ebp + 36], eax     ; incr2 := D = 2 * (DY - dx)

                mov     eax, [ebp +  8]     ; Y1
                push    ebx
                or      ebx, ebx
                jns     .L05
                neg     ebx
    .L05:
                call    StartPoint          ; edi=addr + X + Y * width
                pop     ebx
                pop     ecx
                pop     eax
                jb      .Slope32
                cmp     eax, ecx            ; DELTA Y - DELTA X
                jg      .HiSlopeLine        ; JUMP IF DY > dx ( SLOPE > 1)

    .LoSlopeLine:
                inc     ecx
                mov     eax, [ebp + 20]     ; color
    .L11:       stosw
                or      esi, esi
                jns     .L12
                add     esi, [ebp + 32]     ; incr1
                loop    .L11
                jmp     short .exit

    .L12:       add     esi, [ebp + 36]     ; incr2
                add     edi, ebx            ; ebx=(+/-)width
                loop    .L11
                jmp     short .exit

    .HiSlopeLine:
                xchg    eax, ecx
                inc     ecx
                mov     eax, [ebp + 20]     ; color
    .L21:       stosw
                add     edi, ebx            ; ebx=(+/-)width
                or      esi, esi
                jns     .L22
                add     esi, [ebp + 32]     ; incr1
                dec     edi
                dec     edi
                loop    .L21
                jmp     short .exit

    .L22:       add     esi, [ebp + 36]     ; incr2
                loop    .L21

    .exit:      popa
                ret

    .Slope32:   cmp     eax, ecx            ; DELTA Y - DELTA X
                jg      .HiSlopeLine32      ; JUMP IF DY > dx ( SLOPE > 1)

    .LoSlopeLine32:
                inc     ecx
                mov     eax, [ebp + 20]     ; color
    .L31:       stosd
                or      esi, esi
                jns     .L32
                add     esi, [ebp + 32]     ; incr1
                loop    .L31
                jmp     short .exit2

    .L32:       add     esi, [ebp + 36]     ; incr2
                add     edi, ebx            ; ebx=(+/-)width
                loop    .L31
                jmp     short .exit2

    .HiSlopeLine32:
                xchg    eax, ecx
                inc     ecx
                mov     eax, [ebp + 20]     ; color
    .L41:       stosd
                add     edi, ebx            ; ebx=(+/-)width
                or      esi, esi
                jns     .L42
                add     esi, [ebp + 32]     ; incr1
                sub     edi, 4
                loop    .L41
                jmp     short .exit2

    .L42:       add     esi, [ebp + 36]     ; incr2
                loop    .L41

    .exit2:     popa
                ret

;---------------------------------------------------------------------------
; 点の描画 16&32bit
;   d[0] = addr   [ebp +  0] 描画領域先頭アドレス
;   d[1] = x      [ebp +  4] X座標
;   d[2] = y      [ebp +  8] Y座標
;   d[3] = Color  [ebp + 12] 色
;   d[4] = ScrX   [ebp + 16] 転送先X方向のバイト数
;   d[5] = Depth  [ebp + 20] 1ピクセルのバイト数
Dot:
                pusha
                xor     ebx, ebx
                mov     bl, 'd'             ; 引数
                mov     ebp, [ebp+ebx*4]    ; ebp : argument top
                mov     ecx, [ebp + 16]     ; ScrX
                mov     edi, [ebp]          ; buffer address (mem or fb)
                mov     eax, [ebp +  8]     ; Y
                imul    ecx                 ; Y * ScrX
                mov     edx, [ebp +  4]     ; X
                shl     edx, 1              ; X * 2
                add     eax, edx            ; X * 2 + Y * ScrX
                add     edi, eax            ; edi := addr + eax
                mov     ebx, [ebp + 12]     ; color
                mov     eax, [ebp + 20]     ; Depth
                cmp     al, 32
                je      .depth32
                mov     [edi], bx           ; 16bit/pixel
                popa
                ret
    .depth32:   mov     [edi], ebx          ; 32bit/pixel
                popa
                ret


;---------------------------------------------------------------------------
; 引数関連共通処理
; return
;  eax = depth
;  ebx = ScrX
;  ecx = ScrX
;  edx = PatH
;  edi = 転送先アドレス
;  esi = パターンの格納アドレス先頭
;  ebp = 引数先頭
PatternSize:
                cld
                mov     ebp, [ebp+ebx*4]    ; ebp : argument top
                mov     ecx, [ebp + 24]     ; ScrX
                mov     edi, [ebp]          ; buffer address (mem or fb)
                mov     esi, [ebp + 20]     ; pattern
                mov     eax, [ebp +  8]     ; Y
                imul    ecx                 ; Y * ScrX
                mov     edx, [ebp +  4]     ; X
                shl     edx, 1              ; X * 2
                add     eax, edx            ; X * 2 + Y * ScrX
                add     edi, eax            ; edi := addr + eax
                mov     ebx, ecx            ; ebx := Screen Width
                mov     edx, [ebp + 16]     ; PatH
                mov     al,  [ebp + 28]     ; Depth
                ret

;---------------------------------------------------------------------------
; パターン転送 16&32bit
;   p[0] = addr   [ebp +  0] 転送先アドレス
;   p[1] = x      [ebp +  4] 転送先のX座標
;   p[2] = y      [ebp +  8] 転送先のY座標
;   p[3] = PatW   [ebp + 12] パターンの幅
;   p[4] = PatH   [ebp + 16] パターンの高さ
;   p[5] = mem    [ebp + 20] パターンの格納アドレス
;   p[6] = ScrX   [ebp + 24] 転送先X方向のバイト数
;   p[7] = Depth  [ebp + 28] 1ピクセルのバイト数

PatternTransfer:
                pusha
                xor     ebx, ebx
                mov     bl, 'p'             ; 引数
                call    PatternSize
                cmp     al, 32
                je      .pat32
    .loop16:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                rep     movsw
                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop16
                jmp     short .exit
    .pat32:     add     edi, edx            ; edi=addr + Y*ScrX + X*4
    .loop32:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                rep     movsd
                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop32
    .exit:      popa
                ret

;---------------------------------------------------------------------------
; パターン転送2 16&32bit
;   t[0] = addr   [ebp +  0] 転送先アドレス
;   t[1] = x      [ebp +  4] 転送先のX座標
;   t[2] = y      [ebp +  8] 転送先のY座標
;   t[3] = PatW   [ebp + 12] パターンの幅
;   t[4] = PatH   [ebp + 16] パターンの高さ
;   t[5] = mem    [ebp + 20] パターンの格納アドレス先頭
;   t[6] = ScrX   [ebp + 24] 転送先のX方向のバイト数
;   t[7] = Depth  [ebp + 28] 1ピクセルのバイト数
;   t[8] = x2     [ebp + 32] 転送元のX座標
;   t[9] = y2     [ebp + 36] 転送元のY座標
;   t[10]= ScrX2  [ebp + 40] 転送元のX方向のバイト数

PatternTransfer2:
                pusha
                xor     ebx, ebx
                mov     bl, 't'             ; 引数
                call    PatternSize
                push    eax                 ; depth
                push    edx                 ; PatH
                mov     ecx, [ebp + 40]     ; ScrX2
                mov     eax, [ebp + 36]     ; Y2
                imul    ecx                 ; Y2 * ScrX2
                mov     edx, [ebp + 32]     ; X2
                shl     edx, 1              ; X2 * 2
                add     eax, edx            ; X2 * 2 + Y2 * ScrX2
                add     esi, eax            ; esi := mem + eax
                pop     edx                 ; PatH
                pop     eax                 ; depth
                cmp     al, 32
                je      .pat32
                mov     eax, [ebp + 40]     ; ScrX2
    .loop16:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                push    esi
                rep     movsw
                pop     esi
                pop     edi
                add     edi, ebx            ; y++
                add     esi, eax            ; y2++
                dec     edx
                jne     .loop16
                jmp     short .exit
    .pat32:     add     edi, edx            ; edi=addr + Y*ScrX + X*4
                mov     eax, [ebp + 40]     ; ScrX2
    .loop32:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                push    esi
                rep     movsd
                pop     esi
                pop     edi
                add     edi, ebx            ; y++
                add     esi, eax            ; y2++
                dec     edx
                jne     .loop32
    .exit:      popa
                ret

;---------------------------------------------------------------------------
; マスク付きパターン転送 16&32bit
;   q[0] = addr   [ebp +  0] 転送先アドレス
;   q[1] = x      [ebp +  4] 転送先のX座標
;   q[2] = y      [ebp +  8] 転送先のY座標
;   q[3] = PatW   [ebp + 12] パターンの幅
;   q[4] = PatH   [ebp + 16] パターンの高さ
;   q[5] = mem    [ebp + 20] パターンの格納アドレス
;   q[6] = ScrX   [ebp + 24] X方向のバイト数
;   q[7] = Depth  [ebp + 28] 1ピクセルのバイト数
;   q[8] = Mask   [ebp + 32] マスク色
MPatternTransfer:
                pusha
                xor     ebx, ebx
                mov     bl, 'q'             ; 引数
                call    PatternSize
                cmp     al, 32
                je      .pat32
    .loop16:    mov     ecx, [ebp + 12]     ; PatW
                push    edi

    .l16b       mov     ax, [esi]
                cmp     ax, [ebp + 32]      ; マスク色なら書込まない
                je      .l16n
                mov     [edi], ax
    .l16n       add     esi, 2
                add     edi, 2
                loop    .l16b

                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop16
                jmp     short .exit

    .pat32:     add     edi, edx            ; edi=addr + Y*ScrX + X*4
    .loop32:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
    .l32b       mov     eax, [esi]
                cmp     eax, [ebp + 32]     ; マスク色なら書込まない
                je      .l32n
                mov     [edi], eax
    .l32n       add     esi, 4
                add     edi, 4
                loop    .l32b
                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop32
    .exit:      popa
                ret

;---------------------------------------------------------------------------
; パターンフィル 16&32bit
;   r[0] = addr   [ebp +  0] 転送先アドレス
;   r[1] = x      [ebp +  4] 転送先のX座標
;   r[2] = y      [ebp +  8] 転送先のY座標
;   r[3] = PatW   [ebp + 12] パターンの幅
;   r[4] = PatH   [ebp + 16] パターンの高さ
;   r[5] = Color  [ebp + 20] パターンの色
;   r[6] = ScrX   [ebp + 24] X方向のバイト数
;   r[7] = Depth  [ebp + 28] 1ピクセルのバイト数

PatternFill:
                pusha
                xor     ebx, ebx
                mov     bl, 'r'             ; 引数
                call    PatternSize
                cmp     al, 32
                je      .pat32
    .pat16:     mov     eax, esi
    .loop16:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                rep     stosw
                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop16
                jmp     short .exit
    .pat32:     mov     eax, esi
                add     edi, edx            ; edi=addr + Y*ScrX + X*4
    .loop32:    mov     ecx, [ebp + 12]     ; PatW
                push    edi
                rep     stosd
                pop     edi
                add     edi, ebx            ; y++
                dec     edx
                jne     .loop32
    .exit:      popa
                ret

;---------------------------------------------------------------------------
; メモリフィル 8&16&32bit
;  m[0] = addr   [ebp +  0] メモリフィル先頭アドレス
;  m[1] = offset [ebp +  4] オフセット
;  m[2] = length [ebp +  8] 長さ(ピクセル単位)
;  m[3] = color  [ebp + 12] 色
;  m[4] = Depth  [ebp + 16] bits/pixel

FrameBufferFill:
                push    edi
                cld
                xor     ebx, ebx
                mov     bl, 'm'             ; 引数は a[0] - a[4]
                mov     edx, [ebp+ebx*4]
                mov     edi, [edx]
                add     edi, [edx + 4]      ; offset
                mov     ecx, [edx + 8]      ; length (pixel)
                mov     eax, [edx +12]      ; color
                mov     edx, [edx +16]      ; bits/pixel
                shr     edx, 4
                jne     .word
                rep     stosb               ; byte
                jmp     short .exit
    .word:      shr     edx, 1
                jne     .dword
                rep     stosw               ; word
                jmp     short .exit
    .dword:     rep     stosd               ; dword
    .exit:      pop     edi
                ret

;---------------------------------------------------------------------------
; メモリコピー
;  c[0] = source [ebp +  0] 転送元先頭アドレス
;  c[1] = dest   [ebp +  4] 転送先先頭アドレス
;  c[2] = length [ebp +  8] 転送バイト数
MemCopy:
                pusha
                cld
                xor     ebx, ebx
                mov     bl, 'c'             ; 引数は c[0] - c[2]
                mov     edx, [ebp+ebx*4]
                mov     esi, [edx]          ; 転送元アドレス
                mov     edi, [edx + 4]      ; 転送先アドレス
                mov     ecx, [edx + 8]      ; 転送バイト数
                mov     eax, edi
                sub     eax, esi            ; eax = 転送先 - 転送元
                jle     .normal             ; 転送先 < 転送元
                std                         ; 逆順
                dec     ecx                 ; 行過ぎを事前に修正
                add     esi, ecx            ; 最後部から
                add     edi, ecx
                inc     ecx                 ; 転送量を戻す
    .normal:
                rep     movsb               ; バイト単位
                cld
                popa
                ret
