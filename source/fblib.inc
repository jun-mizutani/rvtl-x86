;-------------------------------------------------------------------------
;  file : fblib.inc
;  2015/08/30
;  Copyright (C) 2001-2015  Jun Mizutani <mizutani.jun@nifty.ne.jp>
;-------------------------------------------------------------------------

%include    "fb.inc"
%include    "mman.inc"

%assign O_RDWR               02q

;==============================================================
section .text

;-------------------------------------------------------------------------
; フレームバッファのデバイスファイルをオープン
;-------------------------------------------------------------------------
fbdev_open:
                mov     eax, SYS_open       ; /dev/fb0 のオープン
                mov     ebx, fb_device
                mov     ecx, O_RDWR
                int     0x80
                mov     [fb_desc], eax      ; /dev/fb0 の fd を保存
                mov     [mmap_arg.fd], eax
                test    eax, eax
                ret
fb_device       db      "/dev/fb0", 0

;-------------------------------------------------------------------------
; フレームバッファのデバイスファイルをクローズ
;-------------------------------------------------------------------------
fbdev_close:
                mov     eax, SYS_close       ; /dev/fb0
                mov     ebx, [fb_desc]
                int     0x80
                ret

;-------------------------------------------------------------------------
; フレームバッファの物理状態を取得
;-------------------------------------------------------------------------
fb_get_fscreen:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOGET_FSCREENINFO
                mov     edx, fscinfo        ; 保存先指定
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; 現在のフレームバッファの状態を保存
;-------------------------------------------------------------------------
fb_get_screen:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOGET_VSCREENINFO
                mov     edx, scinfo_save    ; 保存先指定
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; フレームバッファ設定を書きこむ
;-------------------------------------------------------------------------
fb_set_screen:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOPUT_VSCREENINFO
                mov     edx, scinfo_data    ; 設定済みデータ
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; 保存済みのフレームバッファ設定を新規設定用にコピー
;-------------------------------------------------------------------------
fb_copy_scinfo:
                push    esi
                push    edi
                mov     esi, scinfo_save    ; 保存済みデータ
                mov     edi, scinfo_data    ; 設定用データ
                mov     ecx, (fb_var_screeninfo_size / 4)
                cld
                rep movsd
                pop     edi
                pop     esi
                ret

;-------------------------------------------------------------------------
; フレームバッファメモリをマッピング
;-------------------------------------------------------------------------
fb_map_screen:
                mov     eax, [scinfo_data.yres_virtual]
                mul     dword [scinfo_data.xres_virtual]
                mov     ebx, [scinfo_data.bits_per_pixel]
                shr     ebx, 3
                mul     ebx
                mov     [mmap_arg.len], eax
                mov     dword[mmap_arg.prot], (PROT_READ | PROT_WRITE)
                mov     dword[mmap_arg.flags], MAP_SHARED
                xor     eax, eax
                mov     [mmap_arg.addr], eax
                mov     [mmap_arg.offset], eax
                mov     eax, SYS_old_mmap
                mov     ebx, mmap_arg
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; フレームバッファメモリをアンマップ
;-------------------------------------------------------------------------
fb_unmap_screen:
                mov     eax, SYS_munmap
                mov     ebx, [mmap_arg.addr]
                mov     ecx, [mmap_arg.len]
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; カラーマップ(パレット)を取得
;-------------------------------------------------------------------------
fb_get_colormap:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOGETCMAP
                mov     edx, colormap_save
                int     0x80
                test    eax, eax
                ret

;-------------------------------------------------------------------------
; カラーマップ(パレット)を設定
;-------------------------------------------------------------------------
fb_set_colormap:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOPUTCMAP
                mov     edx, colormap_data
                int     0x80
                ret

;-------------------------------------------------------------------------
; カラーマップ(パレット)を作成
;-------------------------------------------------------------------------
fb_test_colormap:
                push    edi
                xor     eax, eax
                mov     eax, 0xffff
                mov     edi, red_data
                mov     ecx, 0x100
    .loop:
                mov     [edi], ax
                mov     [edi+0x200], ax
                mov     [edi+0x400], ax
                sub     eax, 0x01
                inc     edi
                loop    .loop
                pop     edi
                ret

;-------------------------------------------------------------------------
; 保存済みのフレームバッファ設定を復帰
;-------------------------------------------------------------------------
fb_restore_sc:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOPUT_VSCREENINFO
                mov     edx, scinfo_save
                int     0x80
                ret

;-------------------------------------------------------------------------
; 保存済みのカラーマップ(パレット)を復帰
;-------------------------------------------------------------------------
fb_restore_cmap:
                mov     eax, SYS_ioctl
                mov     ebx, [fb_desc]
                mov     ecx, FBIOPUTCMAP
                mov     edx, colormap_save
                int     0x80
                ret

;==============================================================
section .data

                align   4
colormap_save istruc fb_cmap
    .start      dd    0           ; First entry
    .len        dd    0x100       ; Number of entries (256)
    .red        dd    red_save
    .green      dd    green_save
    .blue       dd    blue_save
    .transp     dd    0           ; transparency, can be NULL
iend

colormap_data istruc fb_cmap
    .start      dd    0           ; First entry
    .len        dd    0x100       ; Number of entries
    .red        dd    red_data
    .green      dd    green_data
    .blue       dd    blue_data
    .transp     dd    0           ; transparency, can be NULL
iend

;==============================================================
section .bss
                        alignb   4

fb_desc:                resd    1
fb_address:             resd    1

red_save:               resw    0x100
green_save:             resw    0x100
blue_save:              resw    0x100

