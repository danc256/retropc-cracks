; Generic Spawner shell, v2.00, (C) 1990-1994 GHT, Ltd.  All Rights Reserved

; General purpose shell for writting .COM files that modify the IBM
; environment then execute another program under that environment.  
; Removes all modifications (Patches + Memory allocated) upon termination of
; spawned program automatically.  Useful for games cheats and such.

; So long as my name is still DISPLAYED upon execution, in a similar manner
; as the author of modifications to this program, it may be modified freely.
; Oh yeah, this is FREEWARE.  See DOCS at end of file.

; Compiled with Turbo Assembler (c) Borland International 
; (Source compatible with most other popular assemblers I.E. MASM)

; ************* MACROS

PHead MACRO ProcLabel
  Handler_&ProcLabel  Proc    Near            
  Assume  CS: Code_Seg, DS: Code_Seg
ENDM

PTail MACRO ProcLabel
  Handler_&ProcLabel Endp
ENDM

Old MACRO Vector
  Old_Int&Vector dd 0000h
ENDM

MJump MACRO Vector
  Jmp CS:Old_Int&Vector
ENDM

MCall MACRO Vector
  Call CS:Old_Int&Vector
ENDM

MSetNVect MACRO Old_Loc, New_Loc, Vector
  Mov   AX, Offset &Old_Loc
  Push  AX
  Mov   AX, Offset &New_Loc
  Push  AX
  Mov   AX, &Vector
  Push  AX

  Call  SetIntVec
ENDM

MRestNVect MACRO Old_Loc, Vector
  Mov   AX, Offset &Old_Loc
  Push  AX
  Mov   AX, &Vector
  Push  AX

  Call  RestIntVec
ENDM

MSetVect MACRO Vector
  Mov    AX, Offset Old_Int&Vector
  Push   AX
  Mov    AX, Offset Handler_&Vector
  Push   AX
  Mov    AX, &Vector
  Push   AX

  Call   SetIntVec
ENDM

MRestVect MACRO Vector
  Mov   AX, Offset Old_Int&Vector
  Push  AX
  Mov   AX, &Vector
  Push  AX

  Call  RestIntVec
ENDM

                CR         EQU 13          ; Carriage Return
                CRE        EQU 13, 00      ; ASCIIZ string w/CR

                A_UP       EQU 4800h       ; Up-Arrow Key keyboard code
                A_DN       EQU 5000h       ; Down-Arrow Key keyboard code
                A_LT       EQU 4B00h       ; Left-Arrow Key keyboard code
                A_RT       EQU 4D00h       ; Right-Arrow Key keyboard code
                K_ESC      EQU 011Bh       ; Escape Key keyboard code
                K_CR       EQU 1C0Dh       ; Return Key keyboard code
                
                PATCH_REV  EQU '1.10 Beta' ; Version for patch
                BOOT_ME    EQU 'TIE.EXE'   ; Startup file patch runs
                
                TIE_FITR   EQU 195,'0',180 ; ANSI Tie-Fighter (cursor)

                IVect_1    EQU 21h         ; Vector's interrupt #

; ************* Code Starts Here

Code_Seg        Segment
                Assume CS: Code_Seg, DS: Code_Seg

StartOfCode     EQU     $
                Org     100h
