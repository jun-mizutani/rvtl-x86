;-------------------------------------------------------------------------
;  Return of the Very Tiny Language
;  file : rvtl.asm
;  version : 3.05  2015/10/05
;  Copyright (C) 2002-2015 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;  RVTL may be copied under the terms of the GNU General Public License.
;
; build :
;   nasm -f elf rvtl.asm
;   ld -s -o rvtl rvtl.o
;
; build small rvtl :
;   nasm -f elf rvtl.asm -dSMALL_VTL
;   ld -s -o rvtls rvtl.o
;
;-------------------------------------------------------------------------

%include        "vtllib.inc"
%include        "mt19937.inc"

%define VTL_LABEL

%ifdef  SMALL_VTL
  %undef  FRAME_BUFFER
  %undef  DETAILED_MSG
  %define NO_FB
%else
  %define DETAILED_MSG
  %include      "syserror.inc"
%endif

%ifndef  NO_FB
  %define FRAME_BUFFER
  %include      "fblib.inc"
%endif

%ifdef  DEBUG
%include        "debug.inc"
%endif

%assign         ARGMAX      15
%assign         VSTACKMAX   1024
%assign         MEMINIT     256*1024
%assign         LSTACKMAX   127
%assign         FNAMEMAX    256
%assign         LABELMAX    1024
%assign         VERSION     30500
%assign         CPU         1

;==============================================================
section .text
global _start

;-------------------------------------------------------------------------
; システムの初期化
;-------------------------------------------------------------------------
_start:
                mov     edi, argc
                pop     ebx                     ; ebx = argc
                mov     [edi], ebx              ; argc 引数の数を保存
                mov     [edi + 4], esp          ; argvp 引数配列先頭を保存
                lea     eax, [esp+ebx*4+4]      ; 環境変数アドレス取得
                mov     [edi + 8], eax          ; envp 環境変数領域の保存

                mov     eax, [edi]              ; argc
                mov     esi, [edi + 4]          ; argvp
                mov     ecx, 1
                cmp     eax, ecx
                je      .L4                     ; 引数なしならスキップ
    .L1:        mov     ebx, [esi + ecx * 4]    ; ip = argvp[r3]
                mov     dl, [ebx]
                inc     ecx
                cmp     ecx, eax
                je      .L3
                cmp     dl, '-'                 ; 「-」か？
                jne     .L1
                dec     ecx
                mov     [edi], ecx              ; argc 引数の数を更新
                inc     ecx
    .L3         lea     edx, [esi + ecx*4]
                mov     [edi + 16], edx         ; vtl用の引数への配列先頭
                sub     eax, ecx
                mov     [edi + 12], eax         ; vtl用の引数の個数 (argc_vtl0)

    .L4:        ; argv[0]="xxx/rvtlw" ならば cgiモード
                xor     edx, edx
                mov     ebx, cginame            ; 文字列 'wltvr',0
                mov     ecx, [esi]              ; argv[0]
    .L5:        mov     al, [ecx]
                inc     ecx
                cmp     al, 0
                jne     .L5
                sub     ecx, 2                  ; 文字列の最終文字位置(w)
    .L6:        mov     al, [ecx]
                mov     ah, [ebx]
                inc     ebx
                dec     ecx
                cmp     ah, 0
                je      .L7                     ; found
                cmp     al, ah
                jne     .L8                     ; no
                jmp     short .L6
    .L7:        inc     edx                     ; edx = 1
    .L8:        mov     [cgiflag], edx

                call    GET_TERMIOS             ; termios の保存
                call    SET_TERMIOS             ; 端末のローカルエコーOFF

                mov     ebp, VarArea            ; サイズ縮小のための準備
                xor     ebx, ebx                ; 0 を渡して現在値を得る
                mov     eax, SYS_brk            ; ヒープ先頭取得
                int     0x80
                xor     ecx, ecx
                mov     ebx, eax                ; ヒープにコードも配置
                mov     edx, eax
                mov     cl, ','                 ; アクセス可能領域先頭
                mov     dword[ebp+ecx*4], eax
                mov     cl, '='                 ; プログラム先頭
                mov     dword[ebp+ecx*4], eax
                add     eax, 4                  ; ヒープ先頭
                mov     cl, '&'
                mov     dword[ebp+ecx*4], eax
                add     ebx, MEMINIT            ; ヒープ末(brk)設定
                mov     cl, '*'                 ; RAM末設定
                mov     [ebp+ecx*4], ebx
                mov     eax, SYS_brk            ; brk
                int     0x80
                xor     eax, eax
                dec     eax
                mov     [edx] ,eax              ; コード末マーク

                mov     eax, 672274774          ; 初期シード値
                mov     cl, '`'                 ; 乱数シード設定
                mov     [ebp+ecx*4], eax
                call    sgenrand

                xor     ebx, ebx                ; シグナルハンドラ設定
                mov     eax, SigIntHandler
                mov     [new_sig.sighandler], eax
                mov     [new_sig.sa_mask], ebx
                mov     eax, SA_NOCLDSTOP       ; 子プロセス停止を無視
                mov     [new_sig.sa_flags], eax
                mov     [new_sig.sa_restorer], ebx
                mov     eax, SYS_sigaction
                mov     ebx, SIGINT             ; ^C
                mov     ecx, new_sig
                mov     edx, old_sig
                int     0x80

                mov     eax, SIG_IGN            ; シグナルの無視
                mov     [new_sig.sighandler], eax
                mov     eax, SYS_sigaction
                mov     ebx, SIGTSTP            ; ^Z
                int     0x80

                mov     eax, SYS_getpid
                int     0x80
                mov     [ebp-24], eax           ; pid の保存
                dec     eax
                ja      .not_init
                push    edi
                mov     edi, envp               ; pid=1 なら環境変数設定
                mov     dword[edi], env         ; envp 環境変数
                pop     edi
                mov     ebx, initvtl            ; /etc/init.vtl
                call    fropen                  ; open
                jle     .not_init               ; 無ければ継続
                mov     [ebp-8], eax            ; FileDesc
                call    WarmInit2
                mov     byte[ebp-4], 1          ; Read from file
                mov     byte[ebp-2], 1          ; EOL=yes
                jmp     short Launch
    .not_init:
                call    WarmInit2
                xor     eax, eax
                mov     [counter], eax          ; コマンド実行カウント初期化
                mov     [current_arg], eax      ; 処理済引数カウント初期化
                call    LoadCode                ; あればプログラムロード
                jg      Launch                  ; メッセージ無し
%ifndef SMALL_VTL
                ; 起動メッセージを表示
                mov     eax, start_msg          ; 起動メッセージ
                call    OutAsciiZ
%endif

Launch:         ; 初期化終了
                mov     [save_stack], esp

;-------------------------------------------------------------------------
; メインループ
;-------------------------------------------------------------------------
MainLoop:
                cmp     byte[ebp-17], 1     ; SIGINT 受信?
                jne     .div0p
                call    WarmInit            ; 実行停止
                jmp     short .continue
    .div0p:     cmp     byte[ebp-18], 1     ; 0除算発生
                jne     .exp_err
                mov     eax, err_div0       ; 0除算メッセージ
                call    OutAsciiZ
                call    WarmInit            ; 実行停止
    .exp_err:   mov     bl, [ebp-19]
                cmp     bl, 0               ; 式中にエラー
                je      .continue
                push    eax                 ; スタック修正(文字コード)
                cmp     bl, 1
                jne     .ee1
                mov     eax, err_exp        ; メッセージ
                jmp     short .ee3
    .ee1:       cmp     bl, 2
                jne     .ee2
                mov     eax, err_vstack     ; メッセージ
                jmp     short .ee3
    .ee2:       mov     eax, err_label      ; メッセージ
    .ee3:       jmp     Error

    .continue:  cmp     byte[ebp-2], 0      ; EOL
                je      .not_eol
                cmp     byte[ebp-3], 1      ; ExecMode=Memory
                jne     ReadLine            ; 行取得
                jmp     ReadMem             ; メモリから行取得

    .not_eol:   call    GetChar
    .next:      cmp     al, ' '             ; 空白読み飛ばし
                jne     .done
                call    GetChar
                jmp     short .next
    .done:
                call    IsNum               ; 行番号付なら編集モード
                jb      .exec
                call    EditMode            ; 編集モード
                jmp     short MainLoop

    .exec:      inc     dword[counter]
	        call    IsAlpha
                jb      Command             ; コマンド実行
    .var        call    SetVar              ; 変数代入
MainLoop2       jmp     MainLoop

;-------------------------------------------------------------------------
; キー入力またはファイル入力されたコードを実行
;-------------------------------------------------------------------------
ReadLine:       ; 1行入力 : キー入力とファイル入力に対応
                cmp     byte[ebp-4], 0      ; Read from ?
                je      .console            ; コンソールから入力
                call    READ_FILE           ; ファイルから入力
                jmp     short .exit

    .console:   call    DispPrompt
                mov     eax, MAXLINE        ; 1 行入力
                mov     ebx, input
                call    READ_LINE           ; 編集機能付キー入力
                mov     esi, ebx
                mov     byte[ebp-2], 0      ; not EOL
    .exit:      jmp     short MainLoop2

;-------------------------------------------------------------------------
; メモリに格納されたコードを実行
;-------------------------------------------------------------------------
ReadMem:
                mov     eax, [edi]          ; JUMP先かもしれない
                inc     eax                 ; 次行オフセットが -1 か?
                je      .stop               ; コード末なら実行終了
                add     edi, [edi]          ; Next Line
                mov     eax, [edi]          ; 次行オフセット
                or      eax, eax            ; コード末？
                jns     .run
    .stop:
                call    CheckCGI            ; CGIモードなら終了
                mov     byte[ebp-3], 0      ; ExecMode=Direct
                mov     byte[ebp-2], 1      ; EOL=yes
                jmp     short MainLoop2
    .run:
                call    SetLineNo           ; 行番号を # に設定
                lea     esi, [edi+8]        ; 行のコード先頭
                mov     byte[ebp-2], 0      ; EOL=no
                jmp     short MainLoop2

;-------------------------------------------------------------------------
; 文の実行
;   文を実行するサブルーチンコール
;-------------------------------------------------------------------------
Command:
                xor     ebx, ebx
                mov     bl, al
                cmp     al, '!'
                jb      .comm2
                cmp     al, '/'
                ja      .comm2
                sub     bl,  '!'            ; ジャンプテーブル
                call    [ebx * 4 + TblComm1]
                jmp     short MainLoop2
    .comm2:     cmp     al, ':'
                jb      .comm3
                cmp     al, '@'
                ja      .comm3
                sub     bl,  ':'
                call    [ebx * 4 + TblComm2]
                jmp     MainLoop
    .comm3:     cmp     al, '['
                jb      .comm4
                cmp     al, '`'
                ja      .comm4
                sub     bl,  '['
                call    [ebx * 4 + TblComm3]
                jmp     MainLoop
    .comm4:     cmp     al, '{'
                jb      .comexit
                cmp     al, '~'
                ja      .comexit
                sub     bl,  '{'
                call    [ebx * 4 + TblComm4]
    .exit:      jmp     MainLoop
    .comexit:   cmp     al, ' '
                je      .exit
                cmp     al, 0
                je      .exit
                cmp     al, 8
                je      .exit
                jmp     short SyntaxError

;-------------------------------------------------------------------------
; 行番号をシステム変数 # に設定
;-------------------------------------------------------------------------
SetLineNo:
                mov     eax, [edi+4]        ; Line No.
                xor     ecx, ecx
                mov     cl, '#'
                mov     [ebp+ecx*4], eax    ; 行番号を # に設定
                ret

SetLineNo2:
                xor     ecx, ecx
                mov     cl, '#'
                mov     eax, [ebp+ecx*4]    ; # から旧行番号を取得
                dec     ecx
                dec     ecx
                mov     [ebp+ecx*4], eax    ; ! に行番号を設定
                mov     eax, [edi+4]        ; Line No.
                inc     ecx
                inc     ecx
                mov     [ebp+ecx*4], eax    ; 行番号を # に設定
                ret

;-------------------------------------------------------------------------
; 文法エラー
;-------------------------------------------------------------------------
LongJump:       mov     esp, [save_stack]   ; スタック復帰
                push    eax                 ; 文字コード退避
                mov     eax, err_exp        ; メッセージ
                jmp     short Error

SyntaxError:
                push    eax
                mov     eax, syntaxerr
Error:          call    OutAsciiZ
                cmp     byte[ebp-3], 0      ; ExecMode=Direct
                je      .position
                mov     eax, [edi + 4]      ; エラー行行番号
                call    PrintLeft
                call    NewLine
                lea     eax, [edi + 8]
                call    OutAsciiZ           ; エラー行表示
                call    NewLine
                sub     esi, edi
                mov     ecx, esi
                sub     ecx, 9
                je      .position
                cmp     ecx, MAXLINE
                jae     .skip
    .errloop:   mov     al, ' '             ; エラー位置設定
                call    OutChar
                loop    .errloop
    .position:  mov     eax, '^  ['
                call    OutChar4
                pop     eax
                call    PrintHex2           ; エラー文字コード表示
                mov     al, ']'
                call    OutChar
                call    NewLine

    .skip:      call    WarmInit            ; システムを初期状態に
                jmp     MainLoop

;-------------------------------------------------------------------------
; プロンプト表示
;-------------------------------------------------------------------------
DispPrompt:
                mov     eax, prompt1        ; プロンプト表示
                call    OutAsciiZ
                mov     eax, [ebp-24]       ; pid の取得
                call    PrintHex4
                mov     eax, prompt2        ; プロンプト表示
                call    OutAsciiZ
                ret

;-------------------------------------------------------------------------
; シグナルハンドラ
;-------------------------------------------------------------------------
SigIntHandler:
                mov     byte[SigInt], 1     ; SIGINT シグナル受信
                ret

;-------------------------------------------------------------------------
; シグナルによるプログラム停止時の処理
;-------------------------------------------------------------------------
RangeError:
                mov     eax, Range_msg      ; 範囲エラーメッセージ
                call    OutAsciiZ
                xor     ecx, ecx
                mov     cl, '#'             ; 行番号
                mov     eax, [ebp+ecx*4]
                call    PrintLeft
                mov     al, ','
                call    OutChar
                mov     cl, '!'             ; 呼び出し元行番号
                mov     eax, [ebp+ecx*4]
                call    PrintLeft
                call    NewLine
WarmInit:
                call    CheckCGI            ; CGIモードなら終了
WarmInit2:
                mov     byte[ebp-4], 0      ; Read from console
WarmInit1:
                xor     ecx, ecx
                xor     eax, eax
                inc     eax                 ; 1
                mov     cl, '['             ; 範囲チェックON
                mov     [ebp+ecx*4], eax
                mov     [ebp-2], al         ; EOL=yes
                dec     eax                 ; 0
                mov     edi, exarg          ; execve 引数配列初期化
                mov     [edi], eax
                mov     [ebp-19], al        ; 式のエラー無し
                mov     [ebp-18], al        ; ０除算無し
                mov     [ebp-17], al        ; SIGINTシグナル無し
                mov     [ebp-3], al         ; ExecMode=Direct
                mov     [ebp-1], al         ; LSTACK
                mov     [ebp-16], eax       ; VSTACK
                ret

;-------------------------------------------------------------------------
; 変数への代入, FOR文処理
; EAX に変数名を設定して呼び出される
;-------------------------------------------------------------------------
SetVar:         ; 変数代入
                call    SkipAlpha           ; 変数の冗長部分の読み飛ばし
                push    edi
                lea     edi, [ebp+ebx*4]    ; 変数のアドレス
                cmp     al, '='
                je      .var
                cmp     al, '('
                je      .array1
                cmp     al, '{'
                je      .array2
                cmp     al, '['
                je      .array4
                cmp     al, '*'
                je      .strptr
                pop     edi
                jmp     Com_Error

    .var:       ; 単純変数
                call    Exp                 ; 式の処理(先読み無しで呼ぶ)
                mov     [edi], eax          ; 代入
                mov     ebx, eax
                pop     edi
                xor     eax, eax
                mov     al, [esi-1]
                cmp     al, ','             ; FOR文か?
                jne     .exit
                cmp     byte[ebp-3], 0      ; ExecMode=Direct
                jne     .for
                mov     eax, no_direct_mode
                call    OutAsciiZ
                pop     ebx                 ; スタック修正
                call    WarmInit
                jmp     MainLoop
    .for:
                mov     byte[ebp-20], 0     ; 昇順
                call    Exp                 ; 終了値
                cmp     eax, ebx            ; 開始値と終了値を比較
                jge     .asc
                mov     byte[ebp-20], 1     ; 降順 (開始値 >= 終了値)
    .asc:
                call    PushValue           ; 終了値を退避(NEXT部で判定)
                call    PushLine            ; For文の直後を退避
    .exit:      ret

    .array1:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     [edi+ebx], al       ; 代入
                pop     edi
                ret

    .array2:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     [edi+ebx*2], ax     ; 代入
                pop     edi
                ret

    .array4:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     [edi+ebx*4], eax    ; 代入
                pop     edi
                ret

    .range_err:
                call    RangeError          ; アクセス可能範囲を超えた
                pop     edi
                ret

    .strptr:    call    GetChar
                mov     edi, [edi]          ; 文字列をコピー
                call    RangeCheck          ; コピー先を範囲チェック
                jb      .range_err          ; 範囲外をアクセス
                mov     al, [esi]           ; PeekChar
                cmp     al, '"'
                jne     .sp0

                xor     ecx, ecx            ; 即値文字列コピー
                call    GetChar             ; skip "
    .next:      call    GetChar
                cmp     al, '"'
                je      .done
                or      al, al
                je      .done
                mov     [edi + ecx], al
                inc     ecx
                cmp     ecx, FNAMEMAX
                jb      .next
    .done:
                xor     al, al
                mov     [edi + ecx], al
                xor     ebx, ebx
                mov     bl, '%'             ; %に文字数を保存
                mov     [ebp+ebx*4], ecx
                pop     edi
                ret

    .sp0:       call    Exp                 ; コピー元のアドレス
                cmp     edi, eax
                je      .sp3
                push    edi                 ; コピー先退避
                mov     edi, eax            ; RangeCheckはediを見る
                call    RangeCheck          ; コピー元を範囲チェック
                pop     edi                 ; コピー先復帰
                jb      .range_err          ; 範囲外をアクセス
                push    esi
                mov     esi, eax
                xor     ecx, ecx
    .sp1:
                mov     al, [esi+ecx]
                mov     [edi+ecx], al
                inc     ecx
                cmp     ecx, 256*1024       ; 256KB
                je      .sp2
                or      al, al
                jne     .sp1
    .sp2:
                dec     ecx
                xor     ebx, ebx
                mov     bl, '%'             ; %に文字数を保存
                mov     [ebp+ebx*4], ecx
                pop     esi
                pop     edi
                ret

    .sp3:       call    StrLen
                xor     ebx, ebx
                mov     bl, '%'             ; %に文字数を保存
                mov     [ebp+ebx*4], eax
                pop     edi
                ret

    .array:     call    Exp                 ; 配列インデックス
                mov     ebx, eax
                mov     edi, [edi]
                call    SkipCharExp         ; 式の処理(先読み無しで呼ぶ)
                call    RangeCheck          ; 範囲チェック
                ret

;-------------------------------------------------------------------------
; 配列のアクセス可能範囲をチェック
; , < edi < *
;-------------------------------------------------------------------------
RangeCheck:
                push    eax
                push    ebx
                push    ecx
                xor     ecx, ecx
                mov     cl, '['             ; 範囲チェックフラグ
                mov     eax, [ebp+ecx*4]
                test    eax, eax
                je      .exit               ; 0 ならチェックしない
                mov     eax, input2
                cmp     edi, eax            ; if addr=input2
                je      .exit               ; インプットバッファはOK
                mov     cl, ','             ; プログラム先頭
                mov     eax, [ebp+ecx*4]
                mov     cl, '*'             ; RAM末
                mov     ebx, [ebp+ecx*4]
                cmp     edi, eax            ; if = > addr, stc
                jb      .exit
                cmp     ebx, edi            ; if * < addr, stc
    .exit       pop     ecx
                pop     ebx
                pop     eax
                ret

;-------------------------------------------------------------------------
; 変数の冗長部分の読み飛ばし
;   変数名をebxに退避, 次の文字をeaxに返す
;   SetVar, Variable で使用
;-------------------------------------------------------------------------
SkipAlpha:
                mov     ebx, eax            ; 変数名をebxに退避
    .next:      call    GetChar
                call    IsAlpha
                jb      .exit
                jmp     short .next
    .exit:      ret

;-------------------------------------------------------------------------
; 行の編集
;   eax 行番号
;-------------------------------------------------------------------------
LineEdit:
                call    LineSearch          ; 入力済み行番号を探索
                jae     .exit
                mov     esi, input          ; 入力バッファ
                mov     eax, [edi + 4]
                call    PutDecimal          ; 行番号書き込み
                mov     al, ' '
                mov     [esi], al
                inc     esi
                add     edi, 8
    .copy:      mov     al, [edi]           ; 入力バッファにコピー
                mov     [esi], al
                cmp     al, 0
                je      .done
                inc     esi
                inc     edi
                jmp     short .copy
    .done:
                call    DispPrompt
                mov     eax, MAXLINE        ; 1 行入力
                mov     ebx, input
                call    READ_LINE2
                mov     esi, ebx
    .exit:
                mov     byte[ebp-2], 0      ; EOL=no, 入力済み
                ret

;-------------------------------------------------------------------------
; ListMore
;   eax に表示開始行番号
;-------------------------------------------------------------------------
ListMore:
                call    LineSearch          ; 表示開始行を検索
                call    GetChar             ; skip '+'
                call    Decimal             ; 表示行数を取得
                jnb     .list
    .default:   xor     ebx, ebx            ; 表示行数無指定は20行
                mov     bl, 20
    .list:      push    edi
    .count:     mov     eax, [edi]          ; 次行までのオフセット
                or      eax, eax
                js      .all                ; コード最終か?
                dec     ebx
                mov     edx, [edi + 4]      ; 行番号
                add     edi, [edi]
                or      ebx, ebx
                jne     .count
                pop     edi
                jmp     short List.loop

    .all        pop     edi                 ;
                jmp     short List.all      ; コード最終まで

;-------------------------------------------------------------------------
; List
;   eax に表示開始行番号, edi に表示行先頭アドレス
;-------------------------------------------------------------------------
List:
                test    eax, eax
                jne     .partial
                xor     ebx, ebx
                mov     bl, '='
                mov     edi, [ebp+ebx*4]    ; コード先頭アドレス
                jmp     short .all
    .partial:
                call    LineSearch          ; 表示開始行を検索
                call    GetChar             ; 仕様では -
                call    Decimal             ; 範囲最終を取得
                jb      .all
                mov     edx, ebx            ; 終了行番号
                jmp     short .loop
    .all:       xor     edx, edx
                dec     edx                 ; 最終まで表示(最大値)
    .loop:      mov     eax, [edi]          ; 次行までのオフセット
                or      eax, eax
                js      .exit               ; コード最終か?
                mov     eax, [edi + 4]      ; 行番号
                cmp     edx, eax
                jb      .exit
                call    PrintLeft           ; 行番号表示
                mov     al, ' '
                call    OutChar
                mov     ebx, 8
    .code:      mov     al, [edi + ebx]     ; コード部分表示
                cmp     al, 0
                je      .next
                call    OutChar
                inc     ebx
                jmp     short .code
    .next:      add     edi, [edi]
                call    NewLine
                jmp     short .loop         ; 次行処理

    .exit:      mov     byte[ebp-2], 1      ; 次に行入力 EOL=yes
                ret

;-------------------------------------------------------------------------
;  編集モード
;       0) 行番号 0 ならリスト
;       1) 行が行番号のみの場合は行削除
;       2) 行番号の直後が - なら行番号指定部分リスト
;       3) 行番号の直後が + なら行数指定部分リスト
;       4) 行番号の直後が ! なら指定行編集
;       5) 同じ行番号の行が存在すれば入れ替え
;       6) 同じ行番号がなければ挿入
;-------------------------------------------------------------------------
EditMode:
                call    Decimal             ; 行番号取得
                xchg    eax, ebx            ; eax:行番号, ebx:次の文字
                test    eax, eax
                je      List                ; 行番号 0 ならリスト
                cmp     bl, 0               ; 行番号のみか
                je      near LineDelete     ; 行削除
                cmp     bl, '-'
                je      List                ; 部分リスト
                cmp     bl, '+'
                je      near ListMore       ; 部分リスト 20行
