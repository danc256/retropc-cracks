; Compile notes: MUST be a .COM file, so use these options with TASM/TLINK
; TASM PATCHGOD
; TLINK PATCHGOD /t
; To produce a working  PATCHGOD.COM file

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

                BIOS_Params   dw 0008
                BIOS_Model    dw 01FCh
                BIOS_Whocares db 6 Dup(0)

                BootFile   db 'GODS.EXE',00h    ; Name of startup file

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_IntP1  dd 0000h     ; Holds old location of INT 21h (DOS)
                Old_Int09  dd 0000h

                DSeg       dw 0000h

                Patch1_Vec EQU 15h

Patch_1         Proc    Near            ; Actual patch - Dirty work!
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     AH, 0C0h
                Jne     P1_NoDice

                Push    AX
                Push    DS
                Pop     AX
                Mov     CS:[DSeg], AX
                Pop     AX
                
                Push    CS
                Pop     ES

                Mov     BX, Offset BIOS_Params
                Iret

P1_NoDice:
                Jmp     CS:Old_IntP1

Patch_1         Endp


Patch_2         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Pushf
                Call    CS:[Old_Int09]

                Push    AX
                Mov     AH, 01h
                Int     16h

                Cmp     AL, '1'
                Jne     P2_Check2
                
                Mov     AX, CS:[DSeg]
                Push    DS
                Mov     DS, AX
                Inc     Byte Ptr DS:[0192h]
                Inc     Byte Ptr DS:[00D2h]
                Pop     DS
                Jmp     P2_Done

P2_Check2:
                Cmp     AL, '2'
                Jne     P2_Done

                Mov     AX, CS:[DSeg]
                Push    DS
                Mov     DS, AX
                Inc     Byte Ptr DS:[01C4h]
                Inc     Byte Ptr DS:[0104h]
                Pop     DS

P2_Done:
                Pop     AX
                Iret

Patch_2         Endp

ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES              ; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3500h + Patch1_Vec   ; Get old location of INT 
                Int     21h

                Push    ES              ; Store it...
                Mov     Word Ptr DS:[Old_IntP1], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_IntP1+2], BX

                Mov     AX, 2500h + Patch1_Vec
                Mov     DX, Offset Patch_1      ; Install ours...
                Int     21h

                Mov     AX, 3509h
                Int     21h

                Mov     Word Ptr DS:[Old_Int09], BX
                Mov     BX, ES
                Mov     Word Ptr DS:[Old_Int09+2], BX

                Mov     AX, 2509h
                Mov     DX, Offset Patch_2
                Int     21h

                Pop     ES

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    DS

                Mov     AX, Word Ptr DS:[Old_IntP1+2]  ; Restore old INT 21h
                Push    AX                             ; value to INT table 
                Mov     DX, Word Ptr DS:[Old_IntP1]
                Pop     DS
                Mov     AX, 2500h + Patch1_Vec
                Int     21h

                Pop     DS
                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int09+2]
                Push    AX
                Mov     DX, Word Ptr DS:[Old_Int09]
                Pop     DS
                Mov     AX, 2509h
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

Error_Msg   db 'Sorry, an error has occured...Aborting...',13,10,'$'
NoBoot_Msg  db 'Couldn''t find GODS.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'GODS (Minor Fix for certain machines): Fix by Gen. Half-Track',13,10
Intro_0     db '(c) BitMap Brothers - All Rights Reserved',13,10
Intro_1     db 'This patch is not to be distributed with any other programs,',13,10
Intro_2     db 'Nor is it ment to be used to illegally distribute GODS',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
