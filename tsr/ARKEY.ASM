code           segment
               assume cs:code
               org 100h

start:         jmp loader               ;loader

vector         segment at 0000h
               org  0013h*0004h         ;INT13 disk protection patch
      dskint   label word
               org  0021h*0004h         ;INT21 Disk ID patch
      dosint   label word
vector         ends


          old_vector1 dd  0,0           ;Stores old INT13 vector
          old_vector2 dd  0,0           ;Stores old INT21 vector


patch13        proc near                ;INT13 disk check interceptor
               assume cs:code

               cmp    ax,0201h          ;Make sure the GAME is calling it
               jne    nope              ;not a legitimate call!
               cmp    bx,0000h
               jne    nope
               cmp    dx,0000h
               jne    nope

               cmp    cx,0001h          ;Origional Disk?
               je     check1            ;Its there...
               cmp    cx,2601h          ;Prove it!  Read #1 of 4
               je     check2            ;Intercept read #1
               cmp    cx,2603h          ;Read #2 of 4
               je     check2            ;Intercept read #2
               cmp    cx,2701h          ;Read #3 of 4
               je     check2            ;Intercept read #3
               cmp    cx,2703h          ;Read #4 of 4
               je     check2            ;Intercept read #4

nope:
               jmp    old_vector1


check1:
               mov    ax,0001h          ;wimpy BAD SECTOR check
               iret                     ;MOST routines call it quits HERE!

check2:
               mov    ax,1000h          ;But NOOOO...they gotta be assholes..
               mov    word ptr es:[bx],0086h     ;Actual bytes from origional
               mov    word ptr es:[bx+300h],0086h ;disks...so long as they
               iret                               ;MATCH!

patch13        endp

patch21        proc near                        ;INT21 - DISK ID
               assume cs:code

               cmp    ax,1c00h                  ;Make sure not legit call...
               jne    nah
               cmp    bx,0000h
               jne    nah
               cmp    cx,0001h
               jne    nah

               mov    byte ptr ds:[bx],0fdh     ;OK - Tell it its a 360K
               iret

nah:           jmp    old_vector2


patch21        endp

loader           proc near
                 mov    ah,9                    ;My message...
                 mov    dx,offset copy_right
                 int    21h


                 assume ds:vector,cs:code       ;Patch INT21 & INT13
                 mov    ax,vector
                 mov    ds,ax
                 cli
                 mov    ax,dskint
                 mov    word ptr [old_vector1],ax
                 mov    ax,dskint[2]
                 mov    word ptr [old_vector1+2],ax
                 mov    dskint, offset patch13
                 mov    dskint[2],cs

                 mov    ax,dosint
                 mov    word ptr [old_vector2],ax
                 mov    ax,dosint[2]
                 mov    word ptr [old_vector2+2],ax
                 mov    dosint, offset patch21
                 mov    dosint[2],cs
                 sti
                 mov    dx, offset loader
                 int    27h

 copy_right  db  'Generic TSR-Shell v1.1 (c) 1991 GHT - '
 xcr0        db  'Support BBS: Atlantis (717) 825-5766'
 xcr1        db  10,13,'Airborne Ranger Key-Disk simulator:',10,13
 xcr2        db  'Greetz 2:Gunner, MIDIcian, Moonball, Tanis Half-Elven, '
 xcr3        db  'Azrael, Crossbow, Stubby,Alf, Odyessus, Messiah, Alloy'
 xcr4        db  10,13,'Chucky, Willie B. Wright, Winger, and the other '
 xcr5        db  'phun pholx at NEPCO',10,10,13,'-General Half-Track',10,13
 xcr6        db  10,13,'$I bet you think you are really sneaky, hacker!'


loader           endp

code           ends
end            start

;Things 2 add: Program allocate/deallocate option
;Mild Encryption...