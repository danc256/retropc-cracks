code           segment
               assume cs:code
               org 100h

start:         jmp loader   ;loader

vector         segment at 0000h
               org  0013h*0004h        ; INT 05 (Print screen vector)
      psint    label word
vector         ends


          copy_right  db  'Generic TSR-Shell (c) 1991 GHT - '
          copy_right1 db  'Support BBS: Atlantis (717) 825-5766'
          xcr3        db  10,10,13,'Ultima I & II Screw-the-keydisk patch',10,13
          xcr4        db  '-General Half-Track 04/22/91$'


          old_vector  dd  0,0


patch          proc near
               assume cs:code

               cmp    ax,0201h
               je     maybe1
               cmp    ax,0404h
               je     maybe2
               jmp    nope
maybe1:
               cmp    cx,0601h
               jne    nope
               jmp    double_check
maybe2:
               cmp    ch,06h
               jne    nope
double_check:
               cmp    dx,0000h
               jne    nope
               jmp    evil
nope:
               jmp    old_vector


evil:
               mov      ax,0000
               iret


 

patch          endp

loader           proc near
                 mov    ah,9
                 mov    dx,offset copy_right
                 int    21h


                 assume ds:vector,cs:code
                 mov    ax,vector
                 mov    ds,ax
                 cli
                 mov    ax,psint
                 mov    word ptr [old_vector],ax
                 mov    ax,psint[2]
                 mov    word ptr [old_vector+2],ax
                 mov    psint, offset patch
                 mov    psint[2],cs
                 sti
                 mov    dx, offset loader
                 int    27h
loader           endp

code           ends
end            start