%ifdef DEBUG
                cmp     bl, '#'
                je      near DebugList      ; デバッグ用行リスト(#)
                cmp     bl, '$'
                je      near VarList        ; デバッグ用変数リスト($)
                cmp     bl, '%'
                je      near DumpList       ; デバッグ用ダンプリスト(%)
                cmp     bl, '&'
                je      near LabelList      ; デバッグ用ラベルリスト(&)
%endif

    .edit:      cmp     bl, '!'
                je      near LineEdit       ; 指定行編集
                call    LineSearch          ; 入力済み行番号を探索
                jae     LineInsert          ; 一致する行がなければ挿入
                call    LineDelete          ; 行置換(行削除+挿入)
LineInsert:
                xor     ecx, ecx            ; 挿入する行のサイズを計算
    .next:      cmp     byte[esi+ecx], 0    ; esi:コード部先頭
                je      .done               ; EOL発見 (ecx には n-1)
                inc     ecx                 ; 次の文字
                jmp     short .next
    .done:
;                add     ecx, 9              ; ecx に挿入サイズ(+8+1)
                add     ecx, 12             ; ecx に挿入サイズ(+8+1+3)
                and     ecx, 0xfffffffc     ; 4バイト境界に整列
                push    eax                 ; 行番号退避
                mov     eax, edi            ; 挿入ポイント退避
                push    esi                 ; 挿入用ギャップ作成
                push    edi                 ; 挿入位置
                push    ecx                 ; 挿入量退避
                xor     ebx, ebx
                mov     bl, '&'             ; ヒープ先頭システム変数取得
                mov     edx, [ebp+ebx*4]
                mov     edi, edx
                add     edi, ecx            ; 新ヒープ先頭計算
                mov     [ebp+ebx*4], edi    ; 新ヒープ先頭設定
                mov     esi, edx            ; 元の &
                sub     edx, eax            ; 移動サイズ=元& - 挿入位置
                dec     esi                 ; 始めは old &-1 から
                dec     edi                 ; new &-1 へのコピー
                mov     ecx, edx
                std                         ; メモリ後部から移動
            rep movsb
                cld
                pop     ecx                 ; 挿入量復帰
                pop     edi                 ; 挿入ポイント復帰
                pop     esi                 ; 入力ポインタ
                pop     eax                 ; 行番号復帰

                mov     [edi], ecx          ; 次行へのオフセット設定
                mov     [edi+4], eax        ; 行番号設定
                mov     eax, 8
                add     edi, eax            ; 書き込み位置更新
                sub     ecx, eax            ; 書き込みサイズ更新
            rep movsb
                mov     byte[ebp-2], 1      ; 次に行入力 EOL=yes
                ret

;-------------------------------------------------------------------------
; 行の削除
;-------------------------------------------------------------------------
                align   4
LineDelete:
                push    esi
                push    edi
                call    LineSearch          ; 入力済み行番号を探索
                jae     .exit
                mov     esi, edi            ; 削除行先頭位置
                add     esi, [esi]          ; 次行先頭位置取得
                xor     ebx, ebx
                mov     bl, '&'             ; ヒープ先頭
                mov     ecx, [ebp+ebx*4]
                sub     ecx, edi            ; ecx:移動バイト数
                cld                         ; 増加方向
        rep     movsb                       ; ecxバイト移動
                mov     [ebp+ebx*4], edi
    .exit:      pop     edi
                pop     esi
                mov     byte[ebp-2], 1      ; 次に行入力  EOL=yes
                ret

;-------------------------------------------------------------------------
; 入力済み行番号を探索
; eax に検索行番号
; 一致行先頭または不一致の場合には次に大きい行番号先頭位置にedi設定
; 同じ行番号があればキャリーセット
; ebx, edi 破壊
;-------------------------------------------------------------------------
LineSearch:
                xor     ebx, ebx
                mov     bl, '='             ; プログラム先頭
                mov     edi, [ebp+ebx*4]

                align   4

    .nextline:  mov     ebx, [edi]          ; コード末なら検索終了
                inc     ebx
                je      .exit
                mov     ebx, [edi+4]        ; 行番号
                cmp     ebx, eax
                ja      .exit
                je      .found
                add     edi, [edi]          ; 次行先頭
                jmp     short .nextline
                jne     .found
    .exit:      clc
                ret
    .found:     stc
                ret

%ifdef DEBUG

;-------------------------------------------------------------------------
; デバッグ用プログラム行リスト <xxxx> 1#
;-------------------------------------------------------------------------
DebugList:
                pusha
                xor     ebx, ebx
                mov     bl, '='             ; プログラム先頭
                mov     eax, [ebp+ebx*4]
                mov     ecx, eax
                mov     edi, eax
                call    PrintHex8           ; プログラム先頭表示
                mov     al, ' '
                call    OutChar
                mov     bl, '&'             ; ヒープ先頭
                mov     eax, [ebp+ebx*4]
                mov     eax, ecx
                call    PrintHex8           ; ヒープ先頭表示
                mov     al, ' '
                call    OutChar
                sub     eax, ecx            ; プログラム領域サイズ
                call    PrintLeft
                call    NewLine
    .L1
                mov     eax, edi
                call    PrintHex8           ; 行頭アドレス
                mov     esi, [edi]          ; 次行までのオフセット
                mov     al, ' '
                call    OutChar
                mov     eax, esi
                call    PrintHex8           ; オフセットの16進表記
                mov     ecx, 4              ; 4桁右詰
                call    PrintRight          ; オフセットの10進表記
                inc     eax
                je      .L4                 ; コード最終か?
                mov     al, ' '
                call    OutChar

                mov     eax, [edi+4]        ; 行番号
                cmp     eax, 0
                je      .L4
                call    PrintLeft           ; 行番号表示
                mov     al, ' '
                call    OutChar
                mov     ebx, 8
    .L2
                mov     al, [edi+ebx]       ; コード部分表示
                cmp     al, 0
                je      .L3                 ; 改行
                call    OutChar
                inc     ebx                 ; 次の1文字
                jmp     short .L2
    .L3         call    NewLine
                add     edi, esi
                jmp     short .L1           ; 次行処理

    .L4         call    NewLine
                popa
                ret

;-------------------------------------------------------------------------
; デバッグ用変数リスト <xxxx> 1$
;-------------------------------------------------------------------------
VarList:
                xor     ebx, ebx
                mov     bl, 0x21
    .1          mov     al, bl
                call    OutChar
                mov     al, ' '
                call    OutChar
                mov     eax, [ebp+ebx*4]    ; 変数取得
                call    PrintHex8
                mov     ecx, 12             ; 表示桁数の設定
                call    PrintRight
                call    NewLine
                inc     bl
                cmp     bl, 0x7F
                jb      .1
                ret

;-------------------------------------------------------------------------
; デバッグ用ダンプリスト <xxxx> 1%
;-------------------------------------------------------------------------
DumpList:
                pusha
                xor     ebx, ebx
                mov     bl, '='             ; プログラム先頭
                mov     edx, [ebp+ebx*4]

                and     dl, 0xf0            ; 16byte境界から始める
                mov     edi, edx
                mov     bl, 8
    .1
                mov     eax, edi
                call    PrintHex8           ; 先頭アドレス表示
                mov     al, ' '
                call    OutChar
                mov     al, ':'
                call    OutChar
                mov     ecx,16
    .loop
                mov     al, ' '
                call    OutChar
                mov     al, [edi]           ; 1バイト表示
                call    PrintHex2
                inc     edi
                loop    .loop
                call    NewLine
                dec     bl
                jnz     .1                  ; 次行処理
                popa
                ret

;-------------------------------------------------------------------------
; デバッグ用ラベルリスト <xxxx> 1&
;-------------------------------------------------------------------------
LabelList:
                pusha
                mov     ebx, LabelTable      ; ラベルテーブル先頭
                mov     ecx, TablePointer
                mov     ecx, [ecx]           ; テーブル最終登録位置
    .1
                cmp     ebx, ecx
                jge     .2
                mov     eax, [ebx+12]
                call    PrintHex8
                mov     al, ' '
                call    OutChar
                mov     eax, ebx
                call    OutAsciiZ
                call    NewLine
                add     ebx, 16
                jmp     short .1
    .2
                popa
                ret
%endif

;-------------------------------------------------------------------------
; SkipEqualExp  = に続く式の評価
; SkipCharExp   1文字を読み飛ばした後 式の評価
; Exp           式の評価
; eax に値を返す (先読み無しで呼び出し, 1文字先読みで返る)
; ebx, ecx, edx, edi 保存
;-------------------------------------------------------------------------
SkipEqualExp:
                call    GetChar             ; check =
SkipEqualExp2:  cmp     al, '='             ; 先読みの時
                je      Exp
                mov     eax, equal_err      ;
                call    OutAsciiZ
                pop     ebx                 ; スタック修正
                pop     ebx                 ; スタック修正
                jmp     SyntaxError         ; 文法エラー

SkipCharExp:
                call    GetChar             ; skip a character
Exp:
                mov     al, [esi]           ; PeekChar
                cmp     al, ' '
                jne     .ok
                mov     byte[ebp-19], 1     ; 式中の空白はエラー
                jmp     LongJump            ; トップレベルに戻る

    .ok:        pusha
                call    Factor
    .next:
                cmp     al,  '+'            ; ADD
                jne     .sub
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                add     ebx, ecx            ; 2項を加算
                jmp     short .next
    .sub:       cmp     al,  '-'            ; SUB
                jne     .mul
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                sub     ebx, ecx            ; 左項から右項を減算
                jmp     short .next
    .mul:       cmp     al,  '*'            ; MUL
                jne     .div
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                push    eax
                mov     eax, ebx
                imul    ecx                 ; 符号付乗算
                mov     ebx, eax
                pop     eax
                jmp     short .next
    .div:       cmp     al,  '/'            ; DIV
                jne     .udiv
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                or      ecx, ecx
                jne     .div1
                mov     byte[ebp-18], 1     ; ０除算エラー
                jmp     .exit
    .div1:      push    eax
                mov     eax, ebx
                cdq                         ; eax-->edx:eax
                idiv    ecx                 ; 右項で左項を除算
                xor     ecx, ecx
                mov     cl, '%'             ; 剰余の保存
                mov     [ebp+ecx*4], edx
                mov     ebx, eax            ; 商を ebx に
                pop     eax
    .next2:     jmp     short .next
    .udiv:      cmp     al,  '\'            ; UDIV
                jne     .and
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                or      ecx, ecx
                jne     .udiv1
                mov     byte[ebp-18], 1     ; ０除算エラー
                jmp     .exit
    .udiv1:     push    eax
                mov     eax, ebx
                xor     edx, edx            ; eax-->edx:eax
                div     ecx                 ; 右項で左項を除算
                xor     ecx, ecx
                mov     cl, '%'             ; 剰余の保存
                mov     [ebp+ecx*4], edx
                mov     ebx, eax            ; 商を ebx に
                pop     eax
                jmp     short .next2
    .and:       cmp     al,  '&'            ; AND
                jne     .or
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                and     ebx, ecx            ; 左項と右項をAND
                jmp     short .next2
    .or:        cmp     al,  '|'            ; OR
                jne     .xor
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                or      ebx, ecx            ; 左項と右項を OR
                jmp     short .next2
    .xor:       cmp     al,  '^'            ; XOR
                jne     .equal
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                xor     ebx, ecx            ; 左項と右項を XOR
                jmp     short .next2
    .equal:     cmp     al,  '='            ; =
                jne     .exp7
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                jne     .false
    .true:      xor     ebx, ebx
                inc     ebx                 ; 1:真
                jmp     short .next2
    .false:     xor     ebx, ebx            ; 0:偽
    .next3:     jmp     .next
    .exp7:      cmp     al,  '<'            ; <
                jne     .exp8
                mov     al, [esi]           ; PeekChar
                cmp     al,  '='            ; <=
                je      .exp71
                cmp     al,  '>'            ; <>
                je      .exp72
                cmp     al,  '<'            ; <<
                je      .shl
                                            ; <
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                jge     .false
                jmp     short .true
    .exp71:     call    GetChar             ; <=
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                jg      .false
                jmp     short .true
    .exp72:     call    GetChar             ; <>
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                je      .false
    .true2:     jmp     short .true
    .false2     jmp     short .false
    .shl:       call    GetChar             ; <<
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                cmp     ebx, 32             ; 32以上は結果を0に固定
                jae     .zero
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                shl     ebx, cl             ; 左項を右項で SHL (*2)
    .next4:     jmp     short .next3
    .zero:      pop     ebx
                xor     ebx, ebx
                jmp     short .next3

    .exp8:      cmp     al,  '>'            ; >
                jne     .exp9
                mov     al, [esi]           ; PeekChar
                cmp     al,  '='            ; >=
                je      .exp81
                cmp     al,  '>'            ; >>
                je      .shr
                                            ; >
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                jle     .false2
                jmp     short .true2
    .exp81:     call    GetChar             ; >=
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                mov     ecx, ebx            ; 右項を ecx に設定
                pop     ebx                 ; 左の項を復帰
                cmp     ebx, ecx            ; 左項と右項を比較
                jl      .false2
                jmp     short .true2
    .shr:       call    GetChar             ; >>
                push    ebx                 ; 項の値を退避
                call    Factor              ; 右項を取得
                cmp     ebx, 32             ; 32以上は結果を0に固定
                jae     .zero
                mov     ecx, ebx            ; 右項を ecx に設定
    .shr2:      pop     ebx                 ; 左の項を復帰
                shr     ebx, cl             ; 左項を右項で SHR (/2)
                jmp     short .next4
    .exp9:
    .exit:
                mov     [esp+28], ebx       ; eax に返す
                mov     [esp+ 4], esi       ; esi に返す
                popa
                ret

;-------------------------------------------------------------------------
; UNIX時間をマイクロ秒単位で返す
;-------------------------------------------------------------------------
GetTime:
                push    edi
                mov     edi, TV
                mov     eax, SYS_gettimeofday
                mov     ebx, edi
                lea     ecx, [edi + 8]      ; TZ
                int     0x80
                mov     ebx, [edi]          ; sec
                mov     eax, [edi + 4]      ; usec
                xor     ecx, ecx
                mov     cl, '%'             ; 剰余に usec を保存
                mov     [ebp+ecx*4], eax
                pop     edi
                call    GetChar
                ret

;-------------------------------------------------------------------------
; マイクロ秒単位のスリープ _=n
;-------------------------------------------------------------------------
Com_USleep:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                push    edi
                push    esi
                xor     ebx, ebx
                mov     edi, TV
                mov     [edi], ebx          ; sec は 0
                mov     [edi+4], eax        ; usec
                mov     eax, SYS_select
                mov     ecx, ebx
                mov     edx, ebx
                mov     esi, ebx
                int     0x80
                call    CheckError
                pop     esi
                pop     edi
                ret

;-------------------------------------------------------------------------
; 10進整数
; ebx に数値が返る, eax,ebx,ecx 使用
; 1 文字先読みで呼ばれ 1 文字先読みして返る
;-------------------------------------------------------------------------
Decimal:
                xor     ecx, ecx            ; 正の整数を仮定
                xor     ebx, ebx
                cmp     al, "+"
                je      .EatSign
                cmp     al, "-"
                jne     .Num
                inc     ecx                 ; 負の整数
    .EatSign:
                call    GetDigit
                jb      .exit               ; 数字でなければ返る
                jmp     short .NumLoop
    .Num:
                call    IsNum
                jb      .exit
                sub     eax, '0'
    .NumLoop:
                imul    ebx, 10             ;
                add     ebx, eax
                call    GetDigit
                jae     .NumLoop

                or      ecx, ecx            ; 数は負か？
                je      .exit
                neg     ebx                 ; 負にする
    .exit:
                ret

;-------------------------------------------------------------------------
; 配列と変数の参照, ebx に値が返る
;-------------------------------------------------------------------------
Variable:
                call    SkipAlpha           ; 変数名は ebx
                lea     edi, [ebp+ebx*4]    ; 変数アドレス
                cmp     al, '('
                je      .array1
                cmp     al, '{'
                je      .array2
                cmp     al, '['
                je      .array4
                mov     ebx, [edi]          ; 単純変数
                ret

    .array1:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     bl, [edi + eax]
                call    GetChar             ; skip )
                ret

    .array2:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     bx, [edi + eax * 2]
                call    GetChar             ; skip }
                ret

    .array4:    call    .array
                jb      .range_err          ; 範囲外をアクセス
                mov     ebx, [edi + eax * 4]
                call    GetChar             ; skip ]
                ret

    .array:     call    Exp                 ; 1バイト配列
                mov     edi, [edi]
                call    RangeCheck          ; 範囲チェック
                ret

    .range_err:
                call    RangeError
                ret

;-------------------------------------------------------------------------
; 変数値
; ebx に値を返す (先読み無しで呼び出し, 1文字先読みで返る)
;-------------------------------------------------------------------------
Factor:
                call    GetChar
                call    IsNum
                jb      .bracket
                call    Decimal             ; 正の10進整数
                ret

    .bracket:   cmp     al, '('
                jne     .yen
                call    Exp                 ; カッコ処理
                mov     ebx, eax            ; 項の値は ebx
                call    GetChar             ; skip )
                ret

    .yen:       cmp     al, '\'
                jne     .rand
                mov     al, [esi]           ; Peek Char
                cmp     al, '\'
                je      .env
                call    Exp                 ; 引数番号を示す式
                mov     edx, argc_vtl
                mov     ecx, [edx]          ; vtl用の引数の個数
                cmp     eax, ecx            ; 引数番号と引数の数を比較
                jl      .L2                 ; 引数番号 < 引数の数
                mov     ebx, [edx - 8]      ; argvp
                mov     ebx, [ebx]
    .L1:        mov     cl, [ebx]           ; 0を探す
                inc     ebx
                or      cl, cl
                jne     .L1
                dec     ebx                 ; argv[0]のEOLに設定
                jmp     short .L3
    .L2:        mov     ebx, [edx + 4]      ; found [argp_vtl]
                mov     ebx, [ebx + eax*4]  ; 引数文字列先頭アドレス
    .L3:        ret

    .env:
                call    GetChar             ; skip '\'
                call    Exp                 ; 引数番号を示す式
                mov     edx, [envp]
                xor     ecx, ecx
    .L4:        cmp     dword[edx+ecx*4], 0 ; 環境変数の数をカウント
                je      .L5
                inc     ecx
                jmp     short .L4
    .L5:
                cmp     eax, ecx
                jge     short .L6           ; 引数番号が過大
                mov     ebx, [edx + eax*4]  ; 引数文字列先頭アドレス
                ret
    .L6:        lea     ebx, [edx + ecx*4]  ; null pointer を返す
                ret

    .rand:      cmp     al, '`'
                jne     .hex
                call    genrand             ; 乱数の読み出し
                mov     ebx, eax
                call    GetChar
                ret

    .hex:       cmp     al, '$'
                jne     .time
                call    Hex                 ; 16進数または1文字入力
                ret

    .time:      cmp     al, '_'
                jne     .num
                call    GetTime             ; 時間を返す
                ret

    .num:       cmp     al, '?'
                jne     .char
                call    NumInput            ; 数値入力
                ret

    .char:      cmp     al, 0x27
                jne     .singnzex
                call    CharConst           ; 文字定数
                ret

    .singnzex:  cmp     al, '<'
                jne     .neg
                call    Factor
                mov     ebx, ebx            ; ゼロ拡張(64bit版互換機能)
                ret

    .neg:       cmp     al, '-'
                jne     .abs
                call    Factor              ; 負符号
                neg     ebx
                ret

    .abs:       cmp     al, '+'
                jne     .realkey
                call    Factor              ; 変数，配列の絶対値
                or      ebx, ebx
;                jns     .exit
                jns     near .exit
                neg     ebx
                ret

    .realkey:   cmp     al, '@'
                jne     .winsize
                call    RealKey             ; リアルタイムキー入力
                mov     ebx, eax
                call    GetChar
                ret

    .winsize:   cmp     al, '.'
                jne     .pop
                call    WinSize             ; ウィンドウサイズ取得
                mov     ebx, eax
                call    GetChar
                ret

    .pop:       cmp     al, ';'
                jne     .label
                mov     ecx, [ebp-16]       ; VSTACK
                dec     ecx
                jge     .pop2
                xor     ecx, ecx
                mov     cl, 2               ;
                mov     [ebp-19], ecx       ; 変数スタックエラー
                jmp     short .pop3
    .pop2:
                mov     ebx, [ebp+ecx*4+1024]    ; 変数スタックから復帰
                mov     [ebp-16], ecx       ; スタックポインタ更新
    .pop3:      call    GetChar
                ret

    .label:
