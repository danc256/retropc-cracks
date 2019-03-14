; Generic Spawner shell, v1.50, (C) 1990-1993 GHT, Ltd.  All Rights Reserved

; General purpose shell for writting .COM files that modify the IBM
; environment then execute another program under that environment.  
; Removes all modifications (Patches + Memory allocated) upon termination of
; spawned program automatically.  Useful for games cheats and such.

; So long as my name is still DISPLAYED upon execution, in a similar manner
; as the author of modifications to this program, it may be modified freely.
; Oh yeah, this is FREEWARE.  See DOCS at end of file.

; Compiled with Turbo Assembler v3.00, (c) Borland International 
; (Source compatible with most other popular assemblers I.E. MASM)

; *** MACROS ***

SetIntVec MACRO Vector
                Push    ES                    ;; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3500h + &Vector   ;; Get old location 
                Int     21h

                Push    ES                    ;; Store it on the stack
                Mov     Word Ptr DS:[Old_Int&Vector], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int&Vector+2], BX

                Mov     AX, 2500h + &Vector
                Mov     DX, Offset Handler_&Vector ;; Install new vector
                Int     21h

                Pop     ES                       ;; Restore old ES
ENDM

RestIntVec MACRO Vector
                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int&Vector+2]  
                Push    AX                              
                Mov     DX, Word Ptr DS:[Old_Int&Vector]
                Pop     DS
                Mov     AX, 2500h + &Vector
                Int     21h

                Pop     DS
ENDM

PHead MACRO ProcLabel
  Handler_&ProcLabel  Proc    Near            
  Assume  CS: Code_Seg, DS: Code_Seg
ENDM

PTail MACRO ProcLabel
  Handler_&ProcLabel Endp
ENDM

Old MACRO Vector
  Old_Int&Vector dd 0000h
ENDM

MJump MACRO Vector
  Jmp CS:Old_Int&Vector
ENDM

MCall MACRO Vector
  Pushf
  Call CS:Old_Int&Vector
ENDM

                CR         EQU 13, 10      ; Carriage Return, Line Feed
                CRE        EQU 13, 10, '$' ; CR, LF + EOLN Symbol ('$')
                
                PATCH_REV  EQU '1.00'      ; Version for patch
                BOOT_ME    EQU 'PROTO.EXE'  ; Startup file patch runs


                IVect_1    EQU 16h         ; Vector's interrupt #

Code_Seg        Segment
                Assume CS: Code_Seg, DS: Code_Seg

StartOfCode     EQU     $
                Org     100h
