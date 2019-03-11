Code_Seg        Segment
                Assume CS: Code_Seg, DS: Code_Seg
                
                Start_Of_File EQU $  ; Used to calculate file size
                                     ; for shrinking MEM blocks
                ORG     100h

Start:
                JMP     Loader
                                       ; Parameter Block for Child Proc
                ENV_BLOCK dw 0000    
                COM_TAIL  dw 80h
                COM_SEG   dw 00
                FCB_1     dw 5Ch
                FCB_1SEG  dw 00
                FCB_2     dw 6Ch
                FCB_2SEG  dw 00

                FILENAME  db 'TANK.COM',00  ; Filename (duh)
                
                OLD_SP    dw ?  ; Store old Stack Ptr for recovery from 4Bh
                Old_Int13 dd ?  ; Store old Handler
                Old_Int21 dd ?

                Int_P1    EQU 13h
                Int_P2    EQU 21h

                Done_13   db 00

Patch_1         Proc    Near
                Assume CS: Code_Seg, DS: Code_Seg

                Pushf
                Cmp     CS:[Done_13], 01h
                Jne     P1_Protection
                Jmp     P1_Skip

P1_Protection:
                Push    BP
                Mov     BP, SP

                Cmp     DI, 0005h
                Jne     P1_PSkip

                Cmp     SI, 0003h
                Ja      P1_PSkip

                Cmp     AX, 0201h
                Jne     P1_PSkip

                Cmp     BX, 0000h
                Jne     P1_PSkip

                Cmp     CX, 0001h
                Jne     P1_PSkip

                Push    BX
                Mov     BX, SS:[BP+0Ah]
                Cmp     Word Ptr DS:[BX], 0C73h
                Jne     P1_NoPatch
                Mov     Word Ptr DS:[BX], 0FEBh
                
                Inc     CS:[Done_13]
                Xor     AX, AX
                Pop     BX
                Jmp     P1_Done


P1_NoPatch:               
                Pop     BX
                Jmp     P1_PSkip

P1_Done:
                Mov     SP, BP
                Pop     BP
                Popf
                Iret

P1_PSkip:
                Mov     SP, BP
                Pop     BP

P1_Skip:
                Popf
                Jmp     CS:[Old_Int13]

Patch_1         Endp

Patch_2         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     AH, 48h
                Jne     P2_Skip

                Push    BP
                Mov     BP, SP

                Cmp     Word Ptr SS:[BP+02h], 0B01Ch
                
                Mov     SP, BP
                Pop     BP
                
                Jne     P2_Skip

                Mov     Byte Ptr SS:[0A3EAh], 00h

P2_Skip:
                Jmp     CS:[Old_Int21]

Patch_2         Endp



SET_ISR         Proc    Near
                Assume CS: Code_Seg, DS: Code_Seg

                PUSH    ES                
                Push    DS

                MOV     AX, 3500h + Int_P1       ; Get Addr of Old Handler
                INT     21h

                MOV     Word Ptr CS:[OLD_INT13], BX     ; Store it
                MOV     BX, ES
                MOV     Word Ptr CS:[Old_INT13+2], BX

                MOV     AX, 2500h + Int_P1
                MOV     DX, Offset Patch_1        ; Set up NEW handler
                INT     21h

                Pop     DS
                Push    DS

                Mov     AX, 3500h + Int_P2
                Int     21h

                Mov     Word Ptr CS:[Old_Int21], BX
                Mov     BX, ES
                Mov     Word Ptr CS:[Old_Int21+2], BX

                Mov     AX, 2500h + Int_P2
                Mov     DX, Offset Patch_2
                Int     21h

                Pop     DS
                Pop     ES

                Ret

SET_ISR         Endp

DONE_ISR        Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                MOV     AX, 2500h + Int_P1       ; Restore Old handler
                MOV     DX, Word Ptr CS:[OLD_INT13]
                MOV     BX, Word Ptr CS:[OLD_INT13+2]
                PUSH    BX
                POP     DS
                INT     21h
                
                Mov     AX, 2500h + Int_P2
                Mov     DX, Word Ptr CS:[Old_Int21]
                Mov     BX, Word Ptr CS:[Old_Int21+2]
                Push    BX
                Pop     DS
                Int     21h

                RET