%ifdef VTL_LABEL
                cmp     al, '^'
                jne     .var
                call    LabelSearch         ; ラベルのアドレスを取得
                jae     .label2
                xor     ecx, ecx
                mov     cl, 3               ; ラベル未定義
                mov     [ebp-19], ecx       ; ラベル未定義エラー
                call    GetChar
    .label2:
                ret
%endif

    .var:
                call    Variable            ; 変数，配列参照
    .exit       ret

;-------------------------------------------------------------------------
; コンソールから数値入力
;-------------------------------------------------------------------------
NumInput:
                mov     al, [ebp-2]         ; EOL状態退避
                push    eax
                push    esi
                mov     eax, MAXLINE        ; 1 行入力
                mov     ebx, input2         ; 行ワークエリア
                call    READ_LINE3
                mov     esi, ebx
                lodsb                       ; 1文字先読み
                call    Decimal
                pop     esi
                pop     eax
                mov     [ebp-2], al         ; EOL状態復帰
                call    GetChar
                ret

;-------------------------------------------------------------------------
; コンソールから input2 に文字列入力
;-------------------------------------------------------------------------
StringInput:
                mov     al, [ebp-2]         ; EOL状態退避
                push    eax
                mov     eax, MAXLINE        ; 1 行入力
                mov     ebx, input2         ; 行ワークエリア
                call    READ_LINE3
                xor     edx, edx
                mov     dl, '%'             ; %に文字数を保存
                mov     [ebp+edx*4], eax
                pop     eax
                mov     [ebp-2], al         ; EOL状態復帰
                call    GetChar
                ret

