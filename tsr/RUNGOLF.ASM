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
                Old_Int21  dd 0000h     ; Holds old location of INT 21h (DOS)
                Done_1     db 0000h


Patch_1         Proc    Near            
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp    AX, 0201h
                Jne    P1_Nope
                Cmp    DX, 0100h
                Jne    P1_Nope
                Cmp    CX, 27F3h
                Jne    P1_Nope

                Mov    AX, 0001
                Iret

P1_Nope:
                Jmp    CS:Old_Int21

Patch_1         Endp


ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES              ; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3513h       ; Get old location of INT 21h (DOS)
                Int     21h

                Push    ES              ; Store it...
                Mov     Word Ptr DS:[Old_Int21], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int21+2], BX

                Mov     AX, 2513h
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
                Mov     AX, 2513h
                Int     21h

                Pop     DS

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
                Xor     DX, DX
                Mov     DL, Byte Ptr DS:[0080h]
                Add     DX, 81h
                Mov     SI, DX
                Mov     Byte Ptr DS:[SI], 0000h
                Mov     DX, 82h
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

                Xor     BX, BX
                Cmp     BH, Byte Ptr DS:[0080h]
                Jne     M_Cont

                Mov     DX, Offset NoFile
                Mov     AH, 09h
                Int     21h
                Jmp     M_Bye

M_Cont:
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
NoBoot_Msg  db 'Couldn''t find start file (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'Hole-In-One: Cracked by Gen. Half-Track (Patch v1.07)',13,10
            db 'USAGE: RUNGOLF ???GOLF.???  - MUST specify extension!',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'
NoFile      db 'You must specify a file to load!',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
