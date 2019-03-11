; 4D-Sports Boxing - Patch v1.22
; Completed 12/05/91 around 1:15 am (Par for the course)
; Written by Gen. Half-Track

; Compile notes: MUST be a .COM file, so use these options with TASM/TLINK
; TASM CRACK4DB
; TLINK CRACK4DB /t
; To produce a working CRACK4DB.COM file

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

                SetupFile  db 'SETUP.DAT',00h   ; Name of file w/params
                BootFile   db 'LOAD.EXE',00h    ; Name of startup file

                BytesRead  dw 0000h     ; Holds bytes read frim SetupFile
                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_Int21  dd 0000h     ; Holds old location of INT 21h (DOS)
                Applied    db 00h       ; Flag if patch was applied in mem

Patch_1         Proc    Near            ; Actual patch - Dirty work!
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     AH,     4Ah     ; Is program re-sizing memory?
                Jne     P1_NoDice       ; Nope, not there yet...

                Cmp     CS:[Applied], 01h ; Has the patch already been set?
                Je      P1_NoDice         ; No...

                Cmp     Word Ptr SS:[5110h], 0000h  ; Is the Stack Aligned?
                Jne     P1_NoDice                   ; Nope, not the right
                                                    ; spot...
                Cmp     Word Ptr SS:[5112h], 0707h
                Jne     P1_NoDice

                Inc     CS:[Applied]                ; Ok, applied, set flag

                Mov     Word Ptr SS:[5110h], 0001h  ; Set PROTECTION PASSED    

P1_NoDice:
                Jmp     CS:Old_Int21    ; Chain to previous vector
Patch_1         Endp


ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES              ; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3521h       ; Get old location of INT 21h (DOS)
                Int     21h

                Push    ES              ; Store it...
                Mov     Word Ptr DS:[Old_Int21], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int21+2], BX

                Mov     AX, 2521h
                Mov     DX, Offset Patch_1      ; Install ours...
                Int     21h

                Pop     ES

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int21+2]  ; Restore old INT 21h
                Push    AX                             ; value to INT table 
                Mov     DX, Word Ptr DS:[Old_Int21]
                Pop     DS
                Mov     AX, 2521h
                Int     21h

                Pop     DS

                Ret
ISR_Remove      Endp


Setup_Param     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    AX
                Push    CS

                Mov     AX, DS:[002Ch]  ; Set ENVIRONMENT pointer
                Mov     Env_Ptr, AX
                
                Pop     AX      
                Mov     Param_Ph, AX    ; Set SEGMENT portion of FAR
                Mov     Fcb_1h,   AX    ; Pointers to Params, & FCB's
                Mov     Fcb_2h,   AX

                Pop     AX

                Ret
Setup_Param     Endp


GetFile         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     AX, 3D00h       ; Open a File handle
                Mov     DX, Offset SetupFile
                Int     21h
                Jc      GF_Error

GF_Ok:
                Push    AX

                Mov     AH, 3Fh ; Success, now read data from it (100h bytes
                Pop     BX      ; Max, but AX will record ACTUAL # read...)
                Mov     CX, 100h
                Mov     DX, Offset FileBuffer
                Int     21H
                Jc      GF_Error

GF_Opened:
                Mov     BytesRead, AX
                Mov     AH, 3Eh         ; Done w/file, close it up...
                Int     21h
                Jc      GF_Error

GF_Done:               
                Xor     AX, AX          ; Set NO ERROR flag for function

GF_Error:
                Ret
GetFile         Endp


ScanFile        Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Cld
                Mov     DI,  Offset FileBuffer  ; Scan for LF in file just
                Mov     AL,  0Ah                ; read in...
                Mov     CX,  BytesRead
                Repne   Scasb
                Or      CX,  CX
                Jz      SF_Error

SF_LF:
                Mov     AL, ' '                 ; Scan for a <SPACE> (1st
                Repne   Scasb                   ; parameter)
                Or      CX, CX
                Jz      SF_Error

SF_Param:
                Dec     DI
                Push    DI
                Mov     AL, 0Dh
                Or      CX, 0FFFFh              ; Get length of parameter
                Repne   Scasb                   ; list
                Not     CX
                Mov     DS:[0080h], CL          ; stuff parameter list
                Dec     Byte Ptr DS:[80h]       ; in PSP so that LOAD.EXE
                Pop     SI                      ; can 'see' it...
                Mov     DI, 0081h
                Rep     Movsb

                Xor     AX, AX                  ; Function PASSED
SF_Error:
                Ret
ScanFile        Endp


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

                Cmp     Byte Ptr DS:[0080h], 00h
                Je      M_ReadFromSetup

                Mov     DX, Offset Command_Msg
                Int     21h

M_ReadFromSetup:

                Xor     AH, AH                
                Int     16h

                Cmp     AL, 1Bh
                Je      M_Bye

                Mov     SP, Offset StackStart  ; MUST create our own stack,
                                               ; Old one will be OVERWRITTEN 
                Call    ISR_Install            ; when LOAD.EXE is RUN!!! 
                                               ; (64 bytes is plenty...)
                Call    Setup_Param

                Cmp     Byte Ptr DS:[0080h], 00h
                Jne     M_ScannedFile
                
                Call    GetFile
                Or      AX, AX
                Jz      M_GotFile

                Mov     DX, Offset NoSetup_Msg
                Jmp     Terminate

M_GotFile:
                Call    ScanFile
                Or      AX, AX
                Jz      M_ScannedFile

                Mov     DX, Offset Error_Msg
                Jmp     Terminate



M_ScannedFile:

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

Error_Msg   db 'Sorry, an error has occured...Aborting...',13,10,'$'
NoSetup_Msg db 'Couldn''t find SETUP.DAT (Run SETUP.EXE to create)',13,10,'$'
NoBoot_Msg  db 'Couldn''t find LOAD.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db '4-D Sports Boxing: Cracked by Gen. Half-Track (Patch v1.07)',13,10
Intro_0     db '(c) 1991 MindScape/Electronic Arts - All Rights Reserved',13,10
Intro_1     db 'This patch is not to be distributed with any other programs,',13,10
Intro_2     db 'Nor is it ment to be used to illegally distribute 4-D BOXING.',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Command_Msg db '***NOTE: Using COMMAND LINE params specified instead of SETUP.DAT info',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

FileBuffer: 

Code_Seg        Ends
End             Start
