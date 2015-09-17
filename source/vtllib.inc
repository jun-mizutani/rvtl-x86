;---------------------------------------------------------------------
;  RVTL
;  file : vtllib.inc
;  2003/11/05, 2010/02/28, 2015/08/27
;  Copyright (C) 2003-2015 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;---------------------------------------------------------------------

%ifndef __VTLLIB_INC
%define __VTLLIB_INC

%ifndef __SYSCALL_INC
%include "syscall.inc"
%endif

%ifndef __STDIO_INC
%include "stdio.inc"
%endif

%ifndef __SIGNAL_INC
%include "signal.inc"
%endif

section .bss

%assign         MAXLINE     128         ; Maximum Line Length
%assign         MAX_FILE    256         ; Maximum Filename
%assign         MAXHISTORY   16         ; No. of history buffer
%assign         LINE_TOP      7         ; No. of prompt characters

struc winsize
        .ws_row     resw 1
        .ws_col     resw 1
        .ws_xpixel  resw 1
        .ws_ypixel  resw 1
endstruc

wsize istruc winsize
        .ws_row     resw 1
        .ws_col     resw 1
        .ws_xpixel  resw 1
        .ws_ypixel  resw 1
      iend

%assign TIOCGWINSZ      0x5413

%assign NCCS 19

struc termios
    .c_iflag        resd    1       ; input mode flags
    .c_oflag        resd    1       ; output mode flags
    .c_cflag        resd    1       ; control mode flags
    .c_lflag        resd    1       ; local mode flags
    .c_line         resb    1       ; line discipline
    .c_cc           resb    NCCS    ; control characters
endstruc

struc  timeval
    .tv_sec         resd    1       ;
    .tv_usec        resd    1       ;
endstruc

struc timezone
    .tz_minuteswest resd    1       ;
    .tz_dsttime     resd    1       ;
endstruc

;  c_cc characters
%assign VTIME       5
%assign VMIN        6

;  c_lflag bits
%assign ISIG    0000001q
%assign ICANON  0000002q
%assign XCASE   0000004q
%assign ECHO    0000010q
%assign ECHOE   0000020q
%assign ECHOK   0000040q
%assign ECHONL  0000100q
%assign NOFLSH  0000200q
%assign TOSTOP  0000400q
%assign ECHOCTL 0001000q
%assign ECHOPRT 0002000q
%assign ECHOKE  0004000q
%assign FLUSHO  0010000q
%assign PENDIN  0040000q
%assign IEXTEN  0100000q

%assign TCGETS          0x5401
%assign TCSETS          0x5402

%assign SEEK_SET       0       ; Seek from beginning of file.
%assign SEEK_CUR       1       ; Seek from current position.
%assign SEEK_END       2       ; Seek from end of file.

; from include/linux/resource.h
struc  rusage
        .ru_utime_tv_sec   resd  1; user time used
        .ru_utime_tv_usec  resd  1;
        .ru_stime_tv_sec   resd  1; system time used
        .ru_stime_tv_usec  resd  1;
        .ru_maxrss    resd   1;  maximum resident set size
        .ru_ixrss     resd   1;  integral shared memory size
        .ru_idrss     resd   1;  integral unshared data size
        .ru_isrss     resd   1;  integral unshared stack size
        .ru_minflt    resd   1;  page reclaims
        .ru_majflt    resd   1;  page faults
        .ru_nswap     resd   1;  swaps
        .ru_inblock   resd   1;  block input operations
        .ru_oublock   resd   1;  block output operations
        .ru_msgsnd    resd   1;  messages sent
        .ru_msgrcv    resd   1;  messages received
        .ru_nsignals  resd   1;  signals received
        .ru_nvcsw     resd   1;  voluntary context switches
        .ru_nivcsw    resd   1;  involuntary
endstruc

; from include/linux/wait.h
%assign WNOHANG         0x00000001
%assign WUNTRACED       0x00000002

; from include/asm-i386/fcntl.h
%assign O_RDONLY             00q
%assign O_WRONLY             01q
%assign O_RDWR               02q
%assign O_CREAT            0100q ;  not fcntl
%assign O_EXCL             0200q ;  not fcntl
%assign O_NOCTTY           0400q ;  not fcntl
%assign O_TRUNC           01000q ;  not fcntl

; from include/linux/dirent.h
struc dirent
        .d_ino      resd  1  ;
        .d_off      resd  1  ;
        .d_reclen   resw  1  ;
        .d_name     resb 256 ;
endstruc

; from include/asm/stat.h
struc stat
        .st_dev     resw    1
        .__pad1     resw    1
        .st_ino     resd    1
        .st_mode    resw    1
        .st_nlink   resw    1
        .st_uid     resw    1
        .st_gid     resw    1
        .st_rdev    resw    1
        .__pad2     resw    1
        .st_size    resd    1
        .st_blksize resd    1
        .st_blocks  resd    1
        .st_atime   resd    1
        .__unused1  resd    1
        .st_mtime   resd    1
        .__unused2  resd    1
        .st_ctime   resd    1
        .__unused3  resd    1
        .__unused4  resd    1
        .__unused5  resd    1
