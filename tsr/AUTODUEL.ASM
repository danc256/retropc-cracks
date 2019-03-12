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

                BootFile   db 'AUTODUEL.EXE',00h    ; Name of startup file

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_Int21  dd 0000h     ; Holds old location of INT 21h (DOS)
                Old_Int13  dd 0000h

                Done_21    db 00h
                Done_13    db 00h

                P1_Vect    EQU 21h
                P2_Vect    EQU 13h

                Sync_Sig   db 23h, 03h, 0C5h, 0Ah, 00h, 08h, 0E7h, 16h

Patch_1         Proc    Near            
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     CS:[Done_21], 01h
                Je      P1_Done

                Cmp     AH, 19h
                Jne     P1_Done
                
                Mov     AL, 02h
                Inc     CS:[Done_21]

                Iret

P1_Done:
                Jmp     CS:Old_Int21    

Patch_1         Endp


Patch_2         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Cmp    CS:[Done_13], 01h
                Je     P2_Nope

                Cmp    AX, 0201h
                Je     P2_Maybe1

                Cmp    AX, 0404h
                Je     P2_Maybe2

                Jmp    P2_Nope
P2_Maybe1:
                
                Cmp    CX, 0601h
                Jne    P2_Nope
                Cmp    DX, 0000h
                Jne    P2_Nope

                Push   CX
                Push   SI
                Push   DI
                Push   ES
                Push   DS

                Mov    CX, 0004h
                Push   CS
                Pop    DS
                Push   BX
                Add    BX, 0100h
                Push   BX
                Pop    DI
                Pop    BX
                Mov    SI, Offset Sync_Sig
                Cld
                Rep    MovSw

                Pop    DS
                Pop    ES
                Pop    DI
                Pop    SI
                Pop    CX

                Inc    CS:[Done_13]
                Jmp    P2_Evil

P2_Maybe2:
                Cmp    Ch, 06h
                Jne    P2_Nope

                Or     DX, DX
                Jne    P2_Nope

P2_Evil:
                Xor      AH, AH
                Iret

P2_Nope:
                Jmp    CS:Old_Int13

Patch_2         Endp


ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES       

                Mov     AX, 3500h + P1_Vect
                Int     21h

                Mov     Word Ptr [Old_Int21], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_Int21+2], BX

                Mov     AX, 2500h + P1_Vect
                Mov     DX, Offset Patch_1      ; Install ours...
                Int     21h

                Mov     AX, 3500h + P2_Vect
                Int     21h

                Mov     Word Ptr [Old_Int13], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_Int13+2], BX

                Mov     AX, 2500h + P2_Vect
                Mov     DX, Offset Patch_2
                Int     21h
                
                Pop     ES

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int21+2]  ; Restore old INT 21h
                Mov     DX, Word Ptr DS:[Old_Int21]
                Mov     DS, AX
                Mov     AX, 2500h + P1_Vect
                Int     21h

                Pop     DS
                Push    DS

                Mov     AX, Word Ptr [Old_Int13+2]
                Mov     DX, Word PTr [Old_Int13]
                Mov     DS, AX
                Mov     AX, 2500h + P2_Vect
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
NoBoot_Msg  db 'Couldn''t find AUTODUEL.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'AUTODUEL-> Patch by Gen. Half-Track (Patch v1.02 - Works off Floppys & HD)',13,10
Intro_1     db 'This program not to be distributed with any other programs',13,10
Intro_2     db 'or used to illegally play AUTODUEL (CopyRight ORIGIN SYSTEMS)',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
