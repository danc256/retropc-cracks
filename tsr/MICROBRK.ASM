Code_Seg        Segment
                Assume  CS: Code_Seg, DS: Code_Seg

                Org     100h
Start:
                Jmp     Main_Loader

                Old_ISR dd ?
                Old_Int21 dd ?

                Done    db 00

                Vectors db 200 dup(00)
                
ISR             Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES
                Push    AX

                Mov     AX, 0040h
                Mov     ES, AX
                Mov     AL, ES:[0017h]
                And     AL, 10h
                Jz      P1_Gotcha
                Cmp     CS:[Done], 01
                Je      P1_Bugger
                Inc     CS:[Done]

                Push    DS
                Push    SI
                Push    DI
                Push    CX
                Push    DX
                
                Push    CS
                Pop     DS
                Mov     SI, Offset Vectors
                Xor     AX, AX
                Mov     ES, AX
                Xor     DI, DI
                Mov     CX, 200
                Cld

                Rep     Movsb

                Xor     AX, AX
                Mov     ES, AX
                
                Mov     DX, Offset ISR
                Push    CS
                Pop     AX
                Mov     ES:[004Ch], DX
                Mov     ES:[004Eh], AX

                Mov     DX, Word Ptr CS:[Old_Int21]
                Mov     AX, Word Ptr CS:[Old_Int21+2]
                Mov     ES:[0084h], DX                
                Mov     ES:[0086h], AX

                Pop     DX
                Pop     CX
                Pop     DI
                Pop     SI
                Pop     DS
                Pop     AX
                Pop     ES

P1_Bugger:
                Int     03h
                Jmp     ISR_Nope

P1_Gotcha:
                Pop     AX
                Pop     ES

ISR_Nope:
                Jmp     CS:[Old_ISR]

ISR             Endp

End_Tsr         EQU $+1

Main            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
Main_Loader:
                Mov     AX, 3521h
                Int     21h

                Mov     Word Ptr [Old_Int21], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_Int21+2], BX

                Mov     AX, 3513h
                Int     21h

                Mov     Word Ptr [Old_ISR], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_ISR+2], BX

                Mov     AX, 2513h
                Mov     DX, Offset ISR
                Int     21h

                Xor     AX, AX
                Mov     DS, AX
                Push    CS
                Pop     ES
                Xor     SI, SI
                Mov     DI, Offset Vectors
                Mov     CX, 200
                Cld

                Rep     Movsb


                Mov     DX, (Offset End_Tsr)
                Int     27h

Main            Endp



Code_Seg        Ends
End             Start