Start:
                Jmp        Loader       ; Go to start of program

                ; The following variables are needed by the HANDLERS, and
                ; must be preserved throughout execution.

                ; The lower the # the faster
                MislDelMod dw 0050h     ; Becomes Missle Delay   
                LasrDelMod dw 0040h     ; Becomes Laser Delay    
                TrakRate   dw 049Ch     ; Actual value for target lock rate
                
                ; The higher the # the faster
                FixLasrR   db 00        ; Fix Laser Firing Rate
                FixMislR   db 00        ; Fix Missle Firing Rate
                FixShldC   db 00        ; Fix Shield Charging Rate
                FixLasrC   db 00        ; Fix Laser Charging Rate
                FixBeamC   db 00        ; Fix Beam Charging Rate
                FixTrakR   db 00        ; Target Lock rate 
                FixUnlmA   db 00        ; Unlimited Ammo
                FixWeapS   db 00        ; Interactive weapons toggle active

                PtchActive db 00        ; 1=In flight, 0=Anywhere else

                AmmoPos    db 00        ; Position in Ammo Table
                AmmoTable  db 08Fh, 090h, 094h, 095h, 096h, 097h, 098h
                
                BootFile   db BOOT_ME,00h ; Name of startup file

                Env_Ptr    dw 0000      ; Table needed to spawn child
                Param_Pl   dw 0080h     ; process (Contains pointer to
                Param_Ph   dw 0000h     ; parent's environment, pointer
                Fcb_1l     dw 005Ch     ; to command line parameter list,
                Fcb_1h     dw 0000h     ; and pointers to File Control
                Fcb_2l     dw 006Ch     ; blocks #1 & #2...
                Fcb_2h     dw 0000h

                Old_SP     dw 0000h     ; Holds old Stack Pointer
                Ret_Addr   dw 0000h     ; Holds return address from Spawn
                
                UserInt1   dw 0060h     ; Interrupt for patch code
                UserVec1   dd 0000h     ; Stores location of old INT addr.

                Old %IVect_1            ; Stores old location of IVect 1
              

; Wonderful piece of code to check where in the hell the code is that needs
; to be patched.  This was not fun.

PHead %IVect_1
                Cmp     AH, 3Fh                 ; Reading a file?
                Je      P1_DontSkip             ; No, ignore this call
                Jmp     P1_SkipPatch            

P1_DontSkip:
                Cmp     CX, 0F800h              ; 2nd part of FLIGHT.OVL?
                Je      P1_ContNoSkip1          ; Uh-uh.  Skip it.
                Jmp     P1_MagicOff1            ; Might be exiting flight sim


; ****** Check for ENTERING flight sim section

P1_ContNoSkip1:

                Pushf                           ; Do Call, check for signature
                MCall   %IVect_1                

                Cmp     Word Ptr DS:[0000h], 5E89h      ; Magic #'s for
                Je      P1_IsMagic1                     ; STARTING flight sim
                Iret
P1_IsMagic1:

                Cmp     Word Ptr DS:[0002h], 38B4h      ; Other part
                Je      P1_IsMagic2
                Iret


; ****** Check for LEAVING flight sim section

P1_MagicOff1:
                Cmp     CX, 0F840h              ; Is it the length of the 
                Je      P1_MagicOffTest         ; END of the sim overlay?
                Jmp     P1_SkipPatch            ; No, skip it

P1_MagicOffTest:
                
                Pushf                           ; Do Call, check for signature
                MCall   %IVect_1                

                Push    BX
                Mov     BX, DX
                Add     BX, 60h
                Cmp     Word Ptr DS:[BX], 09A11h
                Pop     BX
                Je      P1_MagicOff1OK
                Iret

P1_MagicOff1OK:
                Push    BX
                Mov     BX, DX
                Add     BX, 62h
                Cmp     Word Ptr DS:[BX], 007AEh
                Pop     BX
                Je      P1_MagicOff2OK
                Iret

P1_MagicOff2OK:
                Mov     CS:[PtchActive], 00             ; Turn OFF patch

                Push    AX
                Push    DS

                Mov     AX, 40h
                Mov     DS, AX
                Mov     AL, Byte Ptr DS:[0017h]
                And     AL, Not 16
                Mov     Byte Ptr DS:[0017h], AL

                Pop     DS
                Pop     AX

                Iret

; ************* OK! START PATCHING!

P1_IsMagic2:
                Mov     CS:[PtchActive], 01             ; Turn ON patch

                Push    AX
                Push    DS

                Mov     AX, 40h
                Mov     DS, AX
                Mov     AL, Byte Ptr DS:[0017h]
                Or      AL, 16
                Mov     Byte Ptr DS:[0017h], AL

                Pop     DS
                Pop     AX

                Push    AX
                Mov     AX, CS:[UserInt1]               ; Build INT 6x code
                Mov     AH, 0CDh
                Xchg    AL, AH

                Cmp     CS:[FixUnlmA], 00
                Je      P1_SkipAmmo

                Mov     Word Ptr DS:[8815h], 9090h      ; Unlimited missles!
                Mov     Word Ptr DS:[8817h], 9090h

P1_SkipAmmo:
                Cmp     CS:[FixLasrR], 00
                Je      P1_SkipLasrR

                Mov     Word Ptr DS:[8330h], AX         ; Laser delay fix
                Mov     Word Ptr DS:[8332h], 9090h

P1_SkipLasrR:
                Cmp     CS:[FixMislR], 00
                Je      P1_SkipMislR

                Mov     Word Ptr DS:[83ACh], AX         ; Missle delay fix
                Mov     Word Ptr DS:[83AEh], 9090h

P1_SkipMislR:
                Cmp     CS:[FixLasrC], 00
                Je      P1_SkipLasrC

                Mov     Word Ptr DS:[7FE1h], AX         ; Laser recharge fix

P1_SkipLasrC:
                Cmp     CS:[FixShldC], 00               
                Je      P1_SkipShldC

                Mov     Word Ptr DS:[7F62h], AX         ; Shield recharge fix

P1_SkipShldC:
                Cmp     CS:[FixBeamC], 00               
                Je      P1_SkipBeamC

                Mov     Word Ptr DS:[805Ah], AX         ; Beam recharge fix

P1_SkipBeamC:
                Cmp     CS:[FixTrakR], 00               
                Je      P1_SkipTrakR                    
                
                Mov     AX, Word Ptr CS:[TrakRate]
                Mov     Word Ptr DS:[7CFBh], AX         ; Target locking rate
P1_SkipTrakR:                                           ; AX is wiped out!!!

                Pop     AX
                Iret

P1_SkipPatch:                                           
                Cmp     AH, 08h                         ; Weapons cheat...
                Jne     P1_Skip

                Cmp     CS:[PtchActive], 01             ; Go only when in 
                Jne     P1_Skip                         ; flight.

                Cmp     CS:[FixWeapS], 01               ; Go only when selected 
                Jne     P1_Skip                         

                Pushf                                   ; Read keypress
                MCall   %IVect_1                

                Cmp     AL, 17h                         ; Is it a CTRL+W?
                Je      P1_WeapFixPatch                 ; Yeah...
                Iret                                    ; Nah, screw it...

P1_WeapFixPatch:
                Push    BX

                Mov     BX, Word Ptr DS:[0C8B4h]        ; Load BX w/Player Seg
                Cmp     Word Ptr DS:[BX+0E0h], 00       ; Are missles present?
                Je      P1_CleanSkip                    ; No, clean up & go

                Cmp     Byte Ptr DS:[BX+0D0h], 01       ; Lasers only?
                Jne     P1_Ions

                Mov     Word Ptr DS:[0C8CDh], 0000      ; Select Lasers...
                Jmp     P1_DoneFix

P1_Ions:
                Mov     Word Ptr DS:[0C8CDh], 0001      ; Select Ions...

P1_DoneFix:
                Push    BX
                
                Mov     BL, CS:[AmmoPos]
                Cmp     BL, 06
                Jb      P1_NotZeroYet

                Xor     BL, BL
                Jmp     P1_ZeroBL

P1_NotZeroYet:
                Inc     BL

P1_ZeroBL:
                Mov     CS:[AmmoPos], BL
                Xor     BH, BH

                Mov     AL, CS:[BX+Offset AmmoTable]

                Pop     BX

                Mov     Byte Ptr DS:[BX+0E1h], AL
                Mov     AX, 0877h

P1_CleanSkip:                
                Pop     BX
                Iret
                
P1_Skip:
                MJump %IVect_1
PTail %IVect_1


; Handler to which all INT 0x6? calls are directed.  Handles the heavy stuff.
TimerHandler  Proc      Near
              Assume    CS: Code_Seg, DS: Code_Seg

              Push      BP
              Mov       BP, SP
              
              Cmp       BX, DS:[0C8B4h]         ; Verify that the USER's 
              Je        IV2_UserUpdate          ; stats are the ones being
              Jmp       IV2_Skip                ; modified, not the computer's
              
IV2_UserUpdate:              
              Push      AX
              Push      BX
              
; *********** This routine cannot be generalized!
              Cmp       [BP+02], 0712h          ; Is a laser firing?
              Jne       IV2_MissleDelay         ; No, check next (missles)

              Lea       BX, [BX+SI+0DCh]        ; Decrease the firing delay
              Mov       AX, CS:[LasrDelMod]     ; Get delay value
              Mov       [BX], AX                ; Make it the new delay
              Jmp       IV2_Done

IV2_MissleDelay:
; *********** This routine cannot be generalized!
              Cmp       [BP+02], 078Eh          ; Is it a missle firing?
              Jne       IV2_RechargeLasers      ; No, check next

              Lea       BX, [BX+SI+0E6h]        ; Decrease the firing delay
              Mov       AX, CS:[MislDelMod]     ; Get delay value
              Mov       [BX], AX                ; Make it the new delay
              Jmp       IV2_Done

IV2_RechargeLasers:

              Cmp       [BP+02], 03C3h          ; Is it rechargeing something?
              Jne       IV2_RechargeShields     ; No

              Sub       AH, AH

              Mov       AL, CS:[FixLasrC]       ; Charge rate (also enable)
              Mov       [BP-02], AX

              Jmp       IV2_Done

IV2_RechargeShields:

              Cmp       [BP+02], 0344h
              Jne       IV2_RechargeBeam

              Sub       AH, AH                  ; Overwritten by INT 0x6?
              
              Mov       AL, CS:[FixShldC]       ; Charge rate (also enable)
              Mov       [BP-02], AX             ;

              Jmp       IV2_Done

IV2_RechargeBeam:

              Cmp       [BP+02], 043Ch   
              Jne       IV2_Done

              Sub       AH, AH                  ; Overwritten by INT 0x6?
              
              Mov       AL, CS:[FixBeamC]       ; Charge rate (also enable)
              Mov       [BP-02], AX             

IV2_Done:
              Pop       BX
              Pop       AX
              
IV2_Skip:
              Mov       SP, BP
              Pop       BP

              Iret

TimerHandler  Endp


ISR_Remove      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                MRestVect %IVect_1
                MRestNVect UserVec1 UserInt1

                Ret
ISR_Remove      Endp


; Restores an interrupt vector [BP+06] == Old addr
;                              [BP+04] == Vector to patch
RestIntVec      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    BP
                Mov     BP, SP

                Push    DS                      ; Save segments (good idea...)

                Mov     DI, [BP+06]
                Mov     DX, [DI]                ; Offset of INT to restore
                
                Mov     AX, [DI+02]
                Mov     DS, AX                  ; Segment of INT to restore
                
                Mov     AX, 2500h 
                Add     AX, [BP+04]
                Int     21h

                Pop     DS

                Mov     SP, BP
                Pop     BP

                Ret     0004

RestIntVec      Endp


Spawn           Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Pop     Ret_Addr

                Mov     AH,  4Ah  ; Re-size memory to bare minimum
                Mov     BX,  (Offset EndOfCode - StartOfCode + 15) shr 4
                Int     21h

                Mov     AX, 4B00h       ; Prepare to execute LOAD.EXE
                Mov     BX, Offset Env_Ptr
                Mov     DX, Offset BootFile
                Mov     Old_SP, SP                
                Int     21h

                Mov     CX, CS          ; Restore all registers... (EXE
                Mov     DS, CX          ; trashes ALL but CS:IP registers
                Mov     SS, CX          
                Mov     SP, Old_SP
                Mov     ES, CX
                Jc      S_Error

S_OK:
                Xor     AX, AX          ; Set Function PASSED

S_Error:
                Push    Ret_Addr
                Ret
Spawn           Endp


Main            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
Loader:              
                Mov     AX, 0003h               ; Clear Screen (CO80 mode)
                Int     10h

                Call    SetPallet               ; Change to cool gradients

                Mov     SI, Offset Intro_Msg
                Mov     CX, -1
                Call    ColorPrint

                Mov     AX, Offset UserInt1     ; Find a free INT vector
                Push    AX
                Call    GetFreeInt

                Or      AX, AX                  ; Oops... croaked.  See ya.
                Jz      M_Bye

                Mov     SI, Offset Menu_Msg
                Mov     CX, -1
                Call    ColorPrint

                Mov     AX, Offset Menu_Table   ; Start of message table
                Push    AX
                Call    Menu
                Pop     AX                      ; AX=0 (quit), AX=1 (continue)

                Or      AL, AL
                Jz      M_Bye

                Call    SaveMenu                ; Save menu slider positions
                Call    SetMenu                 ; Impliment menu settings
                
                Mov     [MyCursorX], 0000
                Mov     [MyCursorY], 0000
                Mov     SI, Offset Start_Msg
                Mov     CX, -1
                Call    ColorPrint

                Mov     SP, Offset StackStart

                Call    ISR_Install              
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
                Int     21h                     ; Error/success message
                
                Call    ISR_Remove              ; Clean up INT vectors

M_Bye:
                Mov     AH, 4Ch                 ; Quit to DOS
                Int     21h

Main            Endp

; All error/status message text bodies...
Error_Msg   db 'Sorry, an error has occured! <Aborting>',10,13,'$'
NoBoot_Msg  db 'Couldn''t find the startup file!',10,13,'$'
Bye_Msg     db 'Another quality product from GHT Labs. (c) 1994',10,13,'$'

MyStack     db 10 dup('Stack ')  ; Internal stack (NEVER CHANGE)
StackStart  EQU $-2

EndOfCode   EQU $  ; ANYTHING BEYOND HERE GETS DUMPED ON EXE


GetFreeInt      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    BP
                Mov     BP, SP

                Push    ES

                Mov     SI, [BP+04]             ; Addr. of variable holding
                                                ; Int number (to scan & use) 
GF_Loop:                
                Mov     AX, [SI]                ; Load current value
                Mov     AH, 35h                 ; Check address @ value
                Int     21h

                Mov     AX, ES                  ; Is it zero?
                Or      AX, BX

                Jz      GF_Found                ; Yep.  Got one.

                Inc     Word Ptr DS:[SI]        ; No, check the next one.
                Cmp     Word Ptr DS:[SI], 069h  ; Ran outta ints to scan.
                Ja      GF_Failed
                Jmp     GF_Loop
GF_Found:
                Mov     AX, [SI]
                Sub     AL, 60h - '0'
                Mov     SI, Offset Patch_Me
                Mov     [SI], AL
                Mov     SI, Offset Intr_Msg
                Mov     CX, -1
                Call    ColorPrint
                Mov     AX, 0001                ; Success (TRUE)

                Jmp     GF_Exit
GF_Failed:
                Mov     SI, Offset IntF_Msg
                Mov     CX, -1
                Call    ColorPrint
                Xor     AX, AX                  ; Failed (FALSE)

GF_Exit:                
                Pop     ES
                
                Mov     SP, BP
                Pop     BP

                Ret     0002                    ; Pop off pushed params

GetFreeInt      Endp


; Sets up an interrupt vector [BP+08] == Old addr, [BP+06] == New addr
;                             [BP+04] == Vector to patch
SetIntVec       Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    BP
                Mov     BP, SP                  ; Standard stack frame

                Push    ES                      ; Gotta preserve segments

                Mov     AX, 3500h               ; Get old location 
                Add     AX, [BP+04]
                Int     21h

                Mov     DI, [BP+08]             ; Location to store old addr.
                Mov     Word Ptr DS:[DI], BX
                Mov     Word Ptr DS:[DI+2], ES

                Mov     AX, 2500h               ; Install new vector
                Add     AX, [BP+04]
                Mov     DX, [BP+06]             
                Int     21h

                Pop     ES                      ; Restore old ES

                Mov     SP, BP
                Pop     BP

                Ret     0006

SetIntVec       Endp


Setup_Param     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Mov     Param_Ph, CS    ; Set SEGMENT portion of FAR
                Mov     Fcb_1h,   CS    ; Pointers to Params, & FCB's
                Mov     Fcb_2h,   CS

                Ret
Setup_Param     Endp


ISR_Install     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                MSetVect %IVect_1
                MSetNVect UserVec1 TimerHandler UserInt1

                Ret
ISR_Install     Endp


Menu            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    BP
                Mov     BP, SP
                Sub     SP, 6                   ; 3 Local Variables
                
                Mov     AH, 01
                Mov     CX, 0F00h
                Int     10h                     ; Turn off cursor

                Mov     DI, [BP+04]             ; Location of Menu Table

                Xor     AX, AX
                Mov     AL, [DI]
                Mov     [BP-02], AX             ; Table Length
                Mov     Word Ptr [BP-04], 0000  ; Current Position in Table
                Mov     Word Ptr [BP-06], 0000  ; NEW Position in Table
                Inc     DI                      ; DI points to TABLE data
                Inc     Byte Ptr [BP+04]        ; Also points to TABLE data
                
                Mov     CX, AX                  ; Table Len in CX
                Inc     CX
                Xor     BX, BX                  ; SI will be index register
                Cld                             ; Clear direction flag (down)
                Push    DI                      ; Preserve start of table loc.

MU_MenuRefresh:                
                Mov     [DI].UpdateLine, 01     ; Force line update
                Push    CX
                Call    MU_UpdateScreen
                Pop     CX
                Add     DI, SIZE SMenuTable
                Loop    MU_MenuRefresh
                
                Pop     DI                      ; Restore start of table loc.
                
                Call    MU_InitCursor           ; Draw Initial Cursor
                Jmp     MU_KeyLoop

MU_MenuLoop:
                Call    MU_UpdateScreen

MU_KeyLoop:                
                Xor     AX, AX
                Int     16h                     ; Get a keypress

                Cmp     AX, K_ESC               ; Handles keypresses
                Je      MU_Abort
                Cmp     AX, A_UP
                Je      MU_CursorUp
                Cmp     AX, A_DN
                Je      MU_CursorDn
                Cmp     AX, A_LT
                Je      MU_AdjustLt
                Cmp     AX, A_RT
                Je      MU_AdjustRt
                Cmp     AX, K_CR
                Je      MU_Continue
                Jmp     MU_KeyLoop

MU_CursorUp:
                Mov     AX, [BP-04]
                Or      AX, AX                          ; At zero location?
                Jz      MU_WrapUp                       ; Yeah, wrap to bottom

                Dec     AX                              ; Just back up one
                Mov     [BP-06], AX
                Jmp     MU_MenuLoop

MU_WrapUp:
                Mov     AX, [BP-02]                     ; Wrap to the bottom
                Mov     [BP-06], AX
                Jmp     MU_MenuLoop

MU_CursorDn:
                Mov     AX, [BP-04]
                Cmp     [BP-02], AX                     ; At bottom location?
                Je      MU_WrapDn                       ; Yeah, wrap to top

                Inc     AX                              ; Just move down one
                Mov     [BP-06], AX
                Jmp     MU_MenuLoop

MU_WrapDn:
                Mov     Word Ptr [BP-06], 0000          ; Wrap to the top
                Jmp     MU_MenuLoop

MU_AdjustLt:
                Inc     [DI].UpdateLine                 ; The line has changed
                Mov     AL, [DI].CurrentPos
                Or      AL, AL                          ; Is it already at 0?
                Jz      MU_WrapLt                       

                Dec     [DI].CurrentPos                 ; Move to the left 1
                Jmp     MU_MenuLoop

MU_WrapLt:
                Mov     AL, [DI].ItemCount              ; Wrap off the left 
                Mov     [DI].CurrentPos, AL
                Jmp     MU_MenuLoop 

MU_AdjustRt:
                Inc     [DI].UpdateLine                 ; The line has changed
                Mov     AL, [DI].CurrentPos             ; Is it all the way
                Cmp     [DI].ItemCount, AL              ; to the right?
                Je      MU_WrapRt                       ; Yes

                Inc     [DI].CurrentPos                 ; Move to the right 1
                Jmp     MU_MenuLoop

MU_WrapRt:
                Mov     [DI].CurrentPos, 00             ; Move to beginning of
                Jmp     MU_MenuLoop                     ; line

MU_Abort:                                
                Xor     AX, AX
                Mov     [BP+04], AX
                Jmp     MU_Cleanup

MU_Continue:
                Mov     AX, 0001
                Mov     [BP+04], AX

MU_Cleanup:
                Xor     BX, BX
                Mov     AL, 03
                Int     10h                             ; Clear the screen
                
                Mov     AH, 01
                Mov     CX, 0607h
                Int     10h                             ; Turn on cursor

                Mov     SP, BP
                Pop     BP

                Ret

; ************* NESTED FUNCTION - Dependent on MENU's stack frame
MU_UpdateScreen:
                Mov     AX, [BP-04]             ; Did the cursor move?
                Cmp     AX, [BP-06]
                Je      MU_NoDrawSelect         ; No, don't update it

MU_InitCursor:
                Mov     DX, [DI]                ; Load both X&Y pos at once
                Xor     AX, AX
                Mov     AL, DH
                Mov     [MyCursorY], AX
                Xor     DH, DH
                Mov     [MyCursorX], DX         ; Set Cursor

                Mov     SI, Offset Blank
                Mov     CX, -1
                Call    ColorPrint              ; Erase Cursor

                Mov     AX, SIZE SMenuTable
                Mul     Byte Ptr [BP-06]
                Mov     DI, [BP+04]
                Add     DI, AX                  ; Compute new cursor position

                Mov     DX, [DI]                ; Load both X&Y pos at once
                Xor     AX, AX
                Mov     AL, DH
                Mov     [MyCursorY], AX
                Xor     DH, DH
                Mov     [MyCursorX], DX         ; Set Cursor
                
                Mov     SI, Offset Cursor
                Mov     CX, -1
                Call    ColorPrint              ; Draw Cursor
                
                Mov     AX, [BP-06]
                Mov     [BP-04], AX             ; Update cursor position

                Ret                             ; Can't update cursor/slider
                                                ; in the same call.
MU_NoDrawSelect:
                Cmp     [DI].UpdateLine, 00
                Jz      MU_NoUpdateLine

                Mov     [DI].UpdateLine, 00     ; Clear flag

                Mov     DL, [DI].SliderPos      ; Is a slider active?
                Cmp     DL, -1
                Je      MU_NoSlider

                Mov     DH, [DI].YPos
                Xor     AX, AX
                Mov     AL, DH
                Mov     [MyCursorY], AX
                Xor     DH, DH
                Mov     [MyCursorX], DX         ; Set Cursor at slider

                Mov     SI, Offset SliderChar
                Xor     CH, CH
                Mov     CL, [DI].CurrentPos     ; # of chars to print
                Call    ColorPrint              ; Print Slider chars

                Mov     SI, Offset SliderBlank 
                Mov     CX, 0010
                Mov     AL, [DI].CurrentPos
                Sub     CL, AL
                Call    ColorPrint              ; Pad out w/the blank char

MU_NoSlider:
                Mov     DL, [DI].TextPos        ; Is there a text box?
                Cmp     DL, -1
                Je      MU_NoUpdateLine         ; No.  Skip it.

                Mov     DH, [DI].YPos
                Xor     AX, AX
                Mov     AL, DH
                Mov     [MyCursorY], AX
                Xor     DH, DH
                Mov     [MyCursorX], DX         ; Set Cursor

                Mov     BX, [DI].MsgPtr         ; BX points to message table
                Xor     AH, AH
                Mov     AL, [BX]                ; AX contains message length
                Inc     BX                      ; BX points to message text
                Mov     SI, BX                  ; DX points to message 0
                
                Xor     BH, BH                  ; Compute current message pos
                Mov     BL, [DI].CurrentPos
                Mul     BL

                Add     SI, AX                  ; Add it to base offset
                Mov     CX, -1
                Call    ColorPrint              ; Print the message

MU_NoUpdateLine:
                Ret

Menu            Endp


SaveMenu        Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    ES

                Mov     AX, Word Ptr DS:[002Ch]         ; Offset of environment
                Dec     AX
                Mov     ES, AX
                Mov     BX, 0003
                Mov     DX, ES:[BX]                     ; Size of environment
                Mov     CX, 0004                        ; in paragraphs.
                Shl     DX, CL                          ; Convert to bytes
                Mov     CX, DX
                
                Inc     AX
                Mov     ES, AX                          ; Points to ENV. block
                Xor     DI, DI                          ; Scan for ZERO
                Xor     AX, AX
                Cld

MS_EnvScan:
                Repne   Scasb                           ; Scan for a zero
                Cmp     Word Ptr ES:[DI], 0100h         ; End of Env. block?
                Je      MS_Found                        ; Yes, find filename
                Or      CX, CX
                Jnz     MS_EnvScan                      ; No, continue scan
                Jmp     MS_Failed                       ; End not found (ERROR)

MS_Found:
                Push    DS
                Add     DI, 0003                        ; Move to filename start
                Mov     DX, DI
                Mov     AX, ES
                Mov     DS, AX
                Mov     AX, 3D02h
                Int     21h                             ; Open file
                Pop     DS
                Jc      MS_Failed

                Mov     BX, AX                          ; Preserve file handle
                Mov     AX, 4200h
                Xor     CX, CX
                Mov     DX, (Offset TABLE_START)-100h
                Int     21h                             ; Seek to position
                Jc      MS_CloseFile

                Mov     AH, 40h
                Mov     CX, (TABLE_END - TABLE_START)
                Mov     DX, Offset TABLE_START
                Int     21h                             ; Write information
                
MS_CloseFile:   
                Mov     AH, 3Eh
                Int     21h                             ; Close file

MS_Failed:              
                Pop     ES
                Ret

SaveMenu        Endp

SetCursor       Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     AX, [MyCursorX]
                Mov     BX, [MyCursorY]
                Mov     DX, BX

                Mov     CL, 06
                Shl     BX, CL                  ; Multiply BX by 64

                Mov     CL, 04
                Shl     DX, CL                  ; Multiply DX by 16
                Add     BX, DX                  ; Same as DX * 80
                Add     AX, BX                  ; Add X position
                Shl     AX, 1                   ; Convert to screen location

                Mov     [MyCursor], AX
                Ret

SetCursor       Endp

; Parameters:   SI = Offset of text string, CL = color of text
; Updates MyCursorX, MyCursorY 
; Does not handle screen-wraps or screen scrolling
ColorPrint      Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Push    BP
                Mov     BP, SP
                Sub     SP, 0004                ; 2 Local variables

                Push    ES
                Push    DI

                Mov     Word Ptr [BP-02], 0007  ; Store color value (default)
                Mov     [BP-04], CX             ; Length to print (-1=ASCIIZ)

                Call    SetCursor               ; Initalize cursor position

                Mov     AX, 0B800h
                Mov     ES, AX                  ; Color screen memory
                Cld                             ; Read & write forward
                
CP_CRPrint:                
                Mov     DI, MyCursor
                
CP_NewColor:                
                Mov     CX, [BP-02]             ; Color attribute
                Mov     AH, CL

CP_PrintLoop:
                Cmp     Word Ptr [BP-04], 0000
                Je      CP_Done
                
                Lodsb                           ; Read a character of text

                Cmp     AL, 13                  ; Is it a carriage return?
                Je      CP_DoCR
                Cmp     AL, 01                  ; Change color control?
                Je      CP_ChangeColor          
                Or      AL, AL                  ; End of the text
                Jz      CP_Done

                Stosw                           ; No, just print it
                Inc     [MyCursorX]
                Dec     Word Ptr [BP-04]
                Jmp     CP_PrintLoop

CP_DoCR:
                Inc     [MyCursorY]
                Mov     [MYCursorX], 0000
                Call    SetCursor               ; Re-calculate cursor position
                Jmp     CP_CRPrint

CP_ChangeColor:
                Lodsb
                Mov     [BP-02], AX
                Jmp     CP_NewColor

CP_Done:
                Pop     DI
                Pop     ES

                Mov     SP, BP
                Pop     BP

                Ret

ColorPrint      Endp


SetPallet       Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     AX, 1012h
                Mov     BX, 0038h
                Mov     CX, 0008
                Mov     DX, Offset Pallet8
                Int     10h                     ; Set Color Registers

                Mov     AX, 1012h
                Mov     BX, 0001h
                Mov     CX, 0005
                Mov     DX, Offset Pallet1
                Int     10h                     ; Set Color Registers
                
                Mov     AX, 1010h
                Mov     BX, 0007
                Mov     DH, Pallet7             ; Red
                Mov     CH, Pallet7+1           ; Green
                Mov     CL, Pallet7+2           ; Blue
                Int     10h

                Mov     AX, 1010h
                Mov     BX, 0014h
                Mov     DH, Pallet8             ; Red
                Mov     CH, Pallet8+1           ; Green
                Mov     CL, Pallet8+2           ; Blue
                Int     10h

                Ret

SetPallet       Endp


SetMenu         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     SI, Offset Menu_Table
                Xor     CX, CX
                Mov     CL, [SI]                ; # Of items to move
                Inc     CL                      ; Remember, its 0 based!
                Add     SI, CurrentPos + 1

                Mov     DI, Offset FixLasrR     ; Point to On/Off toggles
                Cld
SM_OnOff:
                Movsb
                Add     SI, SIZE SMenuTable - 1 ; Sub 1 for auto-increment
                Loop    SM_OnOff                ; Move menu data into toggles

                Xor     BX, BX

                Mov     SI, Offset Charge_Tabl  ; All following code takes
                Mov     BL, [FixShldC]          ; the value in the toggle
                Add     SI, BX                  ; cell, and replaces it with
                Mov     AL, [SI]                ; the value found in the 
                Mov     [FixShldC], AL          ; appropriate array.

                Mov     SI, Offset Charge_Tabl
                Mov     BL, [FixLasrC]
                Add     SI, BX
                Mov     AL, [SI]
                Mov     [FixLasrC], AL

                Mov     SI, Offset Charge_Tabl
                Mov     BL, [FixBeamC]
                Add     SI, BX
                Mov     AL, [SI]
                Mov     [FixBeamC], AL

                Mov     SI, Offset Delay_Tabl
                Mov     BL, [FixLasrR]
                Shl     BX, 1
                Add     SI, BX
                Mov     AX, [SI]
                Mov     [LasrDelMod], AX

                Mov     SI, Offset Delay_Tabl
                Mov     BL, [FixMislR]
                Shl     BX, 1
                Add     SI, BX
                Mov     AX, [SI]
                Mov     [MislDelMod], AX

                Mov     SI, Offset Trak_Tabl
                Mov     BL, [FixTrakR]
                Shl     BX, 1
                Add     SI, BX
                Mov     AX, [SI]
                Mov     [TrakRate], AX

                Ret

SetMenu         Endp

; **************** Disposable Data (Tossed upon EXEC)

MyCursorX       dw      0000            ; X-Cord of cursor
MyCursorY       dw      0000            ; Y-Cord of cursor
MyCursor        dw      0000            ; Raw-Screen location of my cursor

; Structure: X Pos, Y Pos, Slider Start (0=None), Item Count/Slider Length
; Text Start (0=None), Current Pos, Message Table Ptr
; All numbers are '0' based

SMenuTable  STRUC
  XPos       db ?   ; X-Position of starting point of cursor
  YPos       db ?   ; Y-Position of starting point of cursor    
  SliderPos  db ?   ; Slider XPosition, FF = No slider
  ItemCount  db ?   ; # of Items/Slider positions
  TextPos    db ?   ; Text comment XPosition, FF = No text
  CurrentPos db ?   ; Current Item/Slider position    
  UpdateLine db ?   ; Something has changed.  Redraw sliders/text
  MsgPtr     dw ?   ; Location of table of near pointers to text messages
SMenuTable  ENDS

; These are the charge boosts for all charge-based systems!!!!! (In decimal)
; First entry MUST be 00 or it cannot be turned off.
Charge_Tabl db 00, 04, 08, 12, 15, 20, 26, 32, 38, 44, 50

; These are the delays for the missle and laser cycle times (In decimal)
Delay_Tabl dw 000, 220, 200, 180, 160, 140, 120, 100, 080, 060, 040

; Delays for the target lock for missle firing
Trak_Tabl  dw 49Ch, 430h, 3B0h, 330h, 2B0h, 230h, 1B0h, 150h, 100h, 080h, 030h

; Define the menu's slider/text box locations
Menu_Table  db 7 ; Table Length, Actual # - 1
TABLE_START EQU $
            SMenuTable <00, 11, 31, 10, 45, 00, 00, Offset SelMsgs>
            SMenuTable <00, 12, 31, 10, 45, 00, 00, Offset SelMsgs>
            SMenuTable <00, 13, 31, 10, 45, 00, 00, Offset SelMsgs>
            SMenuTable <00, 14, 31, 10, 45, 00, 00, Offset SelMsgs>
            SMenuTable <00, 15, 31, 10, 45, 00, 00, Offset SelMsgs>
            SMenuTable <00, 16, 31, 10, 45, 00, 00, Offset SelMsgs>

            SMenuTable <00, 19, 0FFh, 01, 41, 00, 00, Offset OnOffMsgs>
            SMenuTable <00, 20, 0FFh, 01, 41, 00, 00, Offset OnOffMsgs>
TABLE_END   EQU $

Pallet1     db 15, 10, 60
            db 20, 10, 48
            db 25, 10, 36
            db 30, 10, 24
            db 35, 10, 12

Pallet6     db 27, 51, 10               ; Gradient color table for slider
Pallet7     db 20, 50, 11 
                        
Pallet8     db 35, 52, 10 
            db 44, 53, 09 
            db 54, 54, 09 
            db 53, 44, 09 
            db 52, 35, 09 
            db 51, 25, 09 
            db 50, 17, 10 
            db 50, 10, 11 

Old_6       db 00, 00, 00               ; Storage for original colors to 
Old_7       db 00, 00, 00               ; restore.
Old_8       db 8 dup (00, 00, 00)


SelMsgs     db 20 ; Size of Message
            db 'Normal (Cheat Off) ',00      
            db 'Above Normal       ',00
            db 'Really Above Normal',00
            db 'Kinda High         ',00
            db 'High               ',00
            db 'Very High          ',00
            db 'Unreal             ',00    
            db 'Nuts               ',00
            db 'Insane             ',00
            db 'Near instantaneous ',00
            db 'Instantaneous      ',00

OnOffMsgs   db 6
            db 01,15,'OFF',00
            db 01,11,'ON ',00

Intro_Msg   db 01,02,'Generic Loader Shell v2.00 (c) 1990-1994 Gen. Half-Track, Ltd.',13
            db 01,03,'Patch v',PATCH_REV,', compiled ',??time,' on ',??date,' patching file ',BOOT_ME,CR
            db 01,04,'This patch is NOT to be used in a manner that would violate the rights of',CR
            db 01,05,'the owner of any commercial software!  This patch is PD, distributed AS IS.',CR,CRE
            
Patch_Me    EQU $ + 35
Intr_Msg    db 01,15,'>>Using user interrupt vector 0x6?<<',CR
Ver_Msg     db 01,15,'Auto-Detect TIE Fighter Version: ** N/A **',CRE

IntF_Msg    db 'Unable to find free user interrupt vector (0x60-0x69)  Aborting...',CRE

Menu_Msg    db CR,01,01,'TIE Fighter Fire Control System - (c) 1994 GHT Labs, Ltd.',CR,CR
            
            db 01,10,'SLIDER Controls:',CR
            db       '    Laser  Firing   Rate     :',CR
            db       '    Missle Firing   Rate     :',CR
            db 01,11,'    Shield Recharge Rate     :',CR
            db       '    Laser  Recharge Rate     :',CR
            db       '    Beam   Recharge Rate     :',CR
            db 01,12,'    Half-Trak(tm) Target Lock:',CR,CR
            
            db       'TOGGLES:',CR
            db       '    Unlimited ammo                     :',CR
            db 01,13,'    Dynamic Ammo Cycler [Ctrl+W]       :',CR

            db CR, 24,' ',25,' Select Item   ',27,' ',26,' Adjusts   '
            db '<RETURN> starts   <ESC> quits',CRE

Start_Msg   db 01,05,'Running TIE FIGHTER...',CRE

Cursor      db TIE_FITR,00 
Blank       db '   ',00
SliderChar  db 01,06,'>', 01,07,'>', 01,08,'>', 01,09,'>', 01,10,'>'
            db 01,11,'>', 01,12,'>', 01,13,'>', 01,14,'>', 01,15,'>',00
SliderBlank db 01,10,'..........',00

Code_Seg        Ends
End             Start

