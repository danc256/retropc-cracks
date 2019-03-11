code           segment
               assume cs:code
               org 100h

start:

               jmp loader                       ;Go to program start!

               ;This is the DATA portion for the actual TSR that
               ;MUST remain resident...

               serial        dw  0001h          ;Serial  # for PATCH
               version       dw  0110h          ;Version # for PATCH
               loader_ver    dw  0150h          ;Version # for SHELL

               ;WARNING-> NEVER EVER change anything ABOVE THIS LINE!!!!!!
               ;OR the program will be SPAM!
               ;(You CAN change the actual values, just not location...)

               intvec_1    equ    19h           ;INT to be patched
              ;intvec_x    equ    xxh           ;ADDITIONAL INT(s)

               old_vector_1  dd  0,0            ;Storage for old INT
              ;old_vector_x  dd  0,0            ;Storage for old INT xx


patch_1        proc near                        ;Patch_x for INT xx
               assume cs:code

               push   bp              ;Save registers...
               push   es
               push   bx

               mov    bp,sp
               mov    es,ss:[bp+08]     ;Calculate seg:offset of INT call

               mov    bx,ss:[bp+06]
               dec    bx
               dec    bx

               mov    es:[bx],1275h     ;Cover it up

               mov    bx,ss:[bp+06]     ;Move the IP so that on return,
               add    bx,22h            ;it skips over the check!
               mov    ss:[bp+06],bx

               pop    bx                ;Restore registers
               pop    es
               pop    bp

               iret

patch_1        endp

end_resident:

verify_serial  proc near

               clc                              ; Pass for now...
               ret

verify_serial  endp



MCB_walker     proc near

               mov ah, 52h                     ; Get List of Lists (DOS)
               int 21h
               mov ax, es:[bx-2]               ; First MCB address (segment)
               mov es, ax                      ; Toss segment back in ES

               mov bx,05h                      ; An unused word in MCB
               jmp walk_loop                   ; That we'll use for ID

next_bloc:

               mov ax, es                      ; Calculate next block in chain
               mov cx, word ptr es:[3]
               inc cx                       ; Compensate for MCB size itself!
               add ax, cx
               mov es, ax

walk_loop:

               mov ah,es:[0]               ; MCB chain (M = Link, Z = end)
               cmp word ptr es:[bx],0ffffh ; Found our TSR ID byte?
               jne  n_found_ID
               call verify_serial          ; Was the serial# correct?
               jc   found_ID               ; Yep, 'its in there...'
n_found_ID:

               cmp ah,'M'                  ; No ID found, more blocks though?
               je  next_bloc               ; Yes, keep a chuggin'
               cmp ah,'Z'                  ; Are we at the end of the chain?
               je  no_ID                   ; Yes, ID NOT FOUND (install TSR)


                                           ; Corrupted MCB chain [FATAL ERROR]
               mov dx, offset fatal_mess   ; If it got past previous checks!
               call mess                   ; Print Fatal error message
               jmp  terminate              ; Abort....

found_ID:

        mov dx, offset found_mess
        call mess
        jmp  terminate

no_ID:

        mov dx, offset no_mess
        call mess

terminate:

        mov ax,4c00h
        int 21h

MCB_walker endp


set_vec          proc near

                 assume cs:code,ds:code

                 tsr_size  equ   ((end_resident-start)/16)+17 ;inefficient

                 mov    ax,3500h+intvec_1               ;vector swap-age
                 int    21h
                 mov    word ptr [old_vector_1+2],es
                 mov    word ptr [old_vector_1],bx

                
                 mov    ax,2500h+intvec_1
                 mov    dx,offset patch_1
                 push   cs
                 pop    ds
                 int    21h

                 mov    ax,3500h+ser_vec
                 int    21h
                 mov    word ptr [ser_vector+2],es
                 mov    word ptr [ser_vector],bx


                 mov    ax,2500h+ser_vec
                 mov    dx,offset serv
                 push   cs
                 pop    ds
                 int    21h

set_vec    endp


loader           proc near

                 call   MCB_walker      ;is the TSR loaded already?
                 jnc    install         ;Nope, menu display...
                 jmp    remove          ;Its there already!  (kill)

install:
                 call   set_ID                  ;Make fix to MCB for ID
                                                ;4 now, generic text screen
                 mov    dx,offset copy_right    ;Fix this last to look kewl
                 call   mess

                 call   set_vec                 ;Set up interrupt ptrs...
                 
                 mov    ax,31ffh                ;TSR and take off...
                 mov    dx,tsr_size
                 int    21h

                 mov    dx, offset u_error      ;unexpected error!
                 jmp    fatal_error

remove:
                 cmp    ax,serial               ;Some error messages
                 je    l2
                 mov    dx, offset s_err_msg
                 jmp    fatal_error
l2:
                 cmp    bx,version
                 je    l3
                 mov    dx,offset v_err_msg
                 jmp    fatal_error
l3:
                 cmp    cx,loader_ver
                 je    l4
                 mov    dx,offset l_v_err_msg
                 jmp    fatal_error
l4:
                 mov    dx,offset i_msg

fatal_error:
                 call   mess
                 jmp    terminate

loader           endp

   ; ALL error messages FIRST & THEN the funky-text...

   ; Error messages and stuff...(FOR MCB_WALKER)

   fatal_mess db 'BREAK IN MCB CHAIN - SYSTEM WILL CRASH!$'
   found_mess db 'ID byte for xxx FOUND!$'
   no_mess    db 'ID byte NOT FOUND for xxx!$'

   s_err_msg    db  'There is already another Generic TSR installed!',10,13
   xs1          db  '$'
   v_err_msg    db  'There is a different version of the PATCH in memory'
   xv1          db  ' already!',10,13,'$'
   l_v_err_msg  db  'There is a different version of the SHELL in memory'
   xlv1         db  ' already!',10,13,'$'
   i_msg        db  'This patch has already been installed!',10,13,'$'
   u_error      db  'UNEXPECTED ERROR!  (Something is REALLY spammed!)',10,13
   xu1          db  '$'

   copy_right   db  'Generic TSR-Shell v1.50 (c) 1991 GHT - '
   xcr2         db  'PATCH for MODEM WARZ',10,13
   xcr3         db  'Support BBS: Atlantis (717) 825-5766',10,13,'$'


code           ends
end            start
