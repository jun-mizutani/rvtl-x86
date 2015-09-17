;-------------------------------------------------------------------------
;  Return of the Very Tiny Language
;  version : 2.00  2002/06/12
;  Copyright (C) 2002 Jun Mizutani <mizutani.jun@nifty.ne.jp>
;
;  file : ext.inc
;-------------------------------------------------------------------------

                call    GetChar             ;
                cmp     al, 'j'
                je      .ext_j
                jmp     short .func_err

    .ext_j:
                call    GetChar             ;
                cmp     al, 'm'
                je      .ext_jm
                jmp     short .func_err
    .ext_jm:
                ret
