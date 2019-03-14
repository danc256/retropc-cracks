code           segment
               assume cs:code
               org 100h

start:         jmp loader

vector         segment at 0000h
               org  0066h*0004h
      targ_int label word
vector         ends



patch          proc near
               assume cs:code

               push   ds
               push   ax
               push   bp
               push   bx

               mov    ax, 0040h
               push   ax
               pop    ds

               mov    ax, ds:[0017h]
               sub    ah, ah
               and    al, 00000111b
               cmp    ax, 0007h
               jne    skip

Fun_code:
               mov    bp, sp
               mov    ax, ss:[bp+0Ah]
               push   ax
               pop    ds

               mov    ax, ds:[0389h]
               add    ax, 1d7eh

               mov    bx, ax
               mov    byte ptr es:[bx], 0f7h
               inc    bx
               mov    byte ptr es:[bx], 0f8h
               inc    bx
               mov    byte ptr es:[bx], 04h
               inc    bx  
               mov    byte ptr es:[bx], 00h

skip:

               pop    bx
               pop    bp                
               pop    ax
               pop    ds

               mov    dx, 0000
               iret



patch          endp

          copy_right  db  'Generic TSR-Shell (c) 1991 GHT - '
          copy_right1 db  'Support BBS: Atlantis (717) 825-5766',10,10,13
          xcr2         db  'TARGHAN DOC FIX (See README.GHT)',10,13  
          xcr3         db  'Due to code complexity, this is a more',10,13
          xcr4         db  'complex crack than I''d rather...',10,13  
          xcr5         db  'WHEN DOC CHECK APPEARS (You get 3 chances):',10,13  
          xcr6         db  'Type anything (at least SOMETHING) and hit',10,13  
          xcr7         db  '<Return>.  You will get a second guess...',10,13
          xcr8         db  'NOW, you must type ''GHT'', then hold down the',10,13 
          xcr9         db  '<left-space>, <right-space>, and <ctrl> key ',10,13  
          xcr10        db  'for about 1 second, then let them go.  Hit',10,13
          xcr11        db  '<Return> and be on thy merry way...',10,13
          xcr12        db  '>>>>General Half-Track',10,10,13,'$'  


loader           proc near
                 mov    ah,9
                 mov    dx,offset copy_right
                 int    21h

                 assume ds:vector,cs:code
                 mov    ax,vector
                 mov    ds,ax
                 cli
                 mov    targ_int, offset patch
                 mov    targ_int[2],cs
                 sti
                 mov    dx, offset loader
                 int    27h
loader           endp

code           ends
end            start