DONE_ISR        Endp


Main            Proc    Near
                Assume CS: Code_Seg, DS: Code_Seg
Loader:
                
                MOV     DX,     Offset  Intro_Msg
                MOV     AH,     09h
                INT     21h          ; Crack'd Msg - IE Bullshit message!

                MOV     AH, 00h
                INT     16h             ; Slam-a-key

                CMP     AL, 1Bh         ; ESC?
                JE      ESC_KEY         ; Yep, Quit...

                MOV     SP, Offset StartOfStack ; MUST have own stack, because 
                                                ; it gets OVERWRITTEN!

                MOV     BX,     (Offset End_Of_File - Start_Of_File + 15) shr 4

                MOV     AH, 4Ah    ; Shrink MEM alloc so that IMMORTAL.EXE
                INT     21h        ; Has room 2 load!
                JC      LOAD_ERROR ; Oops, oh well....

                CALL    SET_ISR ; Set up ISR (Interrupt Service Routine)

                MOV     AX, CS:[002Ch] ; Pass SEG of Environment 2 child
                MOV     ENV_BLOCK, AX
                
                PUSH    CS
                POP     AX
                
                MOV     COM_SEG,    AX  ; SEG of COMMAND LINE 2 child
                MOV     FCB_1SEG,   AX  ; SEG of File CONTROL BLOCKS 2 child
                MOV     FCB_2SEG,   AX  ; FCB #2

                MOV     CS:OLD_SP, SP   ; Store old SP 

                MOV     BX, Offset ENV_BLOCK ; Where 2 find Parameters
                MOV     DX, Offset FILENAME  ; Where 2 find file 2 exec   

                MOV     AX, 4B00h            ; RUN IMMORTAL.EXE
                INT     21h

                MOV     CX, CS               ; Restore all old registers
                MOV     SS, CX               ; (Whatta mess!!!)   
                MOV     SP, CS:OLD_SP
                MOV     DS, CX
                MOV     ES, CX

                JNC     SUCCESS              ; Print Bullshit MSG #2   
                
                CMP     AX, 02h
                JE      FILE_NOT_FOUND       ; oops, no IMMORTAL.EXE!   
LOAD_ERROR:
                MOV     DX, Offset Error_Msg
                MOV     AH, 09h
                INT     21h
                JMP     TERMINATE

FILE_NOT_FOUND:
                MOV     DX, Offset No_File_Msg
                MOV     AH, 09h
                INT     21h
                JMP     TERMINATE

SUCCESS:                
                MOV     DX, Offset Success_Msg
                MOV     AH, 09h
                INT     21h

TERMINATE:             
                PUSH    CS              ; Clean up shop & restore old
                POP     DS              ; ISR routine                                
                CALL    DONE_ISR
                
ESC_KEY:
                MOV     AH, 4Ch         ; Quit 2 DOS (Bye!)
                INT     21h

Main            Endp

Intro_Msg   db 'M1 Tank Platoon - (c) 1989 MicroProse Software :: Patch by Gen. Half-Track',10,13
Intro_0     db 'Patch v1.10 - Fixes PASSWORD FOOBAR - Won''t pop up anymore...ever',10,13
Intro_00    db 'With undying thanks to the vast technical expertise of Th''mas',10,13
Intro_1     db 'This is a quality game of superior detail, many hours went into',10,13
Intro_2     db 'its design (and this patch!)  Please do not illegally duplicate software!',10,13
Intro_2x    db '**NOTE: This patch supports the command line param that TANK.COM does!',10,13
Intro_2xx   db 'Simply substitute ANTITANK where TANK would appear in any .BAT files',10,13
Intro_3     db '<<<PRESS ANY KEY TO START>>> - or ESC to QUIT',10,13,'$'
Success_Msg db 10,13,'Thank you for not illegally using this patch --GHT',10,13,'$'
Error_Msg   db 'Sorry, an error has occured...',10,13,'$'
No_File_Msg db 'The startup file TANK.COM was not found...',10,13,'$'

NewStack    dw 32 Dup(00)
StartOfStack  EQU $-2

End_Of_File     EQU $  ; Needed in calculation for MEM re-size...
Code_Seg        Ends
End             Start