Start:
                Jmp        Loader       ; Go to start of program
                
                BootFile   db BOOT_ME,00h ; Name of startup file

                Env_Ptr    dw 0000      ; Table needed to spawn child
                Param_Pl   dw 0080h     ; process (Contains pointer to
                Param_Ph   dw 0000h     ; parent's environment, pointer
                Fcb_1l     dw 005Ch     ; to command line parameter list,
                Fcb_1h     dw 0000h     ; and pointers to File Control
                Fcb_2l     dw 006Ch     ; blocks #1 & #2...
                Fcb_2h     dw 0000h

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Ret_Addr   dw 0000h     ; Holds return address from Spawn
                
                Done_1     db 00h       ; Semaphore when patch is done
                Active     db 00h

                LetterPtr  dw 0000h     ; Start of word in Data Segment

                Old %IVect_1
                

PHead %IVect_1
                Cmp     CS:[Done_1], 00  ; Already did it?
                Jne     P1_Skip          ; Yeah, screw it

                Cmp     CS:[Active], 01  ; Is the patch intercepting keys?
                Je      P1_Intercept     ; Yep, rack off the next one

                Push    AX  

                Mov     AH, 01h          ; Scan the keyboard
                MCall   %IVect_1

                Cmp     AX, 372Ah        ; Is it the grey '*'
                Jne     P1_NoActive      ; Fuck no, we won't go...

                Inc     CS:[Active]      ; Yeah, give 'em hell...

                Mov     AX, DS:[72BEh]   ; Location of segment withing STACK
                Add     AX, 000Ah        ; containing offset of password
                Mov     CS:[LetterPtr], AX  ; Add 0x0A for Password being
                                            ; looked for (0x00 is buffer)

                Xor     AX, AX
                MCall   %IVect_1         ; Eat grey plus key from buffer       
P1_NoActive:
                Pop     AX               ; Tidy up

                Jmp     P1_Skip

P1_Intercept:
                Cmp     AH, 00h                 ; Is a keypress requested?
                Jne     P1_CheckCheck           ; Nope

                Push    BX                      ; Yep
                
                Mov     BX, CS:[LetterPtr]      ; Points to current letter
                                                ; in destination word
                Mov     AL, Byte Ptr SS:[BX]    ; Move it in
                Pop     BX
                
                Cmp     AL, 00                  ; End of Word?
                Je      P1_DoneIntercept        ; Yeah, pack it in...

                Inc     CS:[LetterPtr]          ; No, move to next letter and
                Iret                            ; return current one

P1_DoneIntercept:
                Dec     CS:[Active]             ; Tidy up and continue...
                Inc     CS:[Done_1]
                Mov     AL, 0Dh                 ; CR
                Iret

P1_CheckCheck:
                Cmp     AH, 01                  ; Routine that simulates
                Jne     P1_Skip                 ; A key waiting in the
                                                ; buffer, by changing the
                Push    BP                      ; value of the 'Z' flag
                Mov     BP, SP                  ; on the stack

                Push    AX

                Mov     AX, [BP+06]             ; Flags register on stack
                And     AL, 10111111b
                Mov     [BP+06], AX             ; Put back on stack

                Pop     AX

                Mov     SP, BP
                Pop     BP
                Iret

P1_Skip:
                MJump %IVect_1
PTail %IVect_1

ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                SetIntVec %IVect_1

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                RestIntVec %IVect_1

                Ret
ISR_Remove      Endp


Setup_Param     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    AX
                Push    CS
                Pop     AX      
                
                Mov     Param_Ph, AX    ; Set SEGMENT portion of FAR
                Mov     Fcb_1h,   AX    ; Pointers to Params, & FCB's
                Mov     Fcb_2h,   AX

                Pop     AX

                Ret
Setup_Param     Endp


Spawn           Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Pop     Ret_Addr

                Mov     AH,  4Ah  ; Re-size memory to bare minimum
                Mov     BX,  (Offset EndOfCode - StartOfCode + 15) shr 4
                Int     21h

                Mov     AX, 4B00h       ; Prepare to execute LOAD.EXE
                Mov     BX, Offset Env_Ptr
                Mov     DX, Offset BootFile
                Mov     Old_SP, SP                
                Int     21h

                Mov     CX, CS          ; Restore all registers... (EXE
                Mov     DS, CX          ; trashes ALL but CS:IP registers
                Mov     SS, CX          
                Mov     SP, Old_SP
                Mov     ES, CX
                Jc      S_Error

S_OK:
                Xor     AX, AX          ; Set Function PASSED

S_Error:
                Push    Ret_Addr
                Ret
Spawn           Endp


Main            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
Loader:              
                Mov     DX, Offset Intro_Msg    ; Intro Message
                Mov     AH, 09h
                Int     21h

                Xor     AH, AH                
                Int     16h

                Cmp     AL, 1Bh
                Je      M_Bye

                Mov     SP, Offset StackStart

                Call    ISR_Install              
                Call    Setup_Param
                Call    Spawn                
                
                Or      AX, AX
                Jnz     M_CheckSpawnError

                Mov     DX, Offset Bye_Msg
                Jmp     Terminate

M_CheckSpawnError:

                Cmp     AX, 0002
                Jne     M_SpawnError

                Mov     DX, Offset NoBoot_Msg
                Jmp     Terminate

M_SpawnError:
                Mov     DX, Offset Error_Msg

Terminate:              
                Mov     AH, 09h
                Int     21h
                Call    ISR_Remove

M_Bye:
                Mov     AH, 4Ch
                Int     21h

Main            Endp

; All error/status message text bodies...
Error_Msg   db 'Sorry, an error has occured! <Aborting>',CRE
NoBoot_Msg  db 'Couldn''t find the startup file!',CRE
Bye_Msg     db 'Thank you for not illegally using this program! --GHT',CRE

MyStack     db 6 dup('Stack ')
StackStart  EQU $-2

EndOfCode       EQU $

Intro_Msg   db 'Generic TSR Shell v1.50 (c) 1990-1993 Gen. Half-Track, Ltd.',CR
            db 'Patch v',PATCH_REV,', compiled ',??time,' on ',??date,' patching file ',BOOT_ME,CR
            db 'This patch is NOT to be used in a manner that would violate the rights of',CR
            db 'the owner of any commercial software!  This patch is PD, distributed AS IS',CR
            db '-------------------------------------------------------------------------------',CR
            db 'Deprotect for PROTOSTAR by QUARTZ.  It''s my first TSR patch (Thanx GHT)',CR
            db 'so gimmie a break...  This was a little bit brutal (ask GHT, I woke him',CR
            db 'up 3x between midnite & 2am on a school nite), so its not the nicest thing.',CR
            db 'When the protection appears, press the GREY ASTERISK (The ''*'' on the keypad)',CR
            db 'and you will be amazed at how fast you learned to type... QUARTZ - 1993',CR
            db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',CRE

Code_Seg        Ends
End             Start


; Stuff:
; To ADD a new interrupt handler, you must declare the following:
;
; 1) A new IVECT_? label (IE IVect_2 EQU 13h)
; 2) Storage for the OLD vector (IE Old %IVect_2)
; 3) A HANDLER for the new routine (IE PHead %IVect_2 <CODE> PTail %IVect_2)
; 4) An INSTALL routine (IE SetIntVect %IVect_2)
; 5) A REMOVE routine (IE RestIntVect  %IVect_2)
; 6) Code the area between PHEAD and PTAIL with the actual code.  You have
; Macros MJUMP and MCALL to assist in chaining your new handler.  
