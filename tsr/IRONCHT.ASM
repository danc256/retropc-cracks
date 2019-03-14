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

                BootFile   db 'GAME.EXE',00h    ; Name of startup file

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Old_IntP1  dd 0000h     ; Holds old location of INT 21h (DOS)

                KB_Int     dd 0000h
                Done       db 00h
                DataSegmt  dw 0000h

                PlayerTable dw 4C69h, 4C69h+0Fh, 4D2Bh, 4D2Bh+0Fh, 4DEDh, 4DEDh+0Fh

                Patch1_Vec EQU 21h

Patch_1         Proc    Near            ; Actual patch - Dirty work!
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     AX, 2509h
                Jne     P1_Nope

                Cmp     CS:Done, 00
                Jne     P1_Nope

                Inc     CS:Done

                Push    BP
                Mov     BP, SP

                Push    AX
                Push    DS
                Push    DX

                Mov     AX, SS:[BP+08]
                Mov     CS:[DataSegmt], AX

                Pop     AX
                Mov     Word Ptr CS:[KB_Int], AX
                Pop     AX
                Mov     Word Ptr CS:[KB_Int+2], AX

                Push    CS
                Pop     DS
                Mov     DX, Offset KB_Handler
                Pop     AX

                Mov     SP, BP
                Pop     BP

P1_Nope:               
                
                Jmp     CS:Old_IntP1

Patch_1         Endp

KB_Handler      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    AX
                In      AL, 60h

                Cmp     AL, 0Ah                
                Ja      KB_Nope

                Cmp     AL, 05h
                Jb      Kb_Nope

                Xor     AH, AH
                Sub     AL, 05h
                Shl     AX, 01h

                Push    DS
                Push    BX
                Push    AX
                Mov     AX, CS:DataSegmt
                Mov     DS, AX
                Pop     AX

                Xor     BX, BX
                Mov     BL, AL

                Mov     AX, CS:[Offset PlayerTable + BX]
                Push    AX

                Shr     BX, 1
                And     BX, 1
                Pop     BX
                
                Je      KB_Credits

                Mov     Byte Ptr DS:[BX], 80h
                Jmp     KB_Done

KB_Credits:
                Mov     Byte Ptr DS:[BX], 08h
                
KB_Done:               
                Pop     BX
                Pop     DS

KB_Nope:
                
                Pop     AX
                Jmp     CS:KB_Int

KB_Handler      Endp

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
NoBoot_Msg  db 'Couldn''t find GAME.EXE (Must be in same Directory)',13,10,'$'
Intro_Msg   db 'IRONMAN: Cheat by Gen. Half-Track',13,10
Intro_1     db '4-5 = Player 1, 6-7 = Player 2, 8-9 = Player 3',13,10
Intro_2     db '4,6,8 = Credits set to 8  And  5,7,9 = Cash set to 80M',13,10
Intro_3     db '<<<PRESS ANY KEY TO CONTINUE>>> - Or press ESC to Quit',13,10,'$'
Bye_Msg     db 'Thank you for using this cheat --GHT',13,10,'$'

NewStack   dw 32 Dup(00)
StackStart EQU $-2

EndOfCode       EQU $

Code_Seg        Ends
End             Start