red_data:               resw    0x100
green_data:             resw    0x100
blue_data:              resw    0x100

mmap_arg istruc mmap_arg_struct
    .addr       resd    1;
    .len        resd    1;
    .prot       resd    1;
    .flags      resd    1;
    .fd         resd    1;
    .offset     resd    1;
iend

                        alignb   4
scinfo_save:       istruc fb_var_screeninfo
    .xres               resd    1   ; visible resolution
    .yres               resd    1
    .xres_virtual       resd    1   ; virtual resolution
    .yres_virtual       resd    1
    .xoffset            resd    1   ; offset from virtual to visible
    .yoffset            resd    1   ; resolution
    .bits_per_pixel     resd    1   ; guess what
    .grayscale          resd    1   ; != 0 Graylevels instead of colors
    .red_offset         resd    1   ; beginning of bitfield
    .red_length         resd    1   ; length of bitfield
    .red_msb_right      resd    1   ; != 0 : Most significant bit is
    .green_offset       resd    1   ; beginning of bitfield
    .green_length       resd    1   ; length of bitfield
    .green_msb_right    resd    1   ; != 0 : Most significant bit is
    .blue_offset        resd    1   ; beginning of bitfield
    .blue_length        resd    1   ; length of bitfield
    .blue_msb_right     resd    1   ; != 0 : Most significant bit is
    .transp_offset      resd    1   ; beginning of bitfield
    .transp_length      resd    1   ; length of bitfield
    .transp_msb_right   resd    1   ; != 0 : Most significant bit is
    .nonstd             resd    1   ; != 0 Non standard pixel format
    .activate           resd    1   ; see FB_ACTIVATE_*
    .height             resd    1   ; height of picture in mm
    .width              resd    1   ; width of picture in mm
    .accel_flags        resd    1   ; acceleration flags (hints)
    .pixclock           resd    1   ; pixel clock in ps (pico seconds)
    .left_margin        resd    1   ; time from sync to picture
    .right_margin       resd    1   ; time from picture to sync
    .upper_margin       resd    1   ; time from sync to picture
    .lower_margin       resd    1
    .hsync_len          resd    1   ; length of horizontal sync
    .vsync_len          resd    1   ; length of vertical sync
    .sync               resd    1   ; see FB_SYNC_*
    .vmode              resd    1   ; see FB_VMODE_*
    .reserved           resd    6   ; Reserved for future compatibility
iend

                        alignb   4
scinfo_data:       istruc fb_var_screeninfo
    .xres               resd    1   ; visible resolution
    .yres               resd    1
    .xres_virtual       resd    1   ; virtual resolution
    .yres_virtual       resd    1
    .xoffset            resd    1   ; offset from virtual to visible
    .yoffset            resd    1   ; resolution
    .bits_per_pixel     resd    1   ; guess what
    .grayscale          resd    1   ; != 0 Graylevels instead of colors
    .red_offset         resd    1   ; beginning of bitfield
    .red_length         resd    1   ; length of bitfield
    .red_msb_right      resd    1   ; != 0 : Most significant bit is
    .green_offset       resd    1   ; beginning of bitfield
    .green_length       resd    1   ; length of bitfield
    .green_msb_right    resd    1   ; != 0 : Most significant bit is
    .blue_offset        resd    1   ; beginning of bitfield
    .blue_length        resd    1   ; length of bitfield
    .blue_msb_right     resd    1   ; != 0 : Most significant bit is
    .transp_offset      resd    1   ; beginning of bitfield
    .transp_length      resd    1   ; length of bitfield
    .transp_msb_right   resd    1   ; != 0 : Most significant bit is
    .nonstd             resd    1   ; != 0 Non standard pixel format
    .activate           resd    1   ; see FB_ACTIVATE_*
    .height             resd    1   ; height of picture in mm
    .width              resd    1   ; width of picture in mm
    .accel_flags        resd    1   ; acceleration flags (hints)
    .pixclock           resd    1   ; pixel clock in ps (pico seconds)
    .left_margin        resd    1   ; time from sync to picture
    .right_margin       resd    1   ; time from picture to sync
    .upper_margin       resd    1   ; time from sync to picture
    .lower_margin       resd    1
    .hsync_len          resd    1   ; length of horizontal sync
    .vsync_len          resd    1   ; length of vertical sync
    .sync               resd    1   ; see FB_SYNC_*
    .vmode              resd    1   ; see FB_VMODE_*
    .reserved           resd    6   ; Reserved for future compatibility
iend

fscinfo             istruc  fb_fix_screeninfo
    .id                 resb   16   ; identification string eg "TT Builtin"
    .smem_start         resd    1   ; Start of frame buffer mem
                                    ; (physical address)
    .smem_len           resd    1   ; Length of frame buffer mem
    .type               resd    1   ; see FB_TYPE_*
    .type_aux           resd    1   ; Interleave for interleaved Planes
    .visual             resd    1   ; see FB_VISUAL_*
    .xpanstep           resw    1   ; zero if no hardware panning
    .ypanstep           resw    1   ; zero if no hardware panning
    .ywrapstep          resw    1   ; zero if no hardware ywrap
    .padding            resw    1   ;  for alignment, jm 1/26/2001
    .line_length        resd    1   ; length of a line in bytes
    .mmio_start         resd    1   ; Start of Memory Mapped I/O
                                    ; (physical address)
    .mmio_len           resd    1   ; Length of Memory Mapped I/O
    .accel              resd    1   ; Type of acceleration available
    .reserved           resw    3   ; Reserved for future compatibility
iend

