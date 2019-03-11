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
                IVect_2    EQU 65h

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
                Old %IVect_2

                BootFile   db 'MONKEY2.EXE',00h ; Name of startup file
                Done       db 00


PHead %IVect_1
                Cmp     CS:[Done], 01
                Je      P1_Skip

                Cmp     AH, 30h
                Jne     P1_Skip

                Push    DS
                Push    AX

                Mov     AX, CS:[Env_Ptr]
                Mov     DS:[002Ch], AX

                Mov     AX, DS
                Add     AX, 0010h

                Mov     DS, AX

                Mov     Word Ptr DS:[6D48h], 65CDh  ; Replace Cmp AX, SI w/
                Inc     CS:[Done]                   ; INT 65h
                
                Pop     AX
                Pop     DS
P1_Skip:
                MJump %IVect_1
PTail %IVect_1

PHead %IVect_2
                Push    BP
                Mov     BP, SP          ; Set up Stack

                Cmp     Word Ptr DS:[7550h], 0000
                Je      P2_Skip

                Cmp     AX, DS:[68B6h]  ; Password?
                Jne     P2_Skip         ; Nah, do old compare

                Cmp     SI, DS:[7550h]  ; Password?
                Jne     P2_Skip         ; Nah, do old compare


                Push    AX              ; HA!  PASSWORD!  (Screw it)
                Mov     AX, [BP+06h]    ; Get Stack flags

                Or      AL, 01000000b   ; Set flags to PASS!!! (ZF=1)

                Mov     [BP+06h], AX    ; Restore flags
                Pop     AX
                                        
                Push    DS              ; REMOVE INT 65h (Tidy up)
                Push    AX

                Mov     AX, DS
                Sub     AX, 17F4h       ; Adjust DS to find CS!
                Mov     DS, AX

                Mov     Word Ptr DS:[6D48h], 0C63Bh      ; Cmp  AX, SI

                Pop     AX
                Pop     DS
                Jmp     P2_Exit         ; Done w/o a trace...

P2_Skip:
                Cmp     AX, SI          ; ORIGINAL COMPARE
                Push    AX              ; Get Stack flags
                Mov     AX, [BP+06h]    ; Get Stack flags
                Je      P2_Set          ; They match, set flags

                And     AL, 10111111b   ; They DON'T match, clear
                Jmp     P2_Done
P2_Set:
                Or      AL, 01000000b   ; Set flags to PASS            
P2_Done:
                Mov     [BP+06h], AX
                Pop     AX

P2_Exit:
                Mov     SP, BP
                Pop     BP

                Iret
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

                Mov     AX, CS:[002Ch]
                Mov     DS:[Env_Ptr], AX

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
NoBoot_Msg  db 'Couldn''t find the startup file!',CRE
Intro_Msg   db 'Generic TSR Shell (c) 1990, 1992 GHT, Ltd.',CR
            db 'Patch for Monkey Island II (c) 1991 LucasFilm',CR
            db 'Enter any code when the screen appears... --Gen. Half-Track',CR
            db 'PS - This patch MUST be called MONKEY2.COM or it''ll screw up!',CR
            db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',CRE
Bye_Msg     db 'Thank you for not illegally using this program! --GHT',CRE

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
