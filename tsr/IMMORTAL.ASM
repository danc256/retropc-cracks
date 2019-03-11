; Crack for THE IMMORTAL - By Gen. Half-Track
; V 1.07 of Patch (Modified for Stack handlin')
; V 1.05 of Spawn-Shell System (See 4-D Boxing for v1.22)
; Modified 12/06/91  -  12:18 am (When else?)

; Compile options - .COM file MUST be generated...
; TASM IMMORTAL
; TLINK IMMORTAL /t
; That'll do...

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

                FILENAME  db 'IMMORTAL.EXE',00  ; Filename (duh)
                
                OLD_SP    dw ?  ; Store old Stack Ptr for recovery from 4Bh
                OLD_INT16 dd ?  ; Store old KeyBoard Handler
                TRIES     db 00 ; # of protection questions defeated so far

PATCH           Proc    Near
                Assume CS: Code_Seg, DS: Code_Seg

                OR      AH, AH   ; Read a Keypress?
                JNZ     P_NOPE   ; Nope, go to old hander

                CMP     Byte Ptr DS:[245bh], 01h  ; Protection flag set?
                JNE     P_NOPE  ; Nope, can't be the questions yet...

                CMP     CS:[TRIES], 02h ; Did we nuke 2 of them yet?
                JE      P_NOPE  ; Nope, still a few left....

                INC     CS:[TRIES]  ; Well, 1 more down...

                PUSH    BX
                XOR     BX, BX
                MOV     AH, 30h
                MOV     BL, Byte Ptr DS:[238Ch]     ; Get offset into table
                MOV     AL, Byte Ptr DS:[BX+23D9h]  ; Get correct keypress
                ADD     AL, 20h                     ; Add 20 (encryption)
                POP     BX                          ; return w/correct key
                                                    ; in AL
                IRET

P_NOPE:
                JMP    CS:OLD_INT16                 ; Old handler

                IRET

PATCH           Endp


SET_ISR         Proc    Near
                Assume CS: Code_Seg, DS: Code_Seg

                PUSH    ES                

                MOV     AX, 3516h       ; Get Addr of Old Handler
                INT     21h

                MOV     Word Ptr CS:[OLD_INT16], BX     ; Store it
                MOV     AX, ES
                MOV     Word Ptr CS:[Old_INT16+2], AX

                MOV     AX, 2516h
                MOV     DX, Offset PATCH        ; Set up NEW handler
                INT     21h

                POP     ES

                RET
SET_ISR         Endp

DONE_ISR        Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                MOV     AX, 2516h       ; Restore Old handler
                MOV     DX, Word Ptr CS:[OLD_INT16]
                MOV     BX, Word Ptr CS:[OLD_INT16+2]
                PUSH    BX
                POP     DS
                INT     21h

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

                MOV     AH, 4Ah ; Shrink MEM alloc so that IMMORTAL.EXE
                INT     21h     ; Has room 2 load!
                JC      ERROR   ; Oops, oh well....

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
ERROR:
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

Intro_Msg   db 'THE IMMORTAL - (c) 1991 Electronic Arts :: Cracked by Gen. Half-Track',10,13
Intro_0     db '***Note: Patch v1.07 - Stack now protected against hangs.  (Wasn''t a problem,',10,13 
Intro_1     db 'but just poor programming practice...)  ***NOT INTENDED for distribution with ',10,13
Intro_2     db 'any other programs or for illegal duplication of THE IMMORTAL',10,13
Intro_3     db '<<<PRESS ANY KEY TO START>>> - or ESC to QUIT',10,13,'$'
Success_Msg db 10,13,'Thank you for not illegally using this patch --GHT',10,13,'$'
Error_Msg   db 'Sorry, an error has occured...',10,13,'$'
No_File_Msg db 'The startup file IMMORTAL.EXE was not found...',10,13,'$'

NewStack    dw 32 Dup(00)
StartOfStack  EQU $-2

End_Of_File     EQU $  ; Needed in calculation for MEM re-size...
Code_Seg        Ends
End             Start