endstruc

%assign S_IFMT  00170000q
%assign S_IFSOCK 0140000q
%assign S_IFLNK  0120000q
%assign S_IFREG  0100000q
%assign S_IFBLK  0060000q
%assign S_IFDIR  0040000q
%assign S_IFCHR  0020000q
%assign S_IFIFO  0010000q
%assign S_ISUID  0004000q
%assign S_ISGID  0002000q
%assign S_ISVTX  0001000q

%assign S_IRWXU 00700q
%assign S_IRUSR 00400q
%assign S_IWUSR 00200q
%assign S_IXUSR 00100q

%assign S_IRWXG 00070q
%assign S_IRGRP 00040q
%assign S_IWGRP 00020q
%assign S_IXGRP 00010q

%assign S_IRWXO 00007q
%assign S_IROTH 00004q
%assign S_IWOTH 00002q
%assign S_IXOTH 00001q

; from include/linux/fs.h
%assign MS_RDONLY        1      ; Mount read-only
%assign MS_NOSUID        2      ; Ignore suid and sgid bits
%assign MS_NODEV         4      ; Disallow access to device special files
%assign MS_NOEXEC        8      ; Disallow program execution
%assign MS_SYNCHRONOUS  16      ; Writes are synced at once
%assign MS_REMOUNT      32      ; Alter flags of a mounted FS

;==============================================================
section .text

;-------------------------------------------------------------------------
; 編集付き行入力(初期文字列付き)
;   eax:バッファサイズ, ebx:バッファ先頭
;   eax に入力文字数を返す
;-------------------------------------------------------------------------
READ_LINE2:
                mov     dword[FLOATING_TOP], LINE_TOP
                pusha
                push    eax                     ; バッファサイズ退避
                mov     eax, ebx                ; 入力バッファ表示
                call    OutAsciiZ
                call    StrLen
                mov     ecx, eax
                pop     eax                     ; バッファサイズ復帰
                mov     ebp, HistLine           ; history string ptr
                mov     edi, ebx                ; Input Buffer
                mov     edx, eax                ; BufferSize
                mov     esi, ecx                ; current position
                jmp     short READ_LINE.next_char

;-------------------------------------------------------------------------
; 編集付き行入力
;   eax:バッファサイズ, ebx:バッファ先頭
;   eax に入力文字数を返す
;   カーソル位置を取得して行頭を保存, 複数行にわたるペースト不可
;-------------------------------------------------------------------------
READ_LINE3:
                call    get_cursor_position
                jmp     short READ_LINE.entry

