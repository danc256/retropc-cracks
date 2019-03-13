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

                BootFile   db 'START.EXE',00h    ; Name of startup file

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_Int21  dd 0000h     ; Holds old location of INT 21h (DOS)
                Old_Int19  dd 0000h     ; Holds 2nd 'special' vector

                P1_Vec     EQU  21h
                P2_Vec     EQU  19h

Patch_1         Proc    Near            
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp    AH, 3Fh
                Jne    P1_Nope
                Cmp    BX, 0005h
                Jne    P1_Nope
                Cmp    CX, 2102h
                Jne    P1_Nope

                Push   BP
                Push   BX
                Push   ES

                Mov    BP, SP
                Mov    BX, 67C5h                    ;Calculate Offset

                Mov    ES, SS:[BP+012Ah]            ;Calculate Segment
                Cmp    ES: Word Ptr [BX],0C32Bh
                Jne    P1_Not_Rite

                Mov    ES: Word Ptr [BX], 019CDh   ;Small patch...
P1_Not_Rite:

                Pop    ES
                Pop    BX
                Pop    BP

P1_Nope:
                Jmp    CS:Old_INT21
Patch_1         Endp


Patch_2         Proc Near
                Assume CS: Code_Seg, DS: Code_Seg

                Push   ES
                Push   BP
                Push   BX

                Mov    BP, SP
                Mov    ES, SS:[BP+08h]
                Mov    BX, SS:[BP+06h]
                Dec    BX
                Dec    BX
                Cmp    ES:[BX], 019CDh
                Jne    P2_No_Dice

                Mov    ES:[BX], 0C32Bh

                Pop    BX
                Pop    BP
                Pop    ES
P2_No_Dice:
                Xor    AX, AX
                Iret
Patch_2         Endp
                

ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES                  ; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3500h + P1_Vec  ; Get old location of INT 21h
                Int     21h

                Push    ES                  ; Store it...
                Mov     Word Ptr DS:[Old_Int21], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int21 + 2], BX

                Mov     AX, 2500h + P1_Vec
                Mov     DX, Offset Patch_1      ; Install ours...
                Int     21h


                Mov     AX, 3500h + P2_Vec
                Int     21h

                Push    ES
                Mov     Word Ptr DS:[Old_Int19], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int19 + 2], BX

                Mov     AX, 2500h + P2_Vec
                Mov     DX, Offset Patch_2
                Int     21h

                Pop     ES

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int21 + 2]  ; Restore old INT 21h
                Push    AX                               ; value to INT table 
                Mov     DX, Word Ptr DS:[Old_Int21]
                Pop     DS
                Mov     AX, 2500h + P1_Vec
                Int     21h

                Mov     AX, Word Ptr DS:[Old_Int19 + 2]
                Push    AX
                Mov     DX, Word Ptr DS:[Old_Int19]
                Pop     DS
                Mov     AX, 2500h + P2_Vec
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
NoBoot_Msg  db 'Couldn''t find START.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'Eye of the Beholder: Patch by Gen. Half-Track (Patch v1.08)',13,10
            db 'Please do not distribute this program with any other program',13,10
            db 'Not intended or to be used in illegal use of any program',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