;-------------------------------------------------------------------------
; 文字定数を数値に変換
; ebx に数値が返る, eax,ebx,ecx使用
;-------------------------------------------------------------------------
CharConst:
                xor     ebx, ebx
                mov     ecx, 4              ; 文字定数は4バイトまで
    .next:      call    GetChar
                cmp     al, 0x27            ; '''
                je      .exit
                shl     ebx, 8
                add     ebx, eax
                loop    .next
    .exit:      call    GetChar
                ret

;-------------------------------------------------------------------------
; 16進整数の文字列を数値に変換
; ebx に数値が返る, eax,ebx 使用
;-------------------------------------------------------------------------
Hex:
                xor     ebx, ebx
                xor     ecx, ecx
                mov     al, [esi]           ; string input
                cmp     al, '$'             ; string input
                je      StringInput         ; string input
    .next:      call    GetChar             ; $ の次の文字
                call    IsNum
                jb      .hex1
                sub     al, '0'             ; 整数に変換
                jmp     short .num
    .hex1:      cmp     al, ' '             ; 数字以外
                je      .exit
                cmp     al, 'A'
                jb      .exit               ; 'A' より小なら
                cmp     al, 'F'
                ja      .hex2
                sub     al, 55              ; -'A'+10 = -55
                jmp     short .num
    .hex2:      cmp     al, 'a'
                jb      .exit
                cmp     al, 'f'
                ja      .exit
                sub     al, 87              ; -'a'+10 = -87
    .num:
                shl     ebx, 4
                add     ebx, eax
                inc     ecx
                jmp     short .next
    .exit:      test    ecx, ecx
                je      CharInput
                ret

;-------------------------------------------------------------------------
; ソースコードを1文字読み込む
; ESI の示す文字を EAX に読み込み, ESI を次の位置に更新
;-------------------------------------------------------------------------
GetChar:
                xor     eax, eax
                cmp     byte[ebp-2], 1      ; EOL=yes
                je      .exit
                mov     al, [esi]
                or      al, al
                jne     .getc
                mov     byte[ebp-2], 1      ; EOL=yes
    .getc:      inc     esi
    .exit:      ret

;-------------------------------------------------------------------------
; コンソールから 1 文字入力, EBXに返す
;-------------------------------------------------------------------------
CharInput:
                push    eax                 ; 次の文字を保存
                call    InChar
                mov     ebx, eax
                pop     eax
                ret

;---------------------------------------------------------------------
; AL の文字が数字かどうかのチェック
; 数字なら整数に変換して AL 返す. 非数字ならキャリーセット
; ! 16進数と文字定数の処理を加えること
;---------------------------------------------------------------------

IsNum:          cmp     al, "0"             ; 0 - 9
                jb      IsAlpha2.no
                cmp     al, "9"
                ja      IsAlpha2.no
                clc
                ret
GetDigit:
                call    GetChar             ; 0 - 9
                call    IsNum
                jb      IsAlpha2.no
                sub     al, '0'             ; 整数に変換
                clc
                ret

IsAlpha:        call    IsAlpha1            ; 英文字か?
                jae     .yes
                call    IsAlpha2
                jb      IsAlpha2.no
    .yes:       clc
                ret

IsAlpha1:       cmp     al, "A"             ; 英大文字(A-Z)か?
                jb      IsAlpha2.no
                cmp     al, "Z"
                ja      IsAlpha2.no
                clc
                ret

IsAlpha2:       cmp     al, "a"             ; 英小文字(a-z)か?
                jb      .no
                cmp     al, "z"
                ja      .no
                clc
                ret
    .no:        stc
                ret

IsAlphaNum:     call    IsAlpha             ; 英文字か?
                jae     .yes
                call    IsNum
                jb      IsAlpha2.no
    .yes:       clc
                ret


;-------------------------------------------------------------------------
; コマンドラインで指定されたVTLコードファイルをロード
;   オープンの有無は jg で判断、オープンなら真
;-------------------------------------------------------------------------
LoadCode:
                push    ecx
                push    edi
                push    esi
                mov     edi, current_arg    ; 処理済みの引数
                mov     ecx, [edi]
                inc     ecx                 ; カウントアップ
                cmp     [edi+4], ecx        ; argc 引数の個数
                je      .exit
                mov     [edi], ecx
                mov     esi, [edi+8]        ; argvp 引数配列先頭
                mov     esi, [esi+ecx*4]    ; 引数取得
                mov     edi, FileName
                mov     ecx, FNAMEMAX
    .next:      mov     al, [esi]
                mov     [edi], al
                or      al, al
                je      .open
                inc     esi
                inc     edi
                loop    .next
    .open:      mov     ebx, FileName       ; ファイルオープン
                call    fropen              ; open
                jle     .exit
                mov     [ebp-8], eax        ; FileDesc
                mov     byte[ebp-4], 1      ; Read from file
                mov     byte[ebp-2], 1      ; EOL=yes
    .exit:      pop     esi
                pop     edi
                pop     ecx
                ret

;-------------------------------------------------------------------------
; ファイル読み込み
;-------------------------------------------------------------------------
READ_FILE:
                mov     ecx, input
                mov     ebx, [ebp-8]        ; FileDesc
    .next:
                mov     eax, SYS_read       ; システムコール番号
                mov     edx, 1              ; 読みこみバイト数
                int     0x80                ; ファイルから読みこみ
                test    eax, eax
                je      .end                ; EOF
                cmp     byte[ecx], 10       ; LineFeed
                je      .exit
                inc     ecx
                jmp     short .next
    .end:
                mov     ebx, [ebp-8]        ; FileDesc
                call    fclose              ; File Close
                mov     byte[ebp-4], 0      ; Read from console
                call    LoadCode
                jmp     short .skip
    .exit:      mov     byte[ebp-2], 0      ; EOL=no
    .skip:      mov     [ecx], bh
                mov     esi, input
                ret

;-------------------------------------------------------------------------
; 符号無し10進数文字列メモリ書き込み
;   esi の示すメモリに書き込み
;-------------------------------------------------------------------------
PutDecimal:
                push    eax
                push    ebx
                push    ecx
                push    edx
                xor     ecx, ecx
                mov     ebx, 10
    .PL1:       xor     edx, edx            ; 上位桁を 0 に
                div     ebx                 ; 10 で除算
                push    edx                 ; 剰余(下位桁)をPUSH
                inc     ecx                 ; 桁数更新
                test    eax, eax            ; 終了か?
                jnz     .PL1
    .PL2:       pop     eax                 ; 上位桁から POP
                add     al,'0'              ; 文字コードに変更
                mov     [esi], al           ; バッファに書込み
                inc     esi
                loop    .PL2
                pop     edx
                pop     ecx
                pop     ebx
                pop     eax
                ret

;-------------------------------------------------------------------------
; 数値出力 ?
;-------------------------------------------------------------------------
Com_OutNum:     call    GetChar             ; get next
                cmp     al, '='             ; PrintLeft
                jne     .ptn1
                call    Exp
                call    PrintLeft
                ret

    .ptn1:      cmp     al, '*'             ; 符号無し10進
                je      .unsigned
                cmp     al, '$'             ; ?$ 16進2桁
                je      .hex2
                cmp     al, '#'             ; ?# 16進4桁
                je      .hex4
                cmp     al, '?'             ; ?? 16進8桁
                je      .hex8
                jmp     short .ptn2

    .unsigned:  call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                call    PrintLeftU
                ret
    .hex2:      call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                call    PrintHex2
                ret
    .hex4:      call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                call    PrintHex4
                ret
    .hex8:      call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                call    PrintHex8
                ret

    .ptn2:      mov     dl, al
                push    edx
                call    Exp
                mov     ecx, eax            ; 表示桁数設定
                and     ecx, 0xff           ; 桁数の最大を255に制限
                call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                pop     edx
                cmp     dl, '{'             ; ?{ 8進数
                je      .oct
                cmp     dl, '!'             ; ?! 2進nビット
                je      .bin
                cmp     dl, '('             ; ?( print right
                je      .dec_right
                cmp     dl, '['             ; ?[ print right
                je      .dec_right0
    .error:     jmp     Com_Error           ; エラー

    .oct:       call    PrintOctal
                ret
    .bin:       call    PrintBinary
                ret
    .dec_right: call    PrintRight
                ret
    .dec_right0:call    PrintRight0
                ret

;-------------------------------------------------------------------------
; 文字出力 $
;-------------------------------------------------------------------------
Com_OutChar:    call    GetChar             ; get next
                cmp     al, '='
                je      .char1
                cmp     al, '$'             ; $$ 2byte
                je      .char2
                cmp     al, '#'             ; $# 4byte
                je      .char3
                cmp     al, '*'             ; $*=StrPtr
                je      .char4
                ret
    .char1:     call    Exp                 ; １バイト文字
                call    OutChar
                ret
    .char2:     call    SkipEqualExp        ; ２バイト文字
                mov     ebx, eax
                mov     al, bh
                call    OutChar
                mov     al, bl
                call    OutChar
                ret
    .char3:     call    SkipEqualExp        ; ４バイト文字
                mov     ebx, eax
                push    ebx
                shr     ebx, 16
                mov     al, bh
                call    OutChar
                mov     al, bl
                call    OutChar
                pop     ebx
                mov     al, bh
                call    OutChar
                mov     al, bl
                call    OutChar
                ret
    .char4:     call    SkipEqualExp
                call    OutAsciiZ
                ret

;-------------------------------------------------------------------------
; 空白出力 .=n
;-------------------------------------------------------------------------
Com_Space:      call    SkipEqualExp     ; 1文字を読み飛ばした後 式の評価
                mov     ecx, eax
    .loop:      mov     al, ' '
                call    OutChar
                loop    .loop
                ret

;-------------------------------------------------------------------------
; 改行出力 /
;-------------------------------------------------------------------------
Com_NewLine:    mov     al, 10              ; LF
                call    OutChar
                ret

;-------------------------------------------------------------------------
; 文字列出力 "
;-------------------------------------------------------------------------
Com_String:     mov     ecx, esi
                xor     edx, edx
    .next       call    GetChar
                cmp     al, '"'
                je      .exit
                cmp     byte [ebp-2], 1     ; EOL=yes ?
                je      .exit
                inc     edx
                jmp     short .next
    .exit:
                mov     eax, ecx
                call    OutString
                ret

;-------------------------------------------------------------------------
; GOTO #
;-------------------------------------------------------------------------
Com_GO:
                call    GetChar
                cmp     al, '!'
                je      .nextline           ; #! はコメント
%ifdef VTL_LABEL
                call    ClearLabel
%endif
                call    SkipEqualExp2       ; = をチェックした後 式の評価
    .go:
                cmp     byte[ebp-3], 0      ; ExecMode=Direct
                je      .label
%ifdef VTL_LABEL
                xor     ebx, ebx
                mov     bl, '^'             ; システム変数「^」の
                mov     ecx, [ebp+ebx*4]    ; チェック
                or      ecx, ecx            ; 式中でラベル参照があるか?
                je      .linenum            ; 無い場合は行番号
                mov     edi, ecx            ; edi を指定行の先頭アドレスへ
                xor     ecx, ecx            ; システム変数「^」クリア
                mov     [ebp+ebx*4], ecx    ; ラベル無効化
                jmp     short .check
%endif

    .linenum:   or      eax, eax            ; #=0 なら次行
                jne     .linenum2
    .nextline:  mov     byte[ebp-2], 1      ; EOL=yes
                ret

    .linenum2:  cmp     eax, [edi+4]        ; 現在の行と行番号比較
                jb      .top
                call    LineSearch.nextline ; 現在行から検索
                jmp     short .check
    .label:
%ifdef VTL_LABEL
                call    LabelScan           ; ラベルテーブル作成
%endif

    .top:       call    LineSearch          ; edi を指定行の先頭へ
    .check:     mov     eax, [edi]          ; コード末チェック
                inc     eax
                je      .stop
                mov     byte[ebp-3], 1      ; ExecMode=Memory
                call    SetLineNo2          ; 行番号を # に設定
                lea     esi, [edi + 8]
                mov     byte [ebp-2], 0     ; EOL=no
                ret
    .stop:
                call    CheckCGI            ; CGIモードなら終了
                call    WarmInit1           ; 入力デバイス変更なし
                ret

%ifdef VTL_LABEL
;-------------------------------------------------------------------------
; 式中でのラベル参照結果をクリア
;-------------------------------------------------------------------------
ClearLabel:
                xor     ecx, ecx            ; システム変数「^」クリア
                xor     ebx, ebx
                mov     bl, '^'             ;
                mov     [ebp+ebx*4], ecx    ; ラベル無効化
                ret

;-------------------------------------------------------------------------
; コードをスキャンしてラベルとラベルの次の行アドレスをテーブルに登録
;-------------------------------------------------------------------------
LabelScan:
                pusha
                xor     ebx, ebx
                mov     bl, '='
                mov     edi, [ebp+ebx*4]    ; コード先頭アドレス
                mov     eax, [edi]          ; コード末なら終了
                inc     eax
                jne     .maketable
                popa
                ret

    .maketable: mov     esi, LabelTable     ; ラベルテーブル先頭
                mov     [TablePointer], esi ; 登録する位置
                xor     ecx, ecx

    .nextline:  mov     cl, 8               ; テキスト先頭
    .space:     mov     al, [edi+ecx]       ; 1文字取得
                cmp     al, 0
                je      .eol                ; 行末
                cmp     al, ' '             ; 空白読み飛ばし
                jne     .nextch
                inc     ecx
                jmp     short .space

    .nextch:    cmp     al, '^'             ; ラベル?
                jne     .eol

    .label:     inc     ecx                 ; ラベルテーブルに登録
                mov     esi, [TablePointer] ; 登録位置をesi
                mov     eax, edi
                add     eax, [edi]          ; 次行先頭
                mov     [esi + 12], eax     ; アドレス登録
                xor     edx, edx
    .label2:    mov     al, [edi+ecx]       ; 1文字取得
                cmp     al, 0
                je      .registerd          ; 行末
                cmp     al, ' '             ; ラベルの区切りは空白
                je      .registerd          ; ラベル文字列
                cmp     edx, 11             ; 最大11文字まで
                je      .registerd          ; 文字数
                mov     [esi+edx], al
                inc     ecx
                inc     edx
                jmp     short .label2

    .registerd: mov     byte[esi+edx], 0    ; ラベル文字列末
                add     esi, 16
                mov     [TablePointer], esi ; 次に登録する位置
    .eol:       add     edi, [edi]          ; 次行先頭
                mov     eax, [edi]          ; 次行オフセット
                inc     eax                 ; コード末チェック
                je      .finish             ; スキャン終了
                cmp     esi, TablePointer   ; テーブル最終位置
                je      .finish             ; スキャン終了
                jmp     short .nextline

    .finish:    popa
                ret

;-------------------------------------------------------------------------
; テーブルからラベルの次の行アドレスを取得
; ラベルの次の行の先頭アドレスをebxと「^」に設定して返る
; Factorからesiを^の次に設定して呼ばれる
; esi はラベルの後ろ(長すぎる場合は読み飛ばして)に設定される
;-------------------------------------------------------------------------
LabelSearch:
                pusha
                mov     edi, LabelTable     ; ラベルテーブル先頭
                mov     ecx, [TablePointer] ; テーブル最終位置

    .cmp_line:  xor     edx ,edx            ; ラベルの先頭から
    .cmp_ch:    mov     al, [esi+edx]       ; ラベルの文字
                mov     bl, [edi+edx]       ; テーブルと比較
                or      bl, bl              ; テーブル文字列の最後?
                jne     .cmp_ch2            ; 比較を継続
                call    IsAlphaNum
                jb      .found              ; 発見
    .cmp_ch2:   cmp     al, bl              ; 比較
                jne     .next               ; 一致しない場合は次

                inc     edx                 ; 一致したら次の文字
                cmp     dl, 11              ; 長さ
                jne     .cmp_ch             ; 次の文字を比較
                call    Skip_excess         ; 長過ぎるラベルは空白か
                                            ; 行末まで読み飛ばし
    .found:     mov     eax, [edi+12]       ; テーブルからアドレス取得
                mov     [esp+16], eax       ; ebx に次行先頭を返す
                xor     ebx, ebx
                mov     bl, '^'             ; システム変数「^」に
                mov     [ebp+ebx*4], eax    ; ラベルの次行先頭を設定
                add     esi, edx
                call    GetChar
                mov     [esp+28], eax       ; eax に1文字を返す
                mov     [esp+4], esi        ; esi を更新
                clc
                popa
                ret

    .next:      add     edi, 16
                cmp     edi, ecx            ; すべての登録をチェック
                je      .notfound
                cmp     edi, TablePointer   ; ラベル領域最終？
                je      .notfound
                jmp     short .cmp_line     ; 次のテーブルエントリ

    .notfound:
                xor     edx, edx
                call    Skip_excess         ; ラベルを空白か行末まで読飛ばし
                xor     eax, eax
                mov     [esp+16], eax       ; ebx に 0 を返す
                stc                         ; なければキャリー
                popa
                ret

Skip_excess:
    .skip:      mov     al, [esi+edx]       ; 長過ぎるラベルは
                call    IsAlphaNum
                jb      .exit
                inc     edx                 ; 読み飛ばし
                jmp     short .skip
    .exit:      ret

%endif

;-------------------------------------------------------------------------
; GOSUB !
;-------------------------------------------------------------------------
Com_GOSUB:
                cmp     byte[ebp-3], 0      ; ExecMode=Direct
                jne     .ok
                mov     eax, no_direct_mode
                call    OutAsciiZ
                pop     ebx                 ; スタック修正
                call    WarmInit
                jmp     MainLoop
    .ok:
%ifdef VTL_LABEL
                call    ClearLabel
%endif
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                call    PushLine
                call    Com_GO.go
                ret

;-------------------------------------------------------------------------
; スタックへアドレスをプッシュ (行と文末位置を退避)
; ebx 変更
;-------------------------------------------------------------------------
PushLine:
                xor     ebx, ebx
                mov     bl, [ebp-1]             ; LSTACK
                cmp     bl, LSTACKMAX
                jge     StackError.over         ; overflow
                mov     [ebp+ebx*4+512], edi    ; push edi
                inc     ebx
                cmp     byte [esi-1], 0
                je      .endofline              ; 行末処理
                mov     [ebp+ebx*4+512], esi    ; push esi
                jmp     short .exit
    .endofline:
                dec     esi                     ; 1文字戻す
                mov     [ebp+ebx*4+512], esi    ; push esi
                inc     esi                     ;
    .exit       inc     ebx
                mov     [ebp-1], bl             ; LSTACK
                ret

;-------------------------------------------------------------------------
; スタックからアドレスをポップ (行と文末位置を復帰)
; ebx, esi, edi  変更
;-------------------------------------------------------------------------
PopLine:
                xor     ebx, ebx
                mov     bl, [ebp-1]             ; LSTACK
                cmp     bl, 2
                jl      StackError.under        ; underflow
                dec     ebx
                mov     esi, [ebp+ebx*4+512]    ; pop esi
                dec     ebx
                mov     edi, [ebp+ebx*4+512]    ; pop edi
                mov     [ebp-1], bl             ; LSTACK
                ret

;-------------------------------------------------------------------------
; スタックエラー
; eax 変更
;-------------------------------------------------------------------------
StackError:
    .over:      mov     eax, stkover
                jmp     short .print
    .under:     mov     eax, stkunder
    .print:     call    OutAsciiZ
                call    WarmInit
                ret

;-------------------------------------------------------------------------
; スタックへ終了条件(EAX)をプッシュ
; ebx 変更
;-------------------------------------------------------------------------
PushValue:
                xor     ebx, ebx
                mov     bl, [ebp-1]         ; LSTACK
                cmp     bl, LSTACKMAX
                jge     StackError.over
                mov     [ebp+ebx*4+512], eax
                inc     ebx
                mov     [ebp-1], bl         ; LSTACK
                ret

;-------------------------------------------------------------------------
; スタック上の終了条件を eax に設定
; eax, ebx 変更
;-------------------------------------------------------------------------
PeekValue:
                xor     ebx, ebx
                mov     bl, [ebp-1]         ; LSTACK
                sub     bl, 3               ; 行,文末位置の前
                mov     eax, [ebp+ebx*4+512]
                ret

;-------------------------------------------------------------------------
; スタックから終了条件(EAX)をポップ
; eax, ebx 変更
;-------------------------------------------------------------------------
PopValue:
                xor     ebx, ebx
                mov     bl, [ebp-1]         ; LSTACK
                cmp     bl, 1
                jl      StackError.under
                dec     ebx
                mov     eax, [ebp+ebx*4+512]
                mov     [ebp-1], bl         ; LSTACK
                ret

;-------------------------------------------------------------------------
; Return ]
;-------------------------------------------------------------------------
Com_Return:
                call    PopLine             ; 現在行の後ろは無視
                mov     byte[ebp-2], 0      ; not EOL
                ret

;-------------------------------------------------------------------------
; IF ; コメント :
;-------------------------------------------------------------------------
Com_IF:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                or      eax, eax
                jne     Com_Comment.true
Com_Comment:    mov     byte[ebp-2], 1      ; 次の行へ
    .true:
                ret

;-------------------------------------------------------------------------
; 未定義コマンド処理(エラーストップ)
;-------------------------------------------------------------------------
Com_Error:
                pop     ebx                 ; スタック修正
                jmp     SyntaxError

;-------------------------------------------------------------------------
; DO UNTIL NEXT @
;-------------------------------------------------------------------------
Com_DO:
                cmp     byte[ebp-3], 0      ; ExecMode=Direct
                jne     .ok
                mov     eax, no_direct_mode
                call    OutAsciiZ
                pop     ebx                 ; スタック修正
                call    WarmInit
                jmp     MainLoop
    .ok:
                call    GetChar
                cmp     al, '='
                jne     .do
                mov     al, [esi]           ; PeekChar
                cmp     al, '('             ; UNTIL?
                jne     .next               ; ( でなければ NEXT
                call    SkipCharExp         ; (を読み飛ばして式の評価
                mov     ecx, eax            ; 式の値
                call    GetChar             ; ) を読む(使わない)
                call    PeekValue           ; 終了条件
                cmp     ecx, eax            ; eax:終了条件
                jl      .continue
                jmp     short .exit
    .next:                                  ; FOR
                call    IsAlpha             ; al=[A-Za-z] ?
                jb      Com_Error
                push    edi
                lea     edi, [ebp+eax*4]    ; 制御変数のアドレス
                call    Exp                 ; 任意の式
                mov     edx, [edi]          ; 更新前の値を ebx に
                mov     [edi], eax          ; 制御変数の更新
                pop     edi
                mov     ecx, eax            ; 式の値
                call    PeekValue           ; 終了条件を eax に
                cmp     byte[ebp-20], 1     ; 降順 (開始値 > 終了値)
                jne     .asc

    .desc:      ; for 降順
                cmp     edx, ecx            ; 更新前 - 更新後
                jle     Com_Error           ; 更新前が小さければエラー
                cmp     edx, eax            ; eax:終了条件
                jg      .continue
                jmp     short .exit         ; 終了

    .asc:       ; for 昇順
                cmp     edx, ecx            ; 更新前 - 更新後
                jge     Com_Error           ; 更新前が大きければエラー
                cmp     edx, eax            ; eax:終了条件
                jl      .continue

    .exit:      ; ループ終了
                xor     ebx, ebx
                mov     bl, [ebp-1]         ; LSTACK=LSTACK-3
                sub     bl, 3
                mov     [ebp-1], bl         ; LSTACK
                ret

    .continue:  ; UNTIL
                xor     ebx, ebx            ; 戻りアドレス
                mov     bl, [ebp-1]         ; LSTACK
                mov     esi, [ebp+ebx*4+508]    ; ebp+(ebx-1)*4+512
                mov     edi, [ebp+ebx*4+504]    ; ebp+(ebx-2)*4+512
                mov     byte[ebp-2], 0      ; not EOL
                ret

    .do:        mov     eax, 1              ; DO
                call    PushValue
                call    PushLine
                ret

;-------------------------------------------------------------------------
; = コード先頭アドレスを再設定
;-------------------------------------------------------------------------
Com_Top:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                push    edi
                mov     edi, eax
                call    RangeCheck          ; ',' <= '=' < '*'
                jb      Com_NEW.range_err   ; 範囲外エラー
                xor     ebx, ebx
                mov     bl, '='             ; コード先頭
                mov     [ebp+ebx*4], eax    ; 式の値を=に設定
                mov     bl, '*'             ; メモリ末
                mov     edi, [ebp+ebx*4]    ; edi=*
    .nextline:                              ; コード末検索
                mov     ebx, [eax]          ; 次行へのオフセット
                inc     ebx                 ; 行先頭が -1 ?
                je      .found              ; yes
                dec     ebx                 ; 次行へのオフセットを戻す
                or      ebx, ebx
                jle     .endmark_err        ; 次行へのオフセット <= 0
                mov     ebx, [eax+4]        ; 行番号 > 0
                or      ebx, ebx
                jle     .endmark_err        ; 行番号 <= 0
                add     eax, [eax]          ; 次行先頭アドレス
                cmp     edi, eax            ; 次行先頭 > メモリ末
                jle     .endmark_err
                jmp     short .nextline     ; 次行処理
    .found:     mov     ecx, eax            ; コード末発見
                pop     edi
                jmp     short Com_NEW.set_end   ; & 再設定
    .endmark_err:
                pop     edi
                mov     eax, EndMark_msg    ; プログラム未入力
                call    OutAsciiZ
                call    WarmInit            ;
                ret

;-------------------------------------------------------------------------
; コード末マークと空きメモリ先頭を設定 &
;   = (コード領域の先頭)からの相対値で指定, 絶対アドレスが設定される
;-------------------------------------------------------------------------
Com_NEW:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                xor     ebx, ebx
                mov     bl, '='             ; コード先頭
                mov     ecx, [ebp+ebx*4]    ; &==+4
                xor     eax, eax
                dec     eax                 ; コード末マーク(-1)
                mov     [ecx] ,eax          ; コード末マーク
    .set_end:
                mov     bl, '&'             ; 空きメモリ先頭
                add     ecx, 4              ; コード末の次
                mov     [ebp+ebx*4], ecx
                call    WarmInit1           ; 入力デバイス変更なし
                ret
    .range_err: pop     edi
                call    RangeError
                ret

;-------------------------------------------------------------------------
; BRK *
;    メモリ最終位置を設定, brk
;-------------------------------------------------------------------------
Com_BRK:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                mov     ebx, eax            ; ebx にメモリサイズ
                mov     eax, SYS_brk        ; メモリ確保
                int     0x80
                xor     ebx, ebx
                mov     bl, '*'             ; ヒープ先頭
                mov     [ebp+ebx*4], eax
                ret

;-------------------------------------------------------------------------
; RANDOM '
;    乱数設定 /dev/urandom から必要バイト数読み出し
;    /usr/src/linux/drivers/char/random.c 参照
;-------------------------------------------------------------------------
Com_RANDOM:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                mov     cl, '`'             ; 乱数シード設定
                mov     [ebp+ecx*4], eax
                call    sgenrand
                ret

;-------------------------------------------------------------------------
; 文字列取得 " または EOL まで
;-------------------------------------------------------------------------
GetString:
                push    edi
                xor     ecx, ecx
                mov     edi, FileName
    .next:      call    GetChar
                cmp     al, '"'
                je      .exit
                or      al, al
                je      .exit
                mov     [edi + ecx], al
                inc     ecx
                cmp     ecx, FNAMEMAX
                jb      .next
    .exit:
                xor     al, al
                mov     [edi + ecx], al
                pop     edi
                ret

;-------------------------------------------------------------------------
; CodeWrite <=
;-------------------------------------------------------------------------
Com_CdWrite:
                push    edi
                push    esi
                call    GetFileName
                call    fwopen              ; open
                je      .exit
                js      .error
                mov     [ebp-12], eax       ; FileDescW
                xor     ebx, ebx
                mov     bl, '='
                mov     edi, [ebp+ebx*4]    ; コード先頭アドレス
    .loop:      mov     esi, input2         ; ワークエリア(行)
                mov     eax, [edi]          ; 次行へのオフセット
                inc     eax                 ; コード最終か?
                je     .exit                ; 最終なら終了
                mov     eax, [edi+4]        ; 行番号取得
                call    PutDecimal          ; 行番号書き込み
                mov     al, ' '             ; スペース書込み
                mov     [esi], al           ; Write One Char
                inc     esi
                mov     ebx, 8
    .code:      mov     al, [edi + ebx]     ; コード部分表示
                cmp     al, 0               ; 行末か?
                je      .next               ; file出力後次行
                mov     [esi], al           ; Write One Char
                inc     esi
                inc     ebx
                jmp     short .code
    .next:      add     edi, [edi]          ; 次行先頭へ
                mov     byte[esi], 10       ; 改行書込み
                inc     esi
                mov     byte[esi], 0        ; EOL
                mov     ecx, input2         ; バッファアドレス
                mov     eax, ecx
                call    StrLen
                mov     edx, eax            ; 書きこみバイト数
                mov     ebx, [ebp-12]       ; FileDescW
                mov     eax, SYS_write
                int     0x80
                jmp     short .loop         ; 次行処理
    .exit:
                mov     ebx, [ebp-12]       ; FileDescW
                call    fclose
                mov     byte[ebp-2], 1      ; EOL
                pop     esi
                pop     edi
                ret

    .error:     pop     esi
                pop     edi
                jmp     short SYS_Error

;-------------------------------------------------------------------------
; CodeRead >=
;-------------------------------------------------------------------------
Com_CdRead:
                cmp     byte[ebp-4], 1      ; Read from file
                je      .error
                call    GetFileName
                call    fropen              ; open
                je      .exit
                js      SYS_Error
                mov     [ebp-8], eax        ; FileDesc
                mov     byte[ebp-4], 1      ; Read from file
                mov     byte[ebp-2], 1      ; EOL
    .exit:      ret
    .error:
                mov     eax, error_cdread
                call    OutAsciiZ
                jmp     short SYS_Error.return

;-------------------------------------------------------------------------
; ファイル名をバッファに取得
;-------------------------------------------------------------------------
GetFileName:
                call    GetChar             ; skip =
                cmp     al, '='
                jne     .error
                call    GetChar             ; skip =
                cmp     al, '"'
                je      .file
                jmp     short .error
    .file:      call    GetString
                mov     eax, FileName       ; ファイル名表示
                ; call    OutAsciiZ
                mov     ebx, eax
                ret
    .error:
                pop     ebx                 ; スタック修正

;-------------------------------------------------------------------------
; 未定義コマンド処理(エラーストップ)
;-------------------------------------------------------------------------
SYS_Error:
                call    CheckError
    .return:    pop     ebx                 ; スタック修正
                call    WarmInit
                jmp     MainLoop

;-------------------------------------------------------------------------
; FileWrite (=
;-------------------------------------------------------------------------
Com_FileWrite:
                mov     al, [esi]           ; PeekChar
                cmp     al, '*'             ; (*=
                jne     .L1
                call    GetChar             ; skip (
                call    GetChar             ; skip =
                cmp     al, '='
                jne     near Com_Error
                call    Exp
                mov     ebx, eax
                jmp     short .L2
    .L1:        call    GetFileName
    .L2:        call    fwopen              ; open
                je      .exit
                js      SYS_Error
                mov     [ebp-12], eax       ; FileDescW

                xor     eax, eax
                mov     al, '{'
                mov     ecx, [ebp+eax*4]    ; バッファ指定
                mov     al, '}'             ; 格納領域最終
                mov     eax, [ebp+eax*4]    ;
                cmp     eax, ecx
                jb      .exit
                sub     eax, ecx
                mov     edx, eax            ; 書き込みサイズ
                mov     eax, SYS_write      ; システムコール番号
                mov     ebx, [ebp-12]       ; FileDescW
                int     0x80
                call    fclose
    .exit       ret

;-------------------------------------------------------------------------
; FileRead )=
;-------------------------------------------------------------------------
Com_FileRead:
                mov     al, [esi]           ; PeekChar
                cmp     al, '*'             ; )*=
                jne     .L1
                call    GetChar             ; skip )
                call    GetChar             ; skip =
                cmp     al, '='
                jne     near Com_Error
                call    Exp
                mov     ebx, eax
                jmp     short .L2
    .L1:        call    GetFileName
    .L2:        call    fropen              ; open
                je      .exit
                js      near SYS_Error
                mov     [ebp-12], eax       ; FileDescW

                mov     ebx, eax            ; 第１引数 : fd
                mov     eax, SYS_lseek      ; システムコール番号
                xor     ecx, ecx            ; 第２引数 : offset = 0
                mov     edx, SEEK_END       ; 第３引数 : origin
                int     0x80                ; ファイルサイズを取得

                push    eax                 ; file_size 退避
                mov     ebx, [ebp-12]       ; 第１引数 : fd
                mov     eax, SYS_lseek      ; システムコール番号
                xor     ecx, ecx            ; 第２引数 : offset=0
                xor     edx, edx            ; 第３引数 : origin=0
                int     0x80                ; ファイル先頭にシーク

                xor     eax, eax
                mov     al, '{'             ; 格納領域先頭
                mov     ecx, [ebp+eax*4]    ; バッファ指定
                pop     edx                 ; file_size 取得
                mov     al, ')'             ; 読み込みサイズ設定
                mov     [ebp+eax*4], edx
                mov     ebx, ecx
                add     ebx, edx
                mov     al, '}'             ; 格納領域最終設定
                mov     [ebp+eax*4], ebx    ;
                mov     al, '*'
                mov     eax, [ebp+eax*4]    ; RAM末
                cmp     eax, ebx
                jl      .exit               ; 領域不足

                mov     eax, SYS_read       ; システムコール番号
                mov     ebx, [ebp-12]       ; FileDescW
                int     0x80                ; ファイル全体を読みこみ
                push    eax
                mov     ebx, [ebp-12]       ; FileDescW
                call    fclose
                pop     eax
                test    eax,eax             ; エラーチェック
    .exit       ret

;-------------------------------------------------------------------------
; ファイル格納域先頭を指定
;-------------------------------------------------------------------------
Com_FileTop:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                push    edi
                mov     edi, eax
                call    RangeCheck          ; 範囲チェック
                pop     edi
                jb      Com_FileEnd.range_err   ; 範囲外をアクセス
                xor     ebx, ebx
                mov     bl, '{'             ; ファイル格納域先頭
                mov     [ebp+ebx*4], eax
                ret

;-------------------------------------------------------------------------
; ファイル格納域最終を指定
;-------------------------------------------------------------------------
Com_FileEnd:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                push    edi
                mov     edi, eax
                call    RangeCheck          ; 範囲チェック
                pop     edi
                jb      .range_err          ; 範囲外をアクセス
                xor     ebx, ebx
                mov     bl, '}'             ; ファイル格納域先頭
                mov     [ebp+ebx*4], eax
                ret
    .range_err:
                call    RangeError
                ret

;-------------------------------------------------------------------------
; CGI モードなら rvtl 終了
;-------------------------------------------------------------------------
CheckCGI:
                cmp     dword[cgiflag], 1   ; CGI mode ?
                je      Com_Exit
                ret

;-------------------------------------------------------------------------
; 終了
;-------------------------------------------------------------------------
Com_Exit:
                call    RESTORE_TERMIOS
                jmp     Exit

;-------------------------------------------------------------------------
; 範囲チェックフラグ [
;-------------------------------------------------------------------------
Com_RCheck:
                call    SkipEqualExp        ; = を読み飛ばした後 式の評価
                xor     ebx, ebx
                mov     bl, '['             ; 範囲チェック
                mov     [ebp+ebx*4], eax
                ret

;-------------------------------------------------------------------------
; 変数または式をスタックに保存
;-------------------------------------------------------------------------
Com_VarPush:
                mov     ecx, [ebp-16]       ; VSTACK
                mov     edx, VSTACKMAX - 1
    .next:
                cmp     ecx, edx
                jge     VarStackError.over
                call    GetChar
                cmp     al, '='             ; +=式
                jne     .push2
                call    Exp
                mov     [ebp+ecx*4+1024], eax    ; 変数スタックに式を保存
                inc     ecx
                jmp     short .exit
    .push2:     cmp     al, ' '
                je      .exit
                or      al, al
                ; cmp     byte [ebp-2], 1     ; EOL
                je      .exit
                mov     eax, [ebp+eax*4]    ; 変数の値取得
                mov     [ebp+ecx*4+1024], eax    ; 変数スタックに式を保存
                inc     ecx
                jmp     short .next
    .exit:
                mov     [ebp-16], ecx       ; スタックポインタ更新
                ret

;-------------------------------------------------------------------------
; 変数をスタックから復帰
;-------------------------------------------------------------------------
Com_VarPop:
                mov     ecx, [ebp-16]       ; VSTACK
    .next:
                call    GetChar
                cmp     al, ' '
                je      .exit
                or      al, al
                ; cmp     byte [ebp-2], 1     ; EOL
                je      .exit
                dec     ecx
                jl      VarStackError.under
                mov     ebx, [ebp+ecx*4+1024]    ; 変数スタックから復帰
                mov     [ebp+eax*4], ebx    ; 変数の値取得
                jmp     short .next
    .exit:
                mov     [ebp-16], ecx       ; スタックポインタ更新
                ret

;-------------------------------------------------------------------------
; 変数スタック範囲エラー
;-------------------------------------------------------------------------
VarStackError:
    .over:      mov     eax, vstkover
                jmp     short .print
    .under:     mov     eax, vstkunder
    .print:     call    OutAsciiZ
                call    WarmInit
                ret

;-------------------------------------------------------------------------
; ForkExec , 外部プログラムの実行
;-------------------------------------------------------------------------
Com_Exec:
%ifndef SMALL_VTL
                call    GetChar             ;
                cmp     al, '*'             ; ,*=A 形式
                jne     .normal
                call    GetChar             ; get =
                cmp     al, '='
                jne     near Com_Error
                call    Exp
                call    GetString2          ; FileNameにコピー
                jmp     short .parse
    .normal:    cmp     byte[esi], '"'
                jne     .filename           ; , /bin/xx 形式
                call    GetChar             ; ,="/bin/xx yy" 形式
    .filename:  call    GetFileName.file    ; 外部プログラム名取得
                call    NewLine

    .parse:     pusha
                call    ParseArg            ; コマンド行の解析
                mov     edi, ebx            ; リダイレクト先ファイル名
                inc     edx                 ; 子プロセスの数
                mov     ecx, exarg          ; char ** argp
                xor     ebp, ebp            ; 先頭プロセス
                cmp     edx, 1
                ja      .loop               ; パイプが必要
                mov     eax, SYS_fork       ; パイプ不要の場合
                int     0x80
                test    eax, eax
                je      .child              ; pid が 0 なら子プロセス
                jmp     short .wait
    .loop:
                mov     esi, ipipe          ; パイプをオープン
                mov     eax, SYS_pipe
                mov     ebx, esi            ; esi に pipe_fd 配列先頭
                int     0x80                ; pipe

        ;------------------------------------------------------------
        ; fork
        ;------------------------------------------------------------
                mov     eax, SYS_fork
                int     0x80
                test    eax, eax
                je      .child              ; pid が 0 なら子プロセス

        ;------------------------------------------------------------
        ; 親プロセス側の処理
        ;------------------------------------------------------------
                test    ebp, ebp            ; 先頭プロセスか?
                je      .not1st
                call    close_old_pipe
    .not1st:    push    eax                 ; 子プロセスの pid の保存
                mov     eax, [esi]          ; パイプ fd の移動
                mov     [esi+8], eax
                mov     eax, [esi+4]
                mov     [esi+12], eax
                pop     eax                 ; 子プロセスの pid の復帰
                dec     edx                 ; 残り子プロセスの数
                je      .done
    .findargp:  add     ecx, 4              ; 次のコマンド文字列探索
                cmp     dword[ecx], 0       ; 区切りを探す
                jne     .findargp
                add     ecx, 4              ; 次のコマンド文字列設定
                inc     ebp                 ; 次は先頭プロセスではない
                jmp     short   .loop
    .done:
                call    close_new_pipe
    .wait:
                mov     ebx, eax            ; 最後に起動したプロセスpid
                mov     eax, SYS_wait4      ; 終了を待つ
                mov     ecx, stat_addr
                mov     edx, WUNTRACED      ; WNOHANG
                mov     esi, ru             ; rusage
                int     0x80
                call    SET_TERMIOS         ; 子プロセスの設定を復帰
                popa
                ret

        ;------------------------------------------------------------
        ; 子プロセス側の処理
        ;------------------------------------------------------------
    .child:
                call    RESTORE_TERMIOS
                push    ecx                 ; ecx に char **argp 設定済
                dec     edx                 ; 最終プロセスチェック
                jne     .pipe_out           ; 最終プロセスでない
                test    edi, edi            ; リダイレクトがあるか
                je      .pipe_in            ; リダイレクト無し, 標準出力
                mov     ebx, edi            ; リダイレクト先ファイル名
                call    fwopen
                mov     ebx, eax            ; オープン済みのファイル fd
                mov     eax, SYS_dup2       ; 標準出力をファイルに
                xor     ecx, ecx
                inc     ecx                 ; 標準出力をファイルに差替え
                int     0x80                ; dup2
                call    fclose              ; ebx にはオープンしたfd
                jmp     short .pipe_in

    .pipe_out:  mov     eax, SYS_dup2       ; 標準出力をパイプに
                mov     ebx, [esi + 4]      ; 新パイプの書込み fd
                xor     ecx, ecx            ; new_fd
                inc     ecx                 ; 標準出力
                int     0x80                ; dup2
                call    close_new_pipe
    .pipe_in:   test    ebp, ebp            ; 先頭プロセスならスキップ
                je      .execve
                mov     eax, SYS_dup2       ; 標準入力をパイプに
                mov     ebx, [esi+8]        ; 前のパイプの読出し fd
                xor     ecx, ecx            ; new_fd 標準入力
                int     0x80                ; dup2
                call    close_old_pipe
    .execve:
                pop     ecx                 ; ecx に char **argp 設定済
                mov     eax, SYS_execve     ; 変身
                mov     ebx, [ecx]          ; char * filename
                mov     edx, [envp]         ; char ** envp
                int     0x80
                call    CheckError          ; 正常ならここには戻らない
                call    Exit                ; 単なる飾り

close_new_pipe:
                push    eax
                mov     ebx, [esi + 4]      ; 出力パイプをクローズ
                call    fclose
                mov     ebx, [esi]          ; 入力パイプをクローズ
                call    fclose
                pop     eax
                ret
close_old_pipe:
                push    eax
                mov     ebx, [esi + 12]     ; 出力パイプをクローズ
                call    fclose
                mov     ebx, [esi + 8]      ; 入力パイプをクローズ
                call    fclose
                pop     eax
                ret
%endif

;-------------------------------------------------------------------------
; 組み込みコマンドの実行
;-------------------------------------------------------------------------
Com_Function:
%ifndef SMALL_VTL
                call    GetChar             ; | の次の文字
    .func_c     cmp     al, 'c'
                jne     .func_d
                call    def_func_c          ; |c
                ret
    .func_d:
    .func_e:    cmp     al, 'e'
                jne     .func_f
                call    def_func_e          ; |e
                ret
    .func_f:    cmp     al, 'f'
                jne     .func_l
                call    def_func_f          ; |f
                ret
    .func_l:    cmp     al, 'l'
                jne     .func_m
                call    def_func_l          ; |l
                ret
    .func_m:    cmp     al, 'm'
                jne     .func_n
                call    def_func_m          ; |m
                ret
    .func_n:
    .func_p:    cmp     al, 'p'
                jne     .func_q
                call    def_func_p          ; |p
                ret
    .func_q:
    .func_r:    cmp     al, 'r'
                jne     .func_s
                call    def_func_r          ; |r
                ret
    .func_s:    cmp     al, 's'
                jne     .func_t
                call    def_func_s          ; |s
                ret
    .func_t:
    .func_u:    cmp     al, 'u'
                jne     .func_v
                call    def_func_u          ; |u
                ret
    .func_v:    cmp     al, 'v'
                jne     .func_z
                call    def_func_v          ; |v
                ret
    .func_z:    cmp     al, 'z'
                jne     func_error
                call    def_func_z          ; |z
                ret
func_error:
                jmp     Com_Error

;------------------------------------
; |c で始まる組み込みコマンド
;------------------------------------
def_func_c:
                call    GetChar             ;
                cmp     al, 'a'
                je      .func_ca            ; cat
                cmp     al, 'd'
                je      .func_cd            ; cd
                cmp     al, 'm'
                je      .func_cm            ; chmod
                cmp     al, 'r'
                je      .func_cr            ; chroot
                cmp     al, 'w'
                je      near .func_cw       ; pwd
                jmp     short func_error
    .func_ca:
                mov     eax, msg_f_ca       ; |ca file
                call    FuncBegin
                mov     ebx, [ebx]          ; filename
                call    DispFile
                ret
    .func_cd:
                mov     eax, msg_f_cd       ; |cd path
                call    FuncBegin
                mov     ebx, [ebx]          ; char ** argp
                mov     eax, FileName
                call    OutAsciiZ
                call    NewLine
                mov     eax, SYS_chdir
                int     0x80
                call    CheckError
                ret
    .func_cm:
                mov     eax, msg_f_cm       ; |cm 644 file
                call    FuncBegin
                mov     eax, [ebx]          ; permission
                mov     ebx, [ebx+4]        ; file name
                call    Oct2Bin
                mov     ecx, eax
                mov     eax, SYS_chmod
                int     0x80
                call    CheckError
                ret
    .func_cr:
                mov     eax, msg_f_cr       ; |cr path
                call    FuncBegin
                mov     ebx, [ebx]          ; char ** argp
                mov     eax, FileName
                call    OutAsciiZ
                call    NewLine
                mov     eax, SYS_chroot
                int     0x80
                call    CheckError
                ret
    .func_cw:
                mov     eax, msg_f_cw      ; |cw
                call    OutAsciiZ
                mov     ebx, FileName
                mov     ecx, FNAMEMAX
                mov     eax, SYS_getcwd
                int     0x80
                call    CheckError
                mov     eax, ebx
                call    OutAsciiZ
                call    NewLine
                ret

;------------------------------------
; |e で始まる組み込みコマンド
;------------------------------------
def_func_e:
                call    GetChar             ;
                cmp     al, 'x'
                je      .func_ex            ; execve
                jmp     func_error
    .func_ex:   mov     eax, msg_f_ex       ; |ex file arg ..
                call    RESTORE_TERMIOS     ; 端末設定を戻す
                call    FuncBegin
                mov     eax, SYS_execve     ; 変身
                mov     ecx, ebx            ; char ** argp
                mov     ebx, [ecx]          ; char * filename
                mov     edx, [ecx-12]       ; char ** envp
                int     0x80
                call    CheckError          ; 正常ならここには戻らない
                call    SET_TERMIOS         ; 端末のローカルエコーをOFF
                ret

;------------------------------------
; |f で始まる組み込みコマンド
;------------------------------------
def_func_f:
%ifdef FRAME_BUFFER
%include        "vtlfb.inc"
%endif

;------------------------------------
; |l で始まる組み込みコマンド
;------------------------------------
def_func_l:
                call    GetChar             ;
                cmp     al, 's'
                je      .func_ls            ; ls
                jmp     func_error

    .func_ls:   pusha
                mov     eax, msg_f_ls       ; |ls dir
                call    FuncBegin
                mov     eax, [ebx]
                mov     edx, eax
                mov     ebx, DirName
                mov     byte[ebx], 0
                test    eax, eax
                je      .empty
                call    StrLen
                mov     ecx, eax
                push    si
                push    di
                mov     esi, edx
                mov     edi, ebx
                rep     movsb
                cmp     byte[edi-1], '/'
                je      .end
                mov     byte[edi] ,'/'
                inc     edi
    .end:       mov     byte[edi], 0
                pop     di
                pop     si
                jmp     short .list
    .empty:     mov     ebx, current_dir
    .list:      call    fropen
                js      .exit0
                mov     esi, eax            ; fd
    .getdents:
                mov     ebx, esi            ; esi : fd
                mov     ecx, dir_ent
                mov     edx, size_dir_ent
                mov     eax, SYS_getdents
                int     0x80
                test    eax, eax            ; valid buffer length
                js      .exit0
                je      .exit
                mov     edi, ecx            ; edi : struct top (dir_ent)
                mov     ebp, eax            ; ebp : buffer size
    .next:
                call    GetFileStat
                mov     eax, [file_stat.st_mode]
                mov     ecx, 6
                call    PrintOctal          ; mode
                mov     eax, [file_stat.st_size+2]
                mov     ecx, 12
                call    PrintRight          ; file size
                mov     eax, ' '
                call    OutChar
                lea     eax, [edi+10]
                call    OutAsciiZ           ; filename
                call    NewLine
                movzx   eax, word[edi+8]
                sub     ebp, eax
                je      .getdents
                add     edi, eax
                jmp     short .next
    .exit0:
                call    CheckError
    .exit:      mov     ebx, esi            ; fd
                call    fclose
                popa
                ret

;------------------------------------
; |m で始まる組み込みコマンド
;------------------------------------
def_func_m:
                call    GetChar             ;
                cmp     al, 'd'
                je      .func_md            ; mkdir
                cmp     al, 'o'
                je      .func_mo            ; mo
                cmp     al, 'v'
                je      .func_mv            ; mv
    .func_error:jmp     func_error

    .func_md:   mov     eax, msg_f_md       ; |md dir [777]
                call    FuncBegin
                mov     eax, [ebx+4]        ; permission
                mov     ebx, [ebx]          ; directory name
                test    eax, eax
                je      .def
                call    Oct2Bin
                mov     ecx, eax
                jmp     short .not_def
    .def:       mov     ecx, 0755q
    .not_def:   mov     eax, SYS_mkdir
                int     0x80
                call    CheckError
                ret
    .func_mo:   mov     eax, msg_f_mo       ; |mo dev_name dir fstype
                call    FuncBegin
                push    edi
                push    esi
                push    ebp
                mov     ebp, ebx            ; exarg
                mov     ebx, [ebp]          ; dev_name
                mov     ecx, [ebp+4]        ; dir_name
                mov     edx, [ebp+8]        ; fstype
                mov     esi, [ebp+12]       ; flags
                or      esi, esi            ; Check ReadOnly
                je      .rw                 ; Read/Write
                mov     esi, [esi]
                mov     esi, MS_RDONLY      ; ReadOnly FileSystem
    .rw:        xor     edi, edi            ; void * data
                mov     eax, SYS_mount
                int     0x80
                call    CheckError
                pop     ebp
                pop     esi
                pop     edi
                ret
    .func_mv:   mov     eax, msg_f_mv       ; |mv fileold filenew
                call    FuncBegin
                mov     ecx, [ebx+4]
                mov     ebx, [ebx]
                mov     eax, SYS_rename
                jmp     short SysCallCheckReturn

;------------------------------------
; |p で始まる組み込みコマンド
;------------------------------------
def_func_p:
                call    GetChar             ;
                cmp     al, 'v'
                je      .func_pv            ; pivot_root
    .func_error:jmp     func_error

    .func_pv:   mov     eax, msg_f_pv       ; |pv /dev/hda2 /mnt
                call    FuncBegin
                mov     ecx, [ebx+4]
                mov     ebx, [ebx]
                mov     eax, SYS_pivot_root
                jmp     short SysCallCheckReturn

;------------------------------------
; |r で始まる組み込みコマンド
;------------------------------------
def_func_r:
                call    GetChar             ;
                cmp     al, 'd'
                je      .func_rd            ; rmdir
                cmp     al, 'm'
                je      .func_rm            ; rm
                cmp     al, 't'
                je      .func_rt            ; rt
    .func_error:jmp     short def_func_p.func_error

    .func_rt:                               ; reset terminal
                mov     eax, msg_f_rt       ; |rt
                call    OutAsciiZ
                call    SET_TERMIOS2        ; cooked mode
                call    GET_TERMIOS         ; termios の保存
                call    SET_TERMIOS         ; raw mode
                ret

     .func_rd:   mov     eax, msg_f_rd       ; |rd path
                call    FuncBegin           ; char ** argp
                mov     ebx, [ebx]
                mov     eax, SYS_rmdir
                jmp     short SysCallCheckReturn
    .func_rm:   mov     eax, msg_f_rm       ; |rm path
                call    FuncBegin           ; char ** argp
                mov     ebx, [ebx]
                mov     eax, SYS_unlink

SysCallCheckReturn:
                int     0x80
                call    CheckError
                ret

;------------------------------------
; |s で始まる組み込みコマンド
;------------------------------------
def_func_s:
                call    GetChar             ;
                cmp     al, 'f'
                je      .func_sf            ; swapoff
                cmp     al, 'o'
                je      .func_so            ; swapon
                cmp     al, 'y'
                je      .func_sy            ; sync
    .func_error:jmp     short def_func_r.func_error

    .func_sf:   mov     eax, msg_f_sf       ; |sf dev_name
                call    FuncBegin           ; const char * specialfile
                mov     ebx, [ebx]
                mov     eax, SYS_swapoff
                jmp     short SysCallCheckReturn

    .func_so:   mov     eax, msg_f_so       ; |so dev_name
                call    FuncBegin
                xor     ecx, ecx            ; int swap_flags
                mov     ebx, [ebx]          ; const char * specialfile
                mov     eax, SYS_swapon
                jmp     short SysCallCheckReturn2

    .func_sy:   mov     eax, msg_f_sy       ; |sy
                call    OutAsciiZ
                mov     eax, SYS_sync
                jmp     short SysCallCheckReturn2

;------------------------------------
; |u で始まる組み込みコマンド
;------------------------------------
def_func_u:
                call    GetChar             ;
                cmp     al, 'm'
                je      .func_um            ; umount
                cmp     al, 'd'
                je      func_ud             ; umount
                jmp     short def_func_s.func_error

    .func_um:   mov     eax, msg_f_um       ; |um dev_name
                call    FuncBegin           ;
                mov     ebx, [ebx]          ; dev_name
                mov     eax, SYS_umount     ; sys_oldumount
SysCallCheckReturn2:
                jmp     SysCallCheckReturn

     func_ud:
                ;------------------------------------
                ; URL デコード
                ;  u[0] URLエンコード文字列の先頭設定
                ;  u[1] 変更範囲の文字数を設定
                ;  u[2] デコード後の文字列先頭を設定
                ;  u[3] デコード後の文字数を返す
                ;------------------------------------
                pusha
                xor     ebx, ebx
                mov     bl, 'u'             ; 引数
                mov     ebp, [ebp+ebx*4]    ; ebp : argument top
                mov     eax, [ebp]          ; URLエンコード文字列の先頭設定
                mov     ebx, [ebp +  4]     ; 変更範囲の文字数を設定
                mov     ecx, [ebp +  8]     ; デコード後の文字列先頭を設定
                call    URL_Decode
                mov     [ebp + 12], eax     ; デコード後の文字数を設定
                popa
                ret

;------------------------------------
; |v で始まる組み込みコマンド
;------------------------------------
def_func_v:
                call    GetChar             ;
                cmp     al, 'e'
                je      .func_ve            ; version
                cmp     al, 'c'
                je      .func_vc            ; cpu
    .func_error:jmp     func_error

    .func_ve:
                xor     ebx, ebx
                mov     bl, '%'             ; 引数
                mov     dword[ebp+ebx*4], VERSION
                ret

    .func_vc:
                xor     ebx, ebx
                mov     bl, '%'             ; 引数
                mov     dword[ebp+ebx*4], CPU
                ret

;------------------------------------
; |zz システムコール
;------------------------------------
def_func_z:
                call    GetChar             ;
                cmp     al, 'c'
                je      .func_zc            ; system call
                cmp     al, 'z'
                je      .func_zz            ; system call
                jmp     short def_func_v.func_error
    .func_zc:
	        mov     eax,dword[counter]     
                xor     ebx, ebx
                mov     bl, '%'             ; 引数
                mov     dword[ebp+ebx*4], eax
                ret

    .func_zz:
                call    GetChar             ; skip space
                push    edi
                push    esi
                xor     ecx, ecx
                mov     cl, 'a'
                mov     eax, [ebp+ecx*4]    ; [a] syscall no.
                inc     ecx
                mov     ebx, [ebp+ecx*4]    ; [b] param1
                inc     ecx
                inc     ecx
                mov     edx, [ebp+ecx*4]    ; [d] param3
                inc     ecx
                mov     esi, [ebp+ecx*4]    ; [e] param4
                inc     ecx
                mov     edi, [ebp+ecx*4]    ; [f] param5
                sub     cl, 3
                mov     ecx, [ebp+ecx*4]    ; [c] param2
                int     0x80
                pop     esi
                pop     edi
                call    CheckError
                ret

;---------------------------------------------------------------------
; AL の文字が16進数字かどうかのチェック
; 数字なら整数に変換して AL 返す. 非数字ならキャリーセット
;---------------------------------------------------------------------

IsHex:          call    IsHex1              ; 英文字か?
                jae     .yes
                call    IsHex2
                jb      IsHex2.no
    .yes:       clc
                ret

IsHex1:         cmp     al, "A"             ; 英大文字(A-F)か?
                jb      IsHex2.no
                cmp     al, "F"
                ja      IsHex2.no
                sub     al, "A"
                add     al, 10
                clc
                ret

IsHex2:         cmp     al, "a"             ; 英小文字(a-f)か?
                jb      .no
                cmp     al, "f"
                ja      .no
                sub     al, "a"
                add     al, 10
                clc
                ret
    .no:        stc
                ret

IsHexNum:       call    IsHex               ; 16進文字？
                jae     .yes
                call    IsNum
                jb      IsHex2.no
                sub     al, "0"
    .yes:       clc
                ret

;-------------------------------------
; URLデコード
;
; eax にURLエンコード文字列の先頭設定
; ebx に変更範囲の文字数を設定
; ecx にデコード後の文字列先頭を設定
; eax にデコード後の文字数を返す
;-------------------------------------
URL_Decode:
                pusha
                mov     esi, eax
                mov     edi, ecx
                xor     eax, eax
                xor     ecx, ecx
                push    esi
    .next:
                mov     al, [esi]           ; エンコード文字
                cmp     al, '+'
                jne     .urld2
                mov     al, ' '
                mov     [edi + ecx], al     ; デコード文字
                jmp     .urld4
    .urld2:
                cmp     al, '%'
                je      .urld3
                mov     [edi + ecx], al     ; 非エンコード文字
                jmp     .urld4

    .urld3:
                xor     edx, edx
                inc     esi
                mov     al, [esi]
                call    IsHexNum
                jb      .urld4
                add     dl, al
                inc     esi
                mov     al, [esi]
                call    IsHexNum
                jb      .urld4
                shl     dl, 4
                add     dl, al
                mov     [edi + ecx], dl
    .urld4:
                inc     esi
                inc     ecx
                mov     edx, [esp]          ; initial esi
                sub     edx, esi
                neg     edx
                cmp     edx, ebx
                jl      .next
                pop     esi
                xor     eax, eax
                mov     [edi + ecx], al
                mov     [esp+28], ecx       ; eax に文字数を返す
                popa
                ret

;-------------------------------------------------------------------------
; 組み込み関数用
;-------------------------------------------------------------------------
FuncBegin:
                call    OutAsciiZ           ; 必要か？
                call    GetChar             ; 空白か等号
                cmp     al, "*"
                jne     .line
                call    SkipEqualExp        ; eax にアドレス
                push    edi                 ; コピー先退避
                mov     edi, eax            ; RangeCheckはediを見る
                call    RangeCheck          ; コピー元を範囲チェック
                pop     edi                 ; コピー先復帰
                jb      .range_err          ; 範囲外をアクセス

                call    GetString2          ; FileNameにコピー
                jmp     short .parse
    .line:      cmp     byte[esi], '"'      ; コード行から
                jne     .get
                call    GetChar             ; skip "
    .get:       call    GetString           ; パス名の取得
    .parse:     call    ParseArg            ; 引数のパース
                mov     ebx, exarg
                ret

    .range_err: mov     eax, 0xFF           ; エラー文字を FF
                jmp     LongJump            ; アクセス可能範囲を超えた

;-------------------------------------------------------------------------
; eax のアドレスからFileNameにコピー
;-------------------------------------------------------------------------
  GetString2:
                push    edi
                mov     ebx, eax
                xor     ecx, ecx
                mov     edi, FileName
    .next:      mov     al, [ebx + ecx]
                mov     [edi + ecx], al
                or      al, al
                je      .exit
                inc     ecx
                cmp     ecx, FNAMEMAX
                jb      .next
    .exit:      pop     edi
                ret

;-------------------------------------------------------------------------
; 8進数文字列を数値に変換
; eax からの8進数文字列を数値に変換して eax に返す
;-------------------------------------------------------------------------
Oct2Bin:
                push    ebx
                push    edi
                mov     edi, eax
                xor     ebx, ebx
                call    GetOctal
                ja      .exit
                mov     ebx, eax
    .OctLoop:
                call    GetOctal
                ja      .exit
                shl     ebx, 3              ;
                add     ebx, eax
                jmp     short .OctLoop
    .exit:
                mov     eax, ebx
                pop     edi
                pop     ebx
                ret

;-------------------------------------------------------------------------
; edi の示す8進数文字を数値に変換して eax に返す
; 8進数文字でないかどうかは ja で判定可能
;-------------------------------------------------------------------------
GetOctal:
                xor     eax, eax
                mov     al, [edi]
                inc     edi
                sub     al, '0'
                cmp     al, 7
                ret

;-------------------------------------------------------------------------
; ファイル内容表示
; ebx にファイル名
;-------------------------------------------------------------------------
DispFile:
                pusha
                call    fropen              ; open
                call    CheckError
                je      .exit
                mov     edi, eax            ; FileDesc
                push    eax                 ; buffer on stack
    .next:
                mov     eax, SYS_read       ; システムコール番号
                mov     ebx, edi            ; fd
                mov     ecx, esp            ; バッファ指定
                xor     edx, edx
                mov     dl, 4
                int     0x80                ; ファイル 4 バイト
                test    eax, eax
                je      .done
                js      .done
                mov     edx, eax            ; # of bytes
                mov     eax, SYS_write
                xor     ebx, ebx
                inc     ebx                 ; 1:to stdout
                mov     ecx, esp
                int     0x80
                jmp     short .next

    .done:      pop     eax
                call    fclose
    .exit:      popa
                ret

;-------------------------------------------------------------------------
; execve 用の引数を設定
; コマンド文字列のバッファ FileName をAsciiZに変換してポインタの配列に設定
; edx に パイプの数 (子プロセス数-1) を返す．
; ebx にリダイレクト先ファイル名文字列へのポインタを返す．
;-------------------------------------------------------------------------
ParseArg:
                push    edi
                push    esi
                xor     ecx, ecx            ; 配列インデックス
                xor     edx, edx            ; パイプのカウンタ
                xor     ebx, ebx            ; リダイレクトフラグ
                mov     esi, FileName       ; コマンド文字列のバッファ
                mov     edi, exarg          ; ポインタの配列先頭
    .nextarg:
    .space:     mov     al, [esi]           ; 連続する空白のスキップ
                or      al, al              ; 行末チェック
                je      .exit
                cmp     al, ' '
                jne     .pipe               ; パイプのチェック
                inc     esi                 ; 空白なら次の文字
                jmp     short .space

    .pipe:      cmp     al, '|'             ; パイプ?
                jne     .redirect
                inc     edx                 ; パイプのカウンタ
                xor     eax, eax
                mov     [edi + ecx*4], eax  ; コマンドの区切り 0
                inc     ecx                 ; 配列インデックス
                jmp     short .check_and_next

    .redirect:  cmp     al, '>'             ; リダイレクト?
                jne     .arg
                inc     ebx
                xor     eax, eax
                mov     [edi + ecx*4], eax  ; コマンドの区切り 0
                inc     ecx                 ; 配列インデックス
                jmp     short .check_and_next

    .arg:       mov     [edi + ecx*4], esi  ; 引数へのポインタを登録
                inc     ecx
    .nextchar:  mov     al, [esi]           ; スペースを探す
                or      al, al              ; 行末チェック
                je      .found2
                cmp     al, ' '
                je      .found
                inc     esi
                jmp     short .nextchar
    .found:     mov     byte[esi], 0        ; スペースを 0 に置換
                test    ebx, ebx            ; リダイレクトフラグ
                je      .check_and_next
    .found2:    test    ebx, ebx            ; リダイレクトフラグ
                je      .exit
                dec     ecx
                mov     ebx, [edi + ecx*4]
                inc     ecx
                jmp     short .exit

    .check_and_next:
                inc     esi
                cmp     ecx, ARGMAX
                jae     .exit
                jmp     short .nextarg

    .exit:
                xor     eax, eax
                mov     [edi + ecx*4], eax  ; 引数ポインタ配列の最後
                pop     esi
                pop     edi
                ret

%endif

;-------------------------------------------------------------------------
; システムコールエラーチェック
;-------------------------------------------------------------------------
CheckError:
                push    ecx
                xor     ecx, ecx
                mov     cl, '|'             ; 返り値を | に設定
                mov     [ebp+ecx*4], eax
                pop     ecx
%ifdef  DETAILED_MSG
                call    SysCallError
%else
                test    eax, eax
                jns     .exit
                mov     eax, Error_msg
                call    OutAsciiZ
%endif
    .exit:      ret

;-------------------------------------------------------------------------
; ユーザ拡張コマンド処理
;-------------------------------------------------------------------------
Com_Ext:
%ifndef SMALL_VTL
%include        "ext.inc"
    .func_err:  jmp     func_error
%endif
                ret

;-------------------------------------------------------------------------
; コマンド用ジャンプテーブル
;-------------------------------------------------------------------------
                align   4

TblComm1:
        dd Com_GOSUB    ;   21  !  GOSUB
        dd Com_String   ;   22  "  文字列出力
        dd Com_GO       ;   23  #  GOTO 実行中の行番号を保持
        dd Com_OutChar  ;   24  $  文字コード出力
        dd Com_Error    ;   25  %  直前の除算の剰余または usec を保持
        dd Com_NEW      ;   26  &  NEW, VTLコードの最終使用アドレスを保持
        dd Com_Error    ;   27  '  文字定数
        dd Com_FileWrite;   28  (  File 書き出し
        dd Com_FileRead ;   29  )  File 読み込み, 読み込みサイズ保持
        dd Com_BRK      ;   2A  *  メモリ最終(brk)を設定, 保持
        dd Com_VarPush  ;   2B  +  ローカル変数PUSH, 加算演算子, 絶対値
        dd Com_Exec     ;   2C  ,  fork & exec
        dd Com_VarPop   ;   2D  -  ローカル変数POP, 減算演算子, 負の十進数
        dd Com_Space    ;   2E  .  空白出力
        dd Com_NewLine  ;   2F  /  改行出力, 除算演算子
TblComm2:
        dd Com_Comment  ;   3A  :  行末まで注釈
        dd Com_IF       ;   3B  ;  IF
        dd Com_CdWrite  ;   3C  <  rvtlコードのファイル出力
        dd Com_Top      ;   3D  =  コード先頭アドレス
        dd Com_CdRead   ;   3E  >  rvtlコードのファイル入力
        dd Com_OutNum   ;   3F  ?  数値出力  数値入力
        dd Com_DO       ;   40  @  DO UNTIL NEXT
TblComm3:
        dd Com_RCheck   ;   5B  [  Array index 範囲チェック
        dd Com_Ext      ;   5C  \  拡張用  除算演算子(unsigned)
        dd Com_Return   ;   5D  ]  RETURN
        dd Com_Comment  ;   5E  ^  ラベル宣言, 排他OR演算子, ラベル参照
        dd Com_USleep   ;   5F  _  usleep, gettimeofday
        dd Com_RANDOM   ;   60  `  擬似乱数を保持 (乱数シード設定)
TblComm4:
        dd Com_FileTop  ;   7B  {  ファイル先頭(ヒープ領域)
        dd Com_Function ;   7C  |  組み込みコマンド, エラーコード保持
        dd Com_FileEnd  ;   7D  }  ファイル末(ヒープ領域)
        dd Com_Exit     ;   7E  ~  VTL終了

;==============================================================
section .data

  envstr        db   'PATH=/bin:/usr/bin', 0
  env           dd   envstr, 0
  cginame       db   'wltvr', 0

%ifndef SMALL_VTL
start_msg       db   'RVTL v.3.05 2015/10/05'
                db   ', Copyright 2002-2015 Jun Mizutani', 10,
                db   'RVTL may be copied under the terms of the GNU',
                db   ' General Public License.', 10
%ifdef DEBUG
                db   'DEBUG VERSION', 10
%endif
                db   0
%endif

initvtl         db   '/etc/init.vtl',0
prompt1         db   10,'<',0
prompt2         db   '> ',0
equal_err       db   10,'= reqiured.',0
syntaxerr       db   10,'Syntax error! at line ', 0
stkunder        db   10,'Stack Underflow!', 10, 0
stkover         db   10,'Stack Overflow!', 10, 0
vstkunder       db   10,'Variable Stack Underflow!', 10, 0
vstkover        db   10,'Variable Stack Overflow!', 10, 0
Range_msg       db   10,'Out of range!', 10, 0
EndMark_msg     db   10,'&=0 required.', 10, 0
Error_msg       db   10,'Error!', 10, 0
err_div0        db   10,'Divided by 0!',10,0
err_exp         db   10,'Error in Expression at line ',0
err_label       db   10,'Label not found!',10,0
err_vstack      db   10,'Empty stack!',10,0
error_cdread    db   10,'Code Read (>=) is not allowed!',10,0
no_direct_mode  db   10,"Direct mode is not allowed!", 10,0

                align 4
stat_addr       dd   0

;-------------------------------------------------------------------------
; 組み込み関数用メッセージ
;-------------------------------------------------------------------------
%ifndef SMALL_VTL
    msg_f_ca    db   0
    msg_f_cd    db   'Change Directory to ',0
    msg_f_cm    db   'Change Permission ',10, 0
    msg_f_cr    db   'Change Root to ',0
    msg_f_cw    db   'Current Working Directory : ',0
    msg_f_ex    db   'Exec Command',10, 0
    msg_f_ls    db   'List Directory ',10, 0
    msg_f_md    db   'Make Directory ',10, 0
    msg_f_mv    db   'Change Name',10, 0
    msg_f_mo    db   'Mount',10, 0
    msg_f_pv    db   'Pivot Root',10, 0
    msg_f_rd    db   'Remove Directory',10, 0
    msg_f_rm    db   'Remove File',10, 0
    msg_f_rt    db   'Reset Termial',10, 0
    msg_f_sf    db   'Swap Off',10, 0
    msg_f_so    db   'Swap On',10, 0
    msg_f_sy    db   'Sync',10, 0
    msg_f_um    db   'Unmount',10, 0
%endif
;==============================================================
section .bss

cgiflag         resd    1
counter         resd    1
current_arg     resd    1
argc            resd    1
argvp           resd    1
envp            resd    1           ; exarg - 12
argc_vtl        resd    1
argp_vtl        resd    1
exarg           resd ARGMAX+1       ; execve 用
ipipe           resd    1
opipe           resd    1
ipipe2          resd    1
opipe2          resd    1
save_stack      resd    1

                alignb  4
input2          resb    MAXLINE
FileName        resb    FNAMEMAX
pid             resd    1           ; ebp-24
FOR_direct      resb    1           ; ebp-20
ExpError        resb    1           ; ebp-19
ZeroDiv         resb    1           ; ebp-18
SigInt          resb    1           ; ebp-17
VSTACK          resd    1           ; ebp-16
FileDescW       resd    1           ; ebp-12
FileDesc        resd    1           ; ebp-8
ReadFrom        resb    1           ; ebp-4
ExecMode        resb    1           ; ebp-3
EOL             resb    1           ; ebp-2
LSTACK          resb    1           ; ebp-1
VarArea         resd  256           ; ebp    後半128dwordはLSTACK用
VarStack        resd VSTACKMAX      ; ebp+1024
%ifdef VTL_LABEL
                alignb  4
LabelTable      resd    LABELMAX*4  ; 1024*16 bytes
TablePointer    resd    1
%endif