;-------------------------------------------------------------------------
; 編集付き行入力
;   eax:バッファサイズ, ebx:バッファ先頭
;   eax に入力文字数を返す
;-------------------------------------------------------------------------
READ_LINE:
                mov     dword[FLOATING_TOP], LINE_TOP
    .entry:     pusha
                mov     ebp, HistLine           ; history string ptr
                mov     edi, ebx                ; Input Buffer
                mov     edx, eax                ; BufferSize
                xor     ecx, ecx
                mov     esi, ecx                ; current position
    .next_char:
                call    InChar
                cmp     al, 0x1B                ; ESC ?
                jnz     .tab
                call    translate_key_seq

    .tab:       cmp     al, 0x09                ; TAB ?
                jnz     .bs
                call    FilenameCompletion      ; ファイル名補完
                call    DispLine
                jmp     short .next_char

    .bs:        cmp     al, 127                 ; BS (linux console) ?
                je      .bs_0
                cmp     al, 0x08                ; BS ?
                jnz     .delete
    .bs_0:      test    esi, esi                ; if cp=0 then next_char
                jz      .next_char
                dec     esi
                mov     ebx, CURSOR_LEFT
                call    OutPString
                jmp     short .del1

    .delete:
                cmp     al, 0x04                ; ^D ?
                jnz     .cursor_left
    .del1:
                cmp     esi, ecx                ; if cp < eol then del2
                jb      .del2
                jmp     short .next_char
    .del2:
                call    DeleteAtCursor
                jmp     short .next_char

    .cursor_left:
                cmp     al, 0x02                ; ^B
                jnz     .cursor_right
                test    esi, esi                ; if cp = 0 then next_char
                jz      .next_char
                call    CursorLeft
    .next_char2:
                jmp     short .next_char

    .cursor_right:
                cmp     al, 0x06                ; ^F
                jnz     .forward
                cmp     ecx, esi                ; if cp=eol then next_char
                je      .next_char
                call    CursorRight
                jmp     short .next_char2

    .forward:
                cmp     al, 0x0E                ; ^N
                jnz     .backward
                call    regist_history          ; 入力中の行をヒストリへ
                xor     eax, eax
                inc     eax                     ; +1
                call    next_history
                jmp     short .disp

    .backward:
                cmp     al, 0x10                ; ^P
                jnz     .enter_key
                call    regist_history          ; 入力中の行をヒストリへ
                xor     eax, eax
                dec     eax                     ; -1
                call    next_history
    .disp:
                and     eax, 0x0F               ; ヒストリは 0-15
                mov     [ebp], eax              ; HistLine
                call    history2input           ; ヒストリから入力バッファ
                call    DispLine
                jmp     short .next_char2

    .enter_key:
                cmp     al, 0x0A                ; enter ?
                jz      .in_exit
                cmp     al, 0x20
                jb      .next_char2             ; illegal chars

    .in_printable:
                inc     ecx
                inc     esi
                cmp     ecx, edx                ; buffer size
                jae     .in_toolong
                cmp     esi, ecx
                jb      .insert
                call    OutChar
                mov     [edi + esi-1], al
    .next_char3:
                jmp     short .next_char2
    .insert:
                call    OutChar
                push    eax
                push    ecx                     ; p = eol
                dec     ecx
    .ins1       cmp     esi, ecx        ; while(p=>cp){buf[p]=buf[p-1]; p--}
                ja      .ins2
                mov     al, [edi + ecx - 1]
                mov     [edi + ecx], al
                dec     ecx
                jmp     short .ins1
    .ins2:
                pop     ecx
                pop     eax
                mov     [edi + esi - 1] ,al
                call    print_line_after_cp
                jmp     short .next_char3

    .in_toolong:
                dec     ecx
                dec     esi
                jmp     short .next_char3

    .in_exit:
                push    ecx
                call    regist_history
                pop     ecx
                call    NewLine
                mov     [esp+28], ecx           ; eax に文字数を返す
                popa
                ret

    ;----------------------------------
    ; カーソル左1文字 （UTF-8対応）
    ;----------------------------------
    CursorLeft:
                mov     ebx, CURSOR_LEFT
                call    OutPString
    .loop:      dec     esi
                mov     al, [edi + esi]
                and     al, 0xC0
                jns     .ascii                  ; ASCIIなら1バイトだけ
                cmp     al, 0x80                ; 第2バイト以降の文字?
                je      .loop
                mov     ebx, CURSOR_LEFT        ; 日本語は2回右
                call    OutPString
    .ascii:
                ret

    ;----------------------------------
    ; カーソル右1文字 （UTF-8対応）
    ;----------------------------------
    CursorRight:
                mov     ebx, CURSOR_RIGHT
                call    OutPString
                xor     ebx, ebx
                mov     al, [edi + esi]
                and     al, 0xF0
                js      .mb                     ; 多バイト文字の場合
                inc     esi                     ; ASCIIなら1バイトだけ
                ret
    .mb:
                inc     esi
                shl     al, 1
                jns     .exit
                jmp     short .mb
    .exit:
                mov     ebx, CURSOR_RIGHT       ; 日本語は2回右
                call    OutPString
                ret

    ;----------------------------------
    ; カーソル位置1文字削除 （UTF-8対応）
    ;----------------------------------
    DeleteAtCursor:
                mov     ebx, DEL_AT_CURSOR
                call    OutPString
                push    edi
                add     edi, esi
                xor     ebx, ebx
                mov     al, [edi + ebx]
                and     al, 0xF0
                js      .count
                inc     ebx
                jmp     short .done             ; ASCIIなら1バイト
    .count:     ; 1文字のバイト数をカウント
                inc     ebx
                shl     al, 1
                jns     .mb_done
                jmp     short .count
    .mb_done:   push    ebx
                mov     ebx, DEL_AT_CURSOR
                call    OutPString
                pop     ebx
    .done:
                pop     edi
                ; 1文字のバイト数を削除
    .next:      sub     ecx, ebx
                push    edi
                push    ecx
                add     ecx, edi        ; ecx = 行末アドレス
                add     edi, esi        ; edi = 文字ポインタのアドレス
    .del:       cmp     edi, ecx
                je      .done2
                mov     al, [edi+ebx]
                mov     [edi], al
                inc     edi
                jmp     short .del
    .done2:
                pop     ecx
                pop     edi
                ret

;-------------------------------------------------------------------------
;  入力バッファをプロンプト直後の位置から表示してカーソルは最終
;  entry  edi : 入力バッファの先頭アドレス
DispLine:
                call    LineTop                 ; カーソルを行先頭に
                mov     eax, edi
                call    OutAsciiZ               ; 入力バッファを表示
                mov     ebx, CLEAR_EOL
                call    OutPString
                call    StrLen
                mov     ecx, eax                ; 入力文字数更新
                mov     esi, ecx                ; 入力位置更新
                ret

