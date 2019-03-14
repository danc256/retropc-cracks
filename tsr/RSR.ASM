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
  Call CS:Old_Int&Vector
ENDM

                CR         EQU 13, 10      ; Carriage Return, Line Feed
                CRE        EQU 13, 10, '$' ; CR, LF + EOLN Symbol ('$')
                
                PATCH_REV  EQU '1.00'          ; Version for patch
                BOOT_ME    EQU 'REDSTORM.COM'  ; Startup file patch runs


                IVect_1    EQU 13h         ; Vector's interrupt #
                IVect_2    EQU 21h

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
                
                Done_13    db 00h       ; Semaphore when patch is done
                Done_21    db 00h 

                Old %IVect_1            ; Holds value of old INT Vector
                Old %IVect_2
                

PHead %IVect_1
                
                Cmp     CS:[Done_13], 00h ; Already passed the disk check?
                Jne     P1_Skip           ; Yeah, why bother w/rest of checks
                
P1_Protection:
                Cmp     DI, 0005h         ; Buncha things to check, just to
                Jne     P1_Skip           ; make SURE that the call we're
                                          ; modifying is the call to the
                Cmp     SI, 0003h         ; disk check (actually, this is the
                Ja      P1_Skip           ; check to make sure there's a disk
                                          ; in the drive.  We want this thing
                Cmp     AX, 0201h         ; stopped before the floppies are
                Jne     P1_Skip           ; even accessed, to make this real
                                          ; clean...)
                Cmp     BX, 0000h
                Jne     P1_Skip

                Cmp     CX, 0001h
                Jne     P1_Skip

                
                Push    BP                ; START PATCH ROUTINE
                Mov     BP, SP

                Inc     CS:[Done_13]             

                Push    BX                       
                                                 ; This is the protection
                Mov     BX, SS:[BP+02h]          ; Get return addr. of INT
                Cmp     Word Ptr DS:[BX], 0C73h  ; from the stack, and modify
                Jne     P1_NoPatch               ; the code that the routine
                                                 ; will return to, to be an
                Mov     Word Ptr DS:[BX], 1BEBh  ; unconditional jump past 
                Xor     AX, AX                   ; the protection!
P1_NoPatch:                                                 
                                                 ; AX = 0 means the protection
                Pop     BX                       ; call was successful. 
                
                Mov     SP, BP
                Pop     BP

                Iret
                                                 ; Bail right here, original
                                                 ; INT 13h call never made
P1_Skip:
                MJump %IVect_1

PTail %IVect_1


PHead %IVect_2
                Cmp     CS:[Done_21], 00  ; DOC check - Was it done yet?
                Jne     P2_Skip           ; Yeah, skip the rest of the checks

                Cmp     AX, 4B00h
                Jne     P2_Skip

                Cmp     BX, 0732h
                Jne     P2_Skip

                Cmp     DX, 0719h
                Jne     P2_Skip

                Pushf
                MCall   %IVect_2  ; Call DOS - this loads the overlay w/the
                                  ; doc check we seek to remove...
                Push    DS
                Push    AX

                Mov     AX, DS:[06D2h]  ; Get Ptr to Segment
                Mov     DS, AX

                Mov     AX, DS:[0024h]  ; Get Ptr to start of program
                Mov     DS, AX

                Mov     Byte Ptr DS:[019Ch], 00  ; Nuke protection jump offset

                Pop     AX      ; Via 2 levels of indirection, we trash the
                Pop     DS      ; conditional jump that determines if the
                                ; doc check was successful or not
                Push    BP
                Mov     BP, SP

                Push    AX

                Pushf
                Inc     CS:[Done_21]
                Pop     AX

                Mov     [BP+06h], AX

                Pop     AX

                Mov     SP, BP
                Pop     BP

                Iret
                
P2_Skip:                
                MJump   %IVect_2

PTail %IVect_2

ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                SetIntVec %IVect_1
                SetIntVec %IVect_2

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                RestIntVec %IVect_1
                RestIntVec %IVect_2

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

EndOfCode       EQU $

Intro_Msg   db 'Generic TSR Shell v1.52 (c) 1990-1993 Gen. Half-Track, Ltd.',CR
            db 'Patch v',PATCH_REV,', compiled ',??time,' on ',??date,' patching file ',BOOT_ME,CR
            db 'This patch is NOT to be used in a manner that would violate the rights of',CR
            db 'the owner of any commercial software!  This patch is PD, distributed AS IS',CR
            db 'Patch for RED STORM RISING - (c) 1989 Microprose Software',CR 
            db '(Yeah its old, patched by request...)',CR
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
