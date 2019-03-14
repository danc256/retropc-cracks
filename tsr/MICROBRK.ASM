Code_Seg        Segment
                Assume  CS: Code_Seg, DS: Code_Seg

                Org     100h
Start:
                Jmp     Main_Loader

                Old_ISR dd ?
                Old_BUG dd ?
                Vectors db 16 dup(00)
                Done    dw 00

ISR             Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES
                Push    AX

                Mov     AX, 0040h
                Mov     ES, AX
                Mov     AL, ES:[0017h]
                And     AL, 10h
                Jz      P1_Gotcha

                Push    DS
                Push    SI
                Push    DI
                Push    CX
                
                Push    CS
                Pop     DS
                Mov     SI, Offset Vectors
                Xor     AX, AX
                Mov     ES, AX
                Xor     DI, DI
                Mov     CX, 10h
                Cld

                Rep     Movsb

                Pop     CX
                Pop     DI
                Pop     SI
                Pop     DS

                Int     03h

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

                Mov     AX, 3513h
                Int     21h

                Mov     Word Ptr [Old_ISR], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_ISR+2], BX

                Mov     AX, 2513h
                Mov     DX, Offset ISR
                Int     21h

                Mov     AX, 3503h
                Int     21h

                Mov     Word Ptr [Old_Bug], BX
                Mov     BX, ES
                Mov     Word Ptr [Old_Bug+2], BX

                Xor     AX, AX
                Mov     DS, AX
                Push    CS
                Pop     ES
                Xor     SI, SI
                Mov     DI, Offset Vectors
                Mov     CX, 10h
                Cld

                Rep     Movsb


                Mov     DX, (Offset End_Tsr)
                Int     27h

Main            Endp



Code_Seg        Ends
End             Start