;-------------------------------------------------------------------------
;  ファイル名補完機能
;  entry  esi : 次に文字が入力される入力バッファ中の位置
;         edi : 入力バッファの先頭アドレス
FilenameCompletion:
                pusha
                add     esi, edi
                mov     ecx, esi            ; (入力済み位置+1)をコピー
                mov     byte[esi], 0        ; 入力済み文字列末をマーク
                mov     eax, FileNameBuffer ; FileNameBuffer初期化
                mov     [FNBPointer], eax   ; FNBPointer=FileNameBuffer
                xor     eax, eax
                mov     [FNCount], eax      ; FNCount=0
                ; 部分パス名の先頭を捜す
    .nextch:
                cmp     byte[esi], ' '      ; 空白はパス名の区切り
                je      .found              ; 空白なら次の処理
                cmp     byte[esi], '"'      ; 二重引用符もパス名の区切り
                je      .found              ; 二重引用符でも次の処理
                cmp     esi, edi            ; 行頭をチェック
                je      .found2             ; 行頭なら次の処理
                dec     esi                 ; 後ろから前に検索
                jmp     short .nextch       ; もう一つ前を調べる

    .found:     inc     esi                 ; 発見したので先頭に設定
    .found2:    cmp     [esi], al           ; al=0
                jne     .path
                popa                        ; 何もない(長さ0)なら終了
                ret

    .path:      dec     ecx                 ; 入力済み文字列最終アドレス
                cmp     byte[ecx], '/'      ; ディレクトリ部分を抽出
                je      .pathend            ; 区切り発見
                cmp     esi, ecx            ; ディレクトリ部分がない?
                jne     .path
                jmp     short .pathend2
    .pathend:   inc     ecx                 ; ファイル名から/を除く
    .pathend2:  ; ディレクトリ名をコピー
                mov     ebx, DirName        ; ディレクトリ保存アドレス
                mov     byte[ebx], 0
                mov     [PartialName], ecx  ; 部分ファイル名先頭
                sub     ecx, esi
                je      .skip               ; ディレクトリ部分がない
                push    edi
                mov     edi, ebx            ; ディレクトリ保存アドレス
                rep movsb                   ; コピー
                mov     byte[edi], 0        ; 文字列末をマーク
                pop     edi
    .skip:
                mov     al, [ebx]           ; ディレクトリ部分の最初の文字
                test    al, al              ; 長さ 0 か?
                jne     .list
                mov     ebx, current_dir    ; ディレクトリ部分がない時
    .list:      call    fropen              ; ディレクトリオープン
                js      near .exit0
                mov     esi, eax            ; fd
    .getdents:  ; ディレクトリエントリを取得
                mov     ebx, esi            ; esi : fd
                mov     ecx, dir_ent
                mov     edx, size_dir_ent
                mov     eax, SYS_getdents
                int     0x80
                mov     edi, ecx            ; edi : struct top (dir_ent)
                test    eax, eax            ; valid buffer length
                js      near .exit0         ; システムコールエラー
                je      .checkfile          ; 終了
                mov     ebp, eax            ; ebp : buffer size
    .next:
                call    GetFileStat
                mov     eax, [file_stat.st_mode]
                and     eax, S_IFDIR
                lea     ebx, [edi+10]       ; ファイル名先頭アドレス
                call    CopyFilename        ; 一致するファイル名を収集
                movzx   eax, word[edi+8]    ; rec_len レコード長
                sub     ebp, eax            ; buffer_size - rec_len
                je      .getdents           ; 次のディレクトリエントリ取得
                add     edi, eax
                jmp     short .next         ; 次のファイル

    .checkfile: ;
                call    Selection           ; ファイルが複数なら表示
                mov     ebp, FNArray
                mov     eax, [PartialName]  ; 部分ファイル名までは一致
                call    StrLen
                mov     edx, eax            ; 部分ファイル名長
                mov     ecx, [FNCount]      ; ファイル数
                or      ecx, ecx
                je      .none               ; 一致するファイル名なし
                dec     ecx
                je      .insert             ; ひとつだけ一致

                ; 複数が一致している場合なるべく長く補完
                xor     edx, edx
    .nextch1:
                mov     ecx, [FNCount]      ; ファイル数
                dec     ecx
                mov     edi, [ebp]          ; edi = FNArray[0]
                add     edi, eax
                mov     bh, [edi + edx]     ; bh = (FNArray[0] + eax + edx)
    .loop:      mov     edi, [ecx*4 + ebp]  ; bl = (FNArray[ecx] + eax + edx)
                add     edi, eax
                mov     bl, [edi + edx]
                cmp     bh, bl
                jne     .partially          ; 異なる文字発見
                dec     ecx
                cmp     cl, 1               ; FNArray[0]は処理済
                jae     .loop               ; すべてのファイル名
                inc     edx
                jmp     short .nextch1

    .partially:
                or      edx, edx
                je      .exit               ; 複数あるが追加補完不可
                mov     ebx, [esp+4]        ; 入力バッファ追加位置(esi)
                mov     ecx, [esp]          ; 入力バッファ先頭(edi)
    .nextch2:
                mov     al, [edi]           ; ファイル名をコピー
                mov     [ecx+ebx], al       ; 入力バッファ
                dec     edx
                je      .done1
                inc     ebx
                inc     edi
                jmp     short .nextch2

    .none:      ; 一致するファイル名なし
                mov     edi, NoCompletion   ; <none>
                jmp     short .insert1      ; <none>を入力バッファに挿入

    .insert:    ; 完全に一致
                mov     edi, [ebp]          ; edi = FNArray[0]
                add     edi, edx            ; 部分ファイル名長だけ進める
    .insert1:   mov     ebx, [esp+4]        ; 入力バッファ追加位置(esi)
                mov     ecx, [esp]          ; 入力バッファ先頭(edi)
    .nextch3:   mov     al, [edi]           ; ファイル名をコピー
                mov     [ecx+ebx], al
                or      al, al              ; 文字列末の0で終了
                je      .done
                inc     ebx
                inc     edi
                jmp     short .nextch3

    .done1:     xor     eax, eax
                inc     ebx
                mov     [ecx+ebx], al       ; 入力バッファ末に0を追加
    .done:
                mov     [esp+4], ebx        ; 次に入力される入力バッファ中の位置(esi)
                mov     [esp+24], ebx       ; 入力バッファ中の文字数(ecx)
                jmp     short .exit

    .exit0:
%ifndef SMALL_VTL
                call    SysCallError
%endif
    .exit:      mov     ebx, esi            ; fd
                call    fclose
                popa
                ret

%assign     S_IFDIR     0040000q

;--------------------------------------------------------------
; ディレクトリ中で一致したファイル名をファイル名バッファに書き込む
; entry eax : ディレクトリフラグ
;       ebx : ファイル名先頭アドレス
;       ecx : 部分ファイル名先頭
;--------------------------------------------------------------
CopyFilename:
                pusha
                mov     edx, FNCount    ; 登録ファイル数
                mov     eax, [edx]      ; 登録ファイル数
                cmp     eax, MAX_FILE
                jae     .exit
                mov     esi, ebx        ; ファイル名先頭アドレス
                mov     ecx, [PartialName]
    .next:      mov     al, [ecx]       ; 部分ファイル名
                or      al, al
                je      .ok
                cmp     al, [ebx]       ; ファイル名
                jne     .exit
                inc     ebx
                inc     ecx
                jmp     short .next
    .ok:
                mov     ebp, FNBPointer
                mov     edi, [ebp]
                mov     eax, esi        ;
                call    StrLen          ; ファイル名の長さを求める
                mov     ecx, eax
                inc     eax             ; 文字列末の/
                inc     eax             ; 文字列末の0
                add     eax, edi        ; 追加時の最終位置
                cmp     eax, ebp        ; FileNameBufferの直後
                jae     .exit           ; バッファより大きくなる
                mov     eax, [edx]      ; FNArray[FNCount++]=edi
                mov     [eax*4 + FNArray], edi
                inc     eax
                mov     [edx], eax      ; ファイル名数の更新
                rep     movsb           ; ファイル名のコピー
                mov     eax, [esp+28]   ; ディレクトリフラグ(eax)
                or      eax, eax        ; ディレクトリ名なら"/"付加
                je      .file
    .dir:       mov     byte[edi], '/'
                inc     edi
    .file:      mov     byte[edi], 0    ; セパレータ(0)を書く
                inc     edi
                mov     [ebp], edi      ; 最終位置(FNBPointer)更新
    .exit:
                popa
                ret

;--------------------------------------------------------------
; ファイル名バッファの内容表示
Selection:
                pusha
                mov     ecx, [FNCount]
                or      ecx, ecx
                je      .exit           ; 0個なら非表示
                dec     ecx
                je      .exit           ; 1個なら非表示
                inc     ecx
                call    NewLine
                xor     ebx, ebx
    .loop:      mov     edi, [ebx*4 + FNArray]
                mov     eax, ebx
                push    ecx
                xor     ecx, ecx
                mov     cl, 4           ; 4桁
                call    PrintRight      ; 番号表示
                pop     ecx
                mov     al, ' '
                call    OutChar
                mov     eax, edi
                call    OutAsciiZ       ; ファイル名表示
                call    NewLine
                inc     ebx
                loop    .loop
    .exit:      popa
                ret

;--------------------------------------------------------------
; entry
;   edi+10 : ファイル名保存アドレス
;   DirName にディレクトリ名
;--------------------------------------------------------------
GetFileStat:
                pusha
                mov     ebx, PathName
                lea     edx, [edi+10]       ; edx = edi+10
                mov     ecx, MAXLINE
                mov     edi, ebx            ; PathName
                mov     eax, DirName        ; ディレクトリ保存アドレス
                mov     esi, eax
                call    StrLen
                mov     ecx, eax
                rep     movsb
                mov     esi, edx
                mov     eax, esi
                call    StrLen
                mov     ecx, eax
                rep     movsb
                mov     byte[edi], 0
                mov     eax, SYS_lstat
                mov     ecx, file_stat
                int     0x80
                popa
                ret

