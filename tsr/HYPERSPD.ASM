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

                BootFile   db 'HYPERSPD.EXE',00h    ; Name of startup file

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_Int16  dd 0000h     ; Holds old location of INT 21h (DOS)
                PassOff    dw 0000h                

                Done_1     db 00h


Patch_1         Proc    Near            
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     CS:[Done_1], 02h
                Je      P1_Skip

                Cmp     CS:[Done_1], 01h
                Je      P1_Pro

                Push    BP
                Mov     BP, SP

                Push    AX
                
                Mov     AX, SS:[BP+08]
                Cmp     AX, 00FAh
                Jne     P1_Nope

                Mov     AX, SS:[BP+0Eh]
                Cmp     AX, 0061h
                Jne     P1_Nope

                Inc     CS:[Done_1]
P1_Nope:
                Pop     AX
                
                Mov     SP, BP
                Pop     BP
                
P1_Skip:                
                Jmp     CS:Old_Int16

P1_Pro: 
                Cmp     AH, 01h
                Jne     P1_Check00

                Push    BP
                Mov     BP, SP

                Push    AX
                Mov     AX, SS:[BP+06]
                And     AL, 0BFh
                Mov     SS:[BP+06], AX

                Mov     SP, BP
                Pop     BP
                Iret

P1_Check00:
                Cmp     AH, 00h
                Jne     P1_Skip

                Push    SI

                Mov     SI, CS:[PassOff]
                Mov     AL, DS:[0F6C3h + SI]
                Inc     CS:[PassOff]
                Cmp     Byte Ptr DS:[0F6C4h + SI], 00
                Jne     P1_Check00Ok
                Inc     CS:[Done_1]

P1_Check00Ok:

                Pop     SI
                Iret

Patch_1         Endp


ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES              ; Keep old ES (Gotta keep SEGs)

                Mov     AX, 3516h       ; Get old location of INT 21h (DOS)
                Int     21h

                Push    ES              ; Store it...
                Mov     Word Ptr DS:[Old_Int16], BX
                Pop     BX
                Mov     Word Ptr DS:[Old_Int16+2], BX

                Mov     AX, 2516h
                Mov     DX, Offset Patch_1      ; Install ours...
                Int     21h

                Pop     ES

                Ret
ISR_Install     Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    DS

                Mov     AX, Word Ptr DS:[Old_Int16+2]  ; Restore old INT 21h
                Push    AX                             ; value to INT table 
                Mov     DX, Word Ptr DS:[Old_Int16]
                Pop     DS
                Mov     AX, 2516h
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
NoBoot_Msg  db 'Couldn''t find HYPERSPD.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'HYPERSPEED: Patch by Gen. Half-Track (Patch v1.00)',13,10
            db 'Warning: Illegal duplication of this product punishable by death!',13,10
            db '(In certain provinces & countries...)  But please do not distribute this',13,10
            db 'patch with any other program, and do not alter this message or patch-code',13,10
            db 'Intended for use for registered owners of HYPERSPEED (c) 1991 MicroProse',13,10
            db 'This program is FREEWARE (and copywrited as well) Read HYPER.TXT before using.',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for not illegally using this patch --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
