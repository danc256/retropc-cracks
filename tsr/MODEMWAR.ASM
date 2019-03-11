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

mess           proc near                ; AFFECTS FLAGS
                                        ; Outputs a string
                                        ; procedure print(var s:string);
               mov  ah,09h
               int  21h
               ret

mess           endp


verify_serial  proc near                ; AFFECTS FLAGS

               push ax
               mov  ax,es
               inc  ax
               mov  es,ax               ;INC ES (point to PSP instead of MCB)
               mov  cx,03h              ; 3 words...

               mov  di,103h             ; Both strings start at 103
                                        ; in their respective segments...
               mov  si,di
               repe cmpsw               ; Compare the Serial #'s
               je   pass_cmpsw
               dec  ax                  ; Flags & CX will be set...
               mov  es,ax               ; restore ES

pass_cmpsw:
               pop  ax
               ret

verify_serial  endp



MCB_walker     proc near

               mov ah, 52h                     ; Get List of Lists (DOS)
               int 21h
               mov ax, es:[bx-2]               ; First MCB address (segment)
               mov es, ax                      ; Toss segment back in ES

               jmp walk_loop                   ; That we'll use for ID

next_bloc:

               mov ax, es                      ; Calculate next block in chain
               mov bx, word ptr es:[3]
               inc bx                       ; Compensate for MCB size itself!
               add ax, bx
               mov es, ax

walk_loop:

               mov ah,es:[0]               ; MCB chain (M = Link, Z = end)
               cmp word ptr es:[5],0ffffh  ; Found our TSR ID byte?
               jne  n_found_ID
               call verify_serial          ; Was the serial# correct?
               jnz   n_found_ID
               ret                         ; Its in there! (ragu)
n_found_ID:

               cmp ah,'M'                  ; No ID found, more blocks though?
               je  next_bloc               ; Yes, keep a chuggin'
               cmp ah,'Z'                  ; Are we at the end of the chain?
               jne no_ID                   ; Yes, ID NOT FOUND (install TSR)
               ret

no_ID:
                                           ; Corrupted MCB chain [FATAL ERROR]
               mov dx, offset fatal_mess   ; If it got past previous checks!
               call mess                   ; Print Fatal error message

terminate:

               mov ax,4c00h
               int 21h

MCB_walker endp


set_vec          proc near

                 assume cs:code,ds:code

                 mov    ax,3500h+intvec_1               ;vector swap-age
                 int    21h
                 mov    word ptr [old_vector_1+2],es
                 mov    word ptr [old_vector_1],bx

                 mov    ax,2500h+intvec_1
                 mov    dx,offset patch_1
                 push   cs
                 pop    ds
                 int    21h

                 
set_vec    endp

set_ID           proc near

                 mov  ax,cs             ;Put CS in ax (duh...)
                 dec  ax                ;Dec 1 (location of MCB)
                 mov  es,ax             ;put that to ES so that we can->
                 mov  es:[5],0ffffh     ;put ID marker in unused word in MCB
                 ret

set_ID           endp

chain_check      proc near

                 or   dx,0FFFFh                  ; DX is pass/fail flag
                 push es                         ; Save TSR ES

                 mov  ax,3500h+intvec_1          ; Get vector
                 int  21h
                 mov  ax, es
                 pop  es
                 mov  bx, es
                 cmp  ax, bx                     ; Does VECTOR match SEG?
                 jne  fail_chain                 ; NO!  Chained over!!!
                 xor  dx, dx                     ; Yes, go ahead and remove
fail_chain:
                 ret

chain_check      endp

trash_tsr        proc near

                 mov  dx,offset s_r_msg
                 call mess
                 jmp  terminate

trash_tsr        endp


loader           proc near

                 call   MCB_walker      ;is the TSR loaded already?
                 and    cx, cx
                 jnz    install         ;Nope, menu display...
                 jmp    remove          ;Its there already!  (kill)

install:
                 call   set_ID                  ;Make fix to MCB for ID
                                                ;4 now, generic text screen
                 mov    dx,offset copy_right    ;Fix this last to look kewl
                 call   mess                    ;Display message (cheap-o)

                 call   set_vec                 ;Set up interrupt ptrs...
                 
                 tsr_size  equ   ((end_resident-start)/16)+17 ;inefficient

                 mov    ax,31ffh                ;TSR and take off...
                 mov    dx,tsr_size
                 int    21h

                 mov    dx, offset u_error      ;unexpected error!
                 jmp    fatal_error

remove:
                 
                 mov    dx,offset i_msg
                 call   mess
                 call   chain_check
                 and    dx, dx
                 jne    fail_remove
                 jmp    trash_tsr
fail_remove:
                 mov    dx,offset f_r_msg

fatal_error:
                 call   mess
                 jmp    terminate

loader           endp

   ; ALL error messages FIRST & THEN the funky-text...

   ; Error messages and stuff...(FOR MCB_WALKER)

   fatal_mess db 'BREAK IN MCB CHAIN - SYSTEM WILL CRASH!',10,13,'$'

   f_r_msg      db  'UNSUCCESSFUL!  (TSR has been chained over!)',10,13,'$'
   s_r_msg      db  'SUCCESSFUL! (TSR has been totally removed!)',10,13,'$'
   i_msg        db  'This patch has already been installed!',10,13
   i_msg_2      db  'Removal has been $'
   u_error      db  'UNEXPECTED ERROR!  (Something is REALLY spammed!)',10,13
   xu1          db  '$'

   copy_right   db  'Generic TSR-Shell v1.50 (c) 1991 GHT - '
   xcr2         db  'PATCH for MODEM WARZ',10,13
   xcr3         db  'Support BBS: Atlantis (717) 825-5766',10,13,'$'


code           ends
end            start
