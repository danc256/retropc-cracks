; Generic Spawner shell, v1.22, (C) 1990, 1992 GHT, Ltd.  All Rights Reserved

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


                IVect_1    EQU 21h         ; Vector's interrupt #

Code_Seg        Segment
                Assume CS: Code_Seg, DS: Code_Seg

StartOfCode     EQU     $
                Org     100h
Start:
                Jmp        Loader       ; Go to start of program

                Env_Ptr    dw 0000      ; Table needed to spawn child
                Param_Pl   dw 0080h     ; process (Contains pointer to
                Param_Ph   dw 0000h     ; parent's environment, pointer
                Fcb_1l     dw 005Ch     ; to command line parameter list,
                Fcb_1h     dw 0000h     ; and pointers to File Control
                Fcb_2l     dw 006Ch     ; blocks #1 & #2...
                Fcb_2h     dw 0000h

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                
                Old %IVect_1

                BootFile   db 'WOLF3D.EXE',00h ; Name of startup file

                Done_1  db      00


PHead %IVect_1
                Cmp     CS:[Done_1], 00
                Jne     P1_Skip

                Cmp     AH, 30h
                Jne     P1_Skip

                Push    AX
                Push    DS

                Mov     AX, DS
                Add     AX, 1010h
                Mov     DS, AX
                Mov     Byte Ptr DS:[1DC8h], 0EBh

                Mov     Word Ptr DS:[1F8Dh], 00B8h
                Mov     Byte Ptr DS:[1F8Fh], 00h

                Mov     Word Ptr DS:[2B0Eh], 9090h
                Mov     Word Ptr DS:[2B10h], 9090h
                Inc     CS:[Done_1]
                
                Pop     DS
                Pop     AX

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

                Mov     AH,  4Ah  ; Re-size memory to bare minimum
                Mov     BX,  (Offset EndOfCode - StartOfCode + 15) shr 4
                Int     21h

                Mov     AX, 4B00h       ; Prepare to execute LOAD.EXE
                Mov     BX, Offset Env_Ptr
                Mov     DX, Offset BootFile
                Mov     DS:[Old_SP], SP
                Int     21h

                Mov     CX, CS          ; Restore all registers... (EXE
                Mov     SS, CX          ; trashes ALL but CS:IP registers
                Mov     SP, CS:[Old_SP] ; So we must restore everything
                Mov     DS, CX          ; manually...)
                Mov     ES, CX
                Jc      S_Error

S_OK:
                Xor     AX, AX          ; Set Function PASSED

S_Error:
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

                Mov     SP, Offset StackStart  ; MUST create our own stack,
                                               ; Old one will be OVERWRITTEN 
                Call    ISR_Install            ; when LOAD.EXE is RUN!!! 
                                               ; (64 bytes is plenty...)
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

Error_Msg   db 'Sorry, an error has occured... Aborting...',CRE
NoBoot_Msg  db 'Couldn''t find the startup file! (WOLF3D.EXE)',CRE
Intro_Msg   db 'Generic TSR Shell (c) 1990, 1992 GHT, Ltd.',CR
            db 'Trainer (Unlimited lives + bullets) for CASTLE WOLFENSTEIN v1.1',CR
            db 'Will (in all probability) screw up (not function) for ANY OTHER VERSION!',CR
            db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',CRE
Bye_Msg     db CR, CR, 'Support PD software and register your program! --GHT',CRE

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

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