;--------------------------------------------------------------
get_cursor_position:
                pusha
                mov     ebx, CURSOR_REPORT
                call    OutPString
                call    InChar              ; 返り文字列
                cmp     al, 0x1B            ; ^[[y;xR
                jne     .exit
                call    InChar
                cmp     al, '['
                jne     .exit
                call    get_decimal         ; Y
                mov     ecx, ebx
                call    get_decimal         ; X
                dec     ebx
                mov     [FLOATING_TOP], ebx ; 左マージン
    .exit:      popa
                ret
get_decimal:
                xor     ebx, ebx
                call    InChar
                sub     eax, '0'
    .gd_loop:
                imul    ebx, 10             ;
                add     ebx, eax
                call    InChar
                sub     al, '0'
                cmp     eax, 9
                jle     .gd_loop
                ret

;--------------------------------------------------------------
print_line_after_cp:
                push    eax
                push    edx
                mov     ebx, SAVE_CURSOR
                call    OutPString
                mov     ebx, CLEAR_EOL
                call    OutPString
                lea     eax, [esi+edi]
                mov     edx, ecx
                sub     edx, esi
                call    OutString
                mov     ebx, RESTORE_CURSOR
                call    OutPString
                pop     edx
                pop     eax
                ret

;--------------------------------------------------------------
translate_key_seq:
                call    InChar
                cmp     al, '['
                jnz     .exit
                call    InChar
    .tk0:       cmp     al, 'A'
                jnz     .tk1
                mov     al, 'P' - 0x40          ; ^P
                ret
    .tk1:       cmp     al, 'B'
                jnz     .tk2
                mov     al, 'N' - 0x40          ; ^N
                ret
    .tk2:       cmp     al, 'C'
                jnz     .tk3
                mov     al, 'F' - 0x40          ; ^F
                ret
    .tk3:       cmp     al, 'D'
                jnz     .tk4
                mov     al, 'B' - 0x40          ; ^B
                ret
    .tk4:       cmp     al, '3'
                jnz     .tk5
                jmp     short .tk5_1
    .tk5:       cmp     al, '4'
                jnz     .exit
    .tk5_1:     call    InChar
                cmp     al, '~'
                mov     al, 4                   ; ^D
                ret
    .exit       mov     al, 0
                ret

;--------------------------------------------------------------
; 入力バッファをヒストリへ登録
;--------------------------------------------------------------
regist_history:
                mov     byte [edi + ecx], 0
                call    check_history
                jae     .exit                   ; 同一行登録済み
                mov     eax, [ebp+4]            ; HistUpdate
                call    input2history
                mov     eax, [ebp+4]            ; HistUpdate
                inc     eax
                and     eax, 0x0F
                mov     [ebp+4], eax            ; HistUpdate
                mov     [ebp], eax              ; HistLine
    .exit:      ret

;--------------------------------------------------------------
; ヒストリを eax (1または-1) だけ進める
;--------------------------------------------------------------
next_history:
                push    edx                     ; buffer size
                push    ebx
                mov     ebx, [ebp]              ; HistLine
                mov     edx, MAXHISTORY
    .next:      dec     edx
                je      .exit                   ; すべて空なら終了
                push    eax
                add     ebx, eax
                and     ebx, MAXHISTORY-1
                mov     eax, ebx
                call    GetHistory
                call    StrLen
                or      eax, eax
                pop     eax
                je      .next
    .exit:      mov     eax, ebx
                pop     ebx
                pop     edx                     ; buffer size
                ret

;--------------------------------------------------------------
; 入力バッファと同じ内容のヒストリバッファがあるかチェック
;   edi : input buffer
;--------------------------------------------------------------
check_history:
                pusha
                mov     ebp, edi                ; input buffer top
                mov     esi, history0
                mov     ecx, MAXHISTORY
    .nextline:
                mov     edi, ebp                ; input buffer top
                xor     ebx, ebx
    .nextchar:  mov     al, [edi]
                cmp     al, [esi+ebx]
                jne     .neq
                test    al, al
                je      .equal
                inc     edi
                inc     ebx
                jmp     .nextchar
    .neq:
                add     esi, MAXLINE
                loop    .nextline
                stc
                jmp     short .exit
    .equal:
                clc
    .exit       popa
                ret

;--------------------------------------------------------------
; 入力バッファのインデックスをアドレスに変換
;   enter  eax : ヒストリバッファのインデックス (0..15)
;   exit   eax : historyinput buffer top address
;--------------------------------------------------------------
GetHistory:
                push    edx
                mov     ecx, MAXLINE
                mul     ecx
                add     eax, history0
                pop     edx
                ret

;--------------------------------------------------------------
; 入力バッファからヒストリバッファへコピー
;   eax : ヒストリバッファのインデックス (0..15)
;   edi : input buffer
;--------------------------------------------------------------
input2history:
                push    esi
                push    edi
                mov     esi, edi
                call    GetHistory
                mov     edi, eax
                jmp     short history2input.loop

;--------------------------------------------------------------
; ヒストリバッファから入力バッファへコピー
;   eax : ヒストリバッファのインデックス (0..15)
;   edi : input buffer
;--------------------------------------------------------------
history2input:
                push    esi
                push    edi
                call    GetHistory
                mov     esi, eax
    .loop:      mov     al, [esi]
                mov     [edi], al
                cmp     al, 0
                je      .done
                inc     esi
                inc     edi
                loop    .loop
    .done:
                pop     edi
                pop     esi
                ret

;--------------------------------------------------------------
; 行先頭にカーソルを移動(左マージン付)
LineTop:
                push    ecx
                mov     ebx, CURSOR_TOP
                call    OutPString
                mov     ebx, CURSOR_RIGHT
                mov     ecx, [FLOATING_TOP] ; 左マージン
                or      ecx, ecx
                je      .exit
    .next:      call    OutPString
                loop    .next
    .exit:      pop     ecx
                ret

;--------------------------------------------------------------
; 現在の termios を保存
GET_TERMIOS:
                pusha
                mov     esi, old_termios
                mov     edi, new_termios
                mov     ebx, esi            ; old_termios
                call    tcgetattr
                mov     ecx, edi            ; new_termios
                sub     ecx, esi
        rep     movsb
                popa
                ret

;--------------------------------------------------------------
; 新しい termios を設定
; Rawモード, ECHO 無し, ECHONL 無し
; VTIME=0, VMIN=1 : 1バイト読み取られるまで待機
SET_TERMIOS:
                pusha
                mov     edi, new_termios.c_lflag
                mov     eax, [edi]
                and     eax, ~ICANON & ~ECHO & ~ECHONL
                or      eax, ISIG
                mov     [edi], eax
                xor     eax, eax
                inc     eax
                mov     edi, new_termios.c_cc
                mov     [edi + VMIN], al    ; 1
                dec     eax
                mov     [edi + VTIME], al   ; 0
                mov     ebx, new_termios
                call    tcsetattr
                popa
                ret

;--------------------------------------------------------------
; 現在の termios を Cooked モードに設定
; Cookedモード, ECHO あり, ECHONL あり
; VTIME=1, VMIN=0
SET_TERMIOS2:
                pusha
                mov     edi, new_termios.c_lflag
                mov     eax, [edi]
                and     eax, ICANON | ECHO | ECHONL
                or      eax, ISIG
                mov     [edi], eax
                xor     eax, eax
                mov     edi, new_termios.c_cc
                mov     [edi + VMIN], al    ; 0
                inc     eax
                mov     [edi + VTIME], al   ; 1
                mov     ebx, new_termios
                call    tcsetattr
                popa
                ret

;--------------------------------------------------------------
; 保存されていた termios を復帰
RESTORE_TERMIOS:
                pusha
                mov     ebx, old_termios
                call    tcsetattr
                popa
                ret

;--------------------------------------------------------------
; 標準入力の termios の取得と設定
; tcgetattr(&termios)
; tcsetattr(&termios)
; eax : destroyed
; ebx : termios buffer adress
; ecx, edx : destroyed
tcgetattr:
                mov     eax, TCGETS
                jmp     short IOCTL

tcsetattr:
                mov     eax, TCSETS

;--------------------------------------------------------------
; 標準入力の ioctl の実行
; sys_ioctl(unsigned int fd, unsigned int cmd,
;           unsigned long arg)
; eax : cmd
; ebx : buffer adress
IOCTL:
                mov     ecx, eax            ; set cmd
                mov     edx, ebx            ; set arg
                mov     eax, SYS_ioctl      ; sys_ioctl
                xor     ebx, ebx            ; 0 : to stdin
                int     0x80                ; call kernel
                ret

;------------------------------------
; input 1 character from stdin
; eax : get char (0:not pressed)
RealKey:
                pusha
                mov     edi, new_termios.c_cc
                mov     [edi + VMIN], byte 0    ; 0
                mov     ebx, new_termios
                call    tcsetattr
                push    eax                 ; work buffer on stack
                xor     ebx, ebx            ; 0:from stdin
                mov     ecx, esp            ; into Input Buffer
                mov     edx, ebx
                inc     edx                 ; 1 char
                mov     eax, SYS_read
                int     0x80                ; call kernel
                pop     ebx                 ; set char
                test    eax, eax            ; if 0 then empty
                je      .nohit
                mov     eax, ebx            ; char code
    .nohit:     mov     [esp+28], eax       ; return eax with key
                mov     [edi + VMIN], byte 1; 1
                mov     ebx, new_termios
                call    tcsetattr
                popa
                ret

;------------------------------------
; get window size
; eax : column(upper 16bit), raw(lower 16bit)
WinSize:        push    ebx
                push    ecx
                push    edx
                mov     eax, SYS_ioctl
                mov     ebx, 0          ; to stdout
                mov     ecx, TIOCGWINSZ ; get wondow size
                mov     edx, wsize
                int     0x80            ; call kernel
                xor     eax, eax
                mov     ax, [edx + winsize.ws_col]
                mov     cl, 16
                shl     eax, cl
                mov     ax, [edx + winsize.ws_row]
                pop     edx
                pop     ecx
                pop     ebx
                ret

;-------------------------------------------------------------------------
; ファイルをオープン
; enter   ebx: 第１引数 filename
; return  eax: fd, if error then eax will be negative.
;-------------------------------------------------------------------------
fropen:
                mov     ecx, O_RDONLY       ; 第２引数 flag
                jmp     short fopen
fwopen:
                mov     ecx, O_CREAT | O_WRONLY | O_TRUNC
fopen:          mov     eax, SYS_open       ; システムコール番号
                mov     edx, 0644q          ; 第３引数 mode
                int     0x80
                test    eax,eax             ; eax <- fd
                ret

;-------------------------------------------------------------------------
; ファイルをクローズ
; enter   ebx: 第１引数 ファイルディスクリプタ
;-------------------------------------------------------------------------
fclose:         mov     eax, SYS_close      ; システムコール番号
                int     0x80
                ret


;==============================================================
section .data

FLOATING_TOP    dd      0         ; No. of prompt characters
HistLine        dd      0
HistUpdate      dd      0
CURSOR_REPORT   db      4, 0x1B, "[6n"
SAVE_CURSOR     db      2, 0x1B, '7'             ; ^[7
RESTORE_CURSOR  db      2, 0x1B, '8'             ; ^[8
DEL_AT_CURSOR   db      4, 0x1B, "[1P"           ; ^[[1P
CURSOR_RIGHT    db      4, 0x1B, "[1C"           ; ^[[1C
CURSOR_LEFT     db      4, 0x1B, "[1D"           ; ^[[1D
CURSOR_TOP      db      1, 0x0D
CLEAR_EOL       db      4, 0x1B, "[0K"           ; ^[[0K
CSI             db      2, 0x1B, '['             ; ^[[
NoCompletion    db      "<none>",0
current_dir     db      './',0

;==============================================================
section .bss

input           resb MAXLINE
history0        resb MAXLINE * MAXHISTORY

DirName         resb MAXLINE
PathName        resb MAXLINE

PartialName     resd 1          ; 部分ファイル名先頭アドレス格納
FileNameBuffer  resd 512        ; 2kbyte for filename completion
FNBPointer      resd 1          ; FileNameBufferの格納済みアドレス+1
FNCount         resd 1          ; No. of Filenames
FNArray         resd MAX_FILE   ; *Filename[0..255]

old_termios istruc termios
                .c_iflag            resd   1       ; input mode flags
                .c_oflag            resd   1       ; output mode flags
                .c_cflag            resd   1       ; control mode flags
                .c_lflag            resd   1       ; local mode flags
                .c_line             resb   1       ; line discipline
                .c_cc               resb   NCCS    ; control characters
            iend

new_termios istruc termios
                .c_iflag            resd   1       ; input mode flags
                .c_oflag            resd   1       ; output mode flags
                .c_cflag            resd   1       ; control mode flags
                .c_lflag            resd   1       ; local mode flags
                .c_line             resb   1       ; line discipline
                .c_cc               resb   NCCS    ; control characters
            iend
new_termios_end:

new_sig     istruc sigaction
                .sighandler         resd    1
                .sa_mask            resd    1
                .sa_flags           resd    1
                .sa_restorer        resd    1
            iend

old_sig     istruc sigaction
                .sighandler         resd    1
                .sa_mask            resd    1
                .sa_flags           resd    1
                .sa_restorer        resd    1
            iend

TV          istruc timeval
                .tv_sec             resd    1
                .tv_usec            resd    1
            iend

TZ          istruc timeval
                .tz_minuteswest     resd    1
                .tz_dsttime         resd    1
            iend

ru          istruc  rusage
                .ru_utime_tv_sec    resd  1 ; user time used
                .ru_utime_tv_usec   resd  1 ;
                .ru_stime_tv_sec    resd  1 ; system time used
                .ru_stime_tv_usec   resd  1 ;
                .ru_maxrss          resd  1 ; maximum resident set size
                .ru_ixrss           resd  1 ; integral shared memory size
                .ru_idrss           resd  1 ; integral unshared data size
                .ru_isrss           resd  1 ; integral unshared stack size
                .ru_minflt          resd  1 ; page reclaims
                .ru_majflt          resd  1 ; page faults
                .ru_nswap           resd  1 ; swaps
                .ru_inblock         resd  1 ; block input operations
                .ru_oublock         resd  1 ; block output operations
                .ru_msgsnd          resd  1 ; messages sent
                .ru_msgrcv          resd  1 ; messages received
                .ru_nsignals        resd  1 ; signals received
                .ru_nvcsw           resd  1 ; voluntary context switches
                .ru_nivcsw          resd  1 ; involuntary
            iend

dir_ent     istruc dirent
                .d_ino      resd  1  ;
                .d_off      resd  1  ;
                .d_reclen   resw  1  ;
                .d_name     resb 256 ;
            iend

size_dir_ent    equ         $ - dir_ent

file_stat   istruc stat
                .st_dev     resw    1
                .__pad1     resw    1
                .st_ino     resd    1
                .st_mode    resw    1
                .st_nlink   resw    1
                .st_uid     resw    1
                .st_gid     resw    1
                .st_rdev    resw    1
                .__pad2     resw    1
                .st_size    resd    1
                .st_blksize resd    1
                .st_blocks  resd    1
                .st_atime   resd    1
                .__unused1  resd    1
                .st_mtime   resd    1
                .__unused2  resd    1
                .st_ctime   resd    1
                .__unused3  resd    1
                .__unused4  resd    1
                .__unused5  resd    1
            iend

%endif
