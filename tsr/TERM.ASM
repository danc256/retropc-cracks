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
                
                PATCH_REV  EQU '1.10'      ; Version for patch
                BOOT_ME    EQU 'TERM.EXE'  ; Startup file patch runs


                IVect_1    EQU 10h         ; Vector's interrupt #

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
                Cheat      db 00h       ; Set if CHEATING is on

                Old %IVect_1
                

PHead %IVect_1
                Cmp     CS:[Done_1], 00
                Je      P1_OK1
                Jmp     P1_Skip
P1_OK1:
                Cmp     AX, 0013h
                Je      P1_OK2
                Jmp     P1_Skip
P1_OK2:

                Inc     CS:[Done_1]

                Push    BP
                Mov     BP, SP

                Push    AX
                Push    DS
                Pushf
                                 
                Mov     AX, [BP+04]  ; Get CS from stack
                Mov     DS, AX
                Mov     Byte Ptr DS:[15FFh], 0EBh  ; Unconditional Jump

                Cmp     CS:[Cheat], 01
                Je      P1_CHEATOK
                Jmp     P1_No_Cheat
P1_CHEATOK:

                Mov     Word Ptr DS:[8804h], 9090h ; No DEC weapon count
                Mov     Word Ptr DS:[8806h], 9090h

                Mov     Word Ptr DS:[8881h], 9090h ; No INC weapon count
                Mov     Word Ptr DS:[8883h], 9090h 

                Mov     Word Ptr DS:[8456h], 9090h ; No GUN recharge time
                Mov     Word Ptr DS:[8458h], 9090h

                Mov     Word Ptr DS:[796Bh], 9090h ; No HEALTH loss
                Mov     Word Ptr DS:[796Dh], 9090h

                Mov     Word Ptr DS:[79DAh], 9090h ; No HEALH loss
                Mov     Word Ptr DS:[79DCh], 9090h

                Mov     Word Ptr DS:[7870h], 9090h ; No HEAD shots
                Mov     Word Ptr DS:[7872h], 9090h

                Mov     Word Ptr DS:[7963h], 9090h ; No ARMOR damage
                Mov     Word Ptr DS:[7965h], 9090h

                Mov     Word Ptr DS:[79D2h], 9090h
                Mov     Word Ptr DS:[79D4h], 9090h
                
                Mov     Word Ptr DS:[81D8h], 9090h
                Mov     Word Ptr DS:[81DAh], 9090h

                Mov     Word Ptr DS:[7EF2h], 9090h
                Mov     Word Ptr DS:[7EF4h], 9090h

                Mov     Word Ptr DS:[8881h], 9090h
                Mov     Word Ptr DS:[8883h], 9090h

                Mov     Word Ptr DS:[7957h], 9090h
                Mov     Word Ptr DS:[7959h], 9090h

P1_No_Cheat:

                Popf
                Pop     DS
                Pop     AX

                Mov     SP, BP
                Pop     BP

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

                Mov     DX, Offset Cheat_Msg
                Mov     AH, 09h
                Int     21h

                Xor     AH, AH
                Int     16h

                Cmp     AL, 'Y'
                Je      Cheat_OK

                Cmp     AL, 'y'
                Jne     Cheat_No
Cheat_OK:
                Mov     CS:[Cheat], 01
Cheat_No:

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
            db 'Patch for TERMINATOR 2029 - Copy this file into TERMINATOR Dir',CR
            db 'and continue to use the 2029.BAT batch file to play game...',CR
            db 'Thanx 2: P. F. Talons & The Boozer...',CR
            db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',CRE
Cheat_msg   db 10,13,'Cheat like hell? (Y/N): $'

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

; Patch LOC's -> All referenced off CS, and all patches take 4 NOP's:
;
; 7870             - No head shots
; 7963, 79D2       - No armor damage
; 79DA, 796B       - No damage to health
; 7957             - Weapons take no damamge
; 8456             - Plasma guns never cool
; 81D8, 7EF2, 8881 - Unlimited Grenades/Rockets 
