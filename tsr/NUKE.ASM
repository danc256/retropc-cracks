;; ***** SUBSTUTITION MACROS *****

CR        EQU  10, 13
CRE       EQU  10, 13, '$'
DELETE    EQU  5300h
SPACE     EQU  ' '
FCBStart  EQU  55h
ParamLen  EQU  80h
ParamBuf  EQU  81h
FCBAttr   EQU  Byte Ptr DS:[05Bh]
ATTRDIR   EQU  0FFh
ATTRNDIR  EQU  0EFh
PARENTDIR EQU  ' .'
DTAFName  EQU  Word Ptr DS:[088h]

;; ***** MULTI-LINE MACROS *****

@DosPrint MACRO Message
Mov     DX, Offset Message
Mov     AH, 09h
Int     21h
ENDM

;; ***** STRUCTURES *****

S_FCB     STRUC
  Extended  db         (0)
  Reservd1  db  5  dup (0)
  Attrib    db         (0)
  Drive     db         (0)
  FileName  db  11 dup (0)
  Reservd2  db  25 dup (0)
  S_End     EQU $ - 01h
S_FCB     ENDS

S_TEMP    STRUC
  OverRide     db         (0)
  CurrentDrive db         (0)          
  CurrentDir   db 128 dup (0)
  WorkingLen   dw         (0)
  WorkingDrive db         (0) 
  AsciiDrive   db         (0)                   
               db         (0)  ;; Store a ':' here....
  WorkingDir   db 128 dup (0)
  SubOffset    dw         (0)
S_TEMP    ENDS

;; ***** CODE *****

Code_Seg        Segment
                Assume  CS: Code_Seg, DS: Code_Seg

                Org     FCBStart                ; Overlay a structure over
                FCB     S_FCB ?                 ; the PSP FCB #1

                Org     100h                    ; .COM file starts at 100h
Start:
                Jmp     Main                    ; Go to start of code

;; ***** STATIC DATA *****

                FCB_DATA     db 0FFh            ; Extended FCB
                             db 05 dup (00)     ; Reserved
                             db 0EFh            ; Attributes (All but DIR)
                             db 00h             ; DEFAULT drive selected
                             db 11 dup ('?')    ; WildCard Mask (*.*)
                DATALEN      EQU $-FCB_DATA     ; Size of Data Field

                DirLevel     db 01              ; Current nesting level in dir
                BackUp       db '..',00         ; Used to back-up 1 dir level

;; ***** PROCEDURES *****


Init            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                @DosPrint M_Banner                  ; Credits ('natch)    

                Cld
                Xor     AX, AX
                Mov     DI, Offset Tmp
                Mov     CX, TEMP_SIZE
                Rep     Stosw

                Mov     Tmp.CurrentDir,   '\'                 
                Mov     Tmp.AsciiDrive+1, ':'
                Mov     AH, 47h                     ; Store current dir
                Xor     DL, DL                      ; to be restored later
                Mov     SI, Offset Tmp.CurrentDir+1
                Int     21h

                Mov     AH, 19h                     ; Get current drive
                Int     21h

                Mov     Tmp.CurrentDrive, AL        ; Store current
                Mov     Tmp.WorkingDrive, AL        ; drive
                Add     AL, 'A'
                Mov     Tmp.WorkingDrive+1, AL      ; Default drive

                Xor     BH, BH                      ; Put a space at the end    
                Mov     BL, DS:[ParamLen]           ; of the command line    
                Mov     Word Ptr DS:[BX+ParamBuf], 20h ; for ease of parsing

                Ret
Init            Endp


Print_String    Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     DX, DI          ; Store start of string
                Cld                     ; Clear Direction flag
                Mov     CX, 0FFFFh      ; Set counter
                Mov     AX, 4000h       ; Set up search & Dos call
                Repne   Scasb           ; Loop
                Not     CX              ; Flip the bits & 
                Dec     CX              ; remove 1 = length of string

                Mov     BX, 01          ; Standard Output
                Int     21h

                Ret
Print_String    Endp


StrLen          Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                ; Given ASCIIZ string in ES:DI, returns length in CX

                Cld
                Mov     CX, 0FFFFh
                Xor     AL, AL
                Repne   Scasb
                Not     CX
                Dec     CX

                Ret
StrLen          Endp


CommandLine     Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Cmp     Byte Ptr DS:[ParamLen], 00
                Je      CL_Fail                  ; No parameters specified

                Mov     SI, ParamBuf             ; Start of command line
                Cld
CL_ScanLoop:               
                Lodsb
                Cmp     AL, ' '
                Je      CL_ScanLoop              ; Eat spaces
                Or      AL, AL
                Je      CL_Done                  ; End of line

                Cmp     AL, '/'                  ; Option?
                Je      CL_Options               ; Yes, process it
                                                 
                Dec     SI
                Cmp     Byte Ptr [SI+01h], ':'   ; No, Must be a filename
                Mov     Tmp.SubOffset, SI
                Jne     CL_NoDrive               ; DRIVE not specified
                
                Cmp     AL, 'A'
                Jb      CL_Fail
                Cmp     AL, 'z'
                Ja      CL_Fail
                And     AL, 0DFh                 ; Make sure it was valid
                Mov     Tmp.AsciiDrive, AL
                Sub     AL, 'A'                  ; & store it
                Mov     Tmp.WorkingDrive, AL
                Inc     SI
                Inc     SI
CL_NoDrive:
                Push    SI
                Mov     DI, SI
                Mov     CX, 0FFFFh
                Mov     AL, ' '
                Repne   Scasb                    ; Copy path name to buffer
                Not     CX
                Dec     CX
                Pop     SI
                Mov     DI, Offset Tmp.WorkingDir
                Rep     Movsb
                Jmp     CL_ScanLoop
CL_Options:
                Lodsb                            ; Process options
                Cmp     AL, 'o' 
                Je      CL_OverRide
                Cmp     AL, 'O'
                Jne     CL_Unknown
CL_OverRide:
                Mov     Tmp.OverRide, 01
CL_Unknown:
                Jmp     CL_ScanLoop
CL_Fail:                
                @DosPrint M_Usage                ; Parse error
                Mov     AX, 0001
                Ret
CL_Done:
                Cmp     Tmp.WorkingDir, 00       ; No filename
                Je      CL_Fail

                Xor     AX, AX                   ; No errors
                Ret     
CommandLine     Endp


Confirm         Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     AH, 0Eh
                Mov     DL, Tmp.WorkingDrive
                Int     21h                      ; Log on target drive

                Mov     AH, 19h                  ; Get current drive
                Int     21h

                Cmp     AL, DL                   ; Do they match?
                Jne     C_BadDrive               ; No, abort

                Mov     AH, 3Bh                  ; Set current directory
                Mov     DX, Offset Tmp.WorkingDir
                Int     21h
                Jc      C_BadDir                 ; Error setting dir

                Mov     AH, 47h
                Xor     DL, DL
                Mov     SI, Offset Tmp.WorkingDir+1
                Int     21h
                Mov     Tmp.WorkingDir, '\'

                Mov     DI, Offset Tmp.WorkingDir ; Store length of dir name
                Call    StrLen
                Mov     Tmp.WorkingLen, CX

                Cmp     Tmp.OverRide, 01
                Je      C_Continue
                Mov     DI, Offset Tmp.AsciiDrive
                Call    Print_String             ; Print name of current dir
                @DosPrint M_Verified             ; and DELETE message

                Xor     AH, AH
                Int     16h                      ; Get keypress

                Cmp     AX, DELETE
                Jne     C_Skip                   ; Abort
C_Continue:
                Xor     AX, AX                   ; Nuke it
                Ret
C_BadDrive:
                @DosPrint M_InvalidDrive         ; Invalid drive
                Jmp     C_Skip
C_BadDir:
                Mov     DI,  Tmp.SubOffset
                Call    Print_String             ; Directiory not found
                @DosPrint M_NotFound
C_Skip:                
                Mov     AX, 0001h                ; Process aborted 
                @DosPrint M_Aborted              ; (DELETE not pressed)
                Ret
Confirm         Endp


Nuke            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Mov     SI, Offset FCB_DATA     ; Setup FCB (Wildcards,
                Mov     DI, Offset FCB          ; Attributes, current drive)
                Mov     CX, DATALEN             ; (Only need to do this once)
                Rep     Movsb                   ; Initalize FCB
NU_Start:
                Mov     DX, Offset FCB          ; Nuke current directory
                Mov     AH, 13h                 ; Except for DIRECTORIES
                Int     21h                     ; (IE DEL *.*)

                Mov     FCB.Attrib, ATTRDIR     ; Search for DIRECTORIES
                Mov     AH, 11h                 
                Int     21h                     ; Any Directories?  (FFh = No)

                Inc     AL
                Jnz     NU_More                 ; No (ONLY ROOT COULD DO THIS)
                Jmp     NU_Done
NU_More:
                Cmp     DTAFName, PARENTDIR     ; Parent dir?
                Jne     NU_NotParent            ; Nope, (Must be root)

                Mov     AH, 12h                 ; Eat '..' directory
                Int     21h
NU_FindNext:
                Int     21h
                Inc     AL
                Jz      NU_NoDirs               ; Empty dir (only parents)
NU_NotParent:                                   
                Std
                Push    SP
                Pop     DI
                Dec     DI
                Dec     DI
                Sub     SP, 26
                Mov     CX, 13
                Mov     SI, Offset FCB.S_End    ; End of FCB
                Rep     Movsw
                Inc     DirLevel                ; Increase nesting count

                Mov     Byte Ptr DS:[0093h], 00 ; Make dir ASCIIZ

                Mov     AH, 3Bh                 ; Make this the current dir
                Mov     DX, 0088h
                Int     21h

                Mov     AH, 47h                 ; Update WORKINGDIR
                Xor     DL, DL
                Mov     SI, Offset Tmp.WorkingDir+1
                Push    SI
                Int     21h
                Pop     DI
                Call    StrLen
                Mov     Tmp.WorkingLen, CX
                Mov     FCB.Attrib, ATTRNDIR    ; MAKE SURE Dirs aren't 
                Jmp     NU_Start                ; deleted w/o emptying them!
NU_NoDirs:
                Mov     DI, Tmp.WorkingLen      ; Size of current dir's name
                Add     DI, Offset Tmp.WorkingDir
                Mov     CX, 0FFFFh
                Std
                Mov     AL, '\'                   ; Find previous dir (if any)
                Repne   Scasb
                Not     CX
                Sub     Tmp.WorkingLen, CX
                Inc     DI
                Mov     Byte Ptr [DI], 00
                Inc     DI
                                     
                Mov     AH, 3Bh                 ; Backup 1 directory level
                Mov     DX, Offset BackUp
                Int     21h
                Jc      NU_Done                 ; Root dir, can't go any lower

                Mov     DX, DI                  ; Pointer to Dirname
NU_TryAgain:                
                Mov     AH, 3Ah                 ; Delete that directory
                Int     21h
                Jnc     NU_Continue

                Cmp     AX, 06                  ; Directory couldn't be 
                Jb      NU_Error                ; removed...

                Mov     AX, 4301h               ; Set its attributes to 0
                Xor     CX, CX
                Mov     DX, DI
                Int     21h
                Jnc     NU_TryAgain
NU_Continue:
                Dec     DirLevel
                Jz      NU_Done
                
                Push    SP                      ; Restore FBC
                Pop     SI
                Mov     DI, Offset FCB.Reservd2
                Cld
                Mov     CX, 13
                Rep     Movsw
                Add     SP, 26
                
                Mov     AH, 12h                 ; Next dir after '..' (If any)
                Mov     DX, Offset FCB          ; Location of extended FCB
                Jmp     NU_FindNExt             ; Find next dir
NU_Done:        
                Xor     AX, AX                  ; Pass (successful deletion)
                Ret
NU_Error:
                Mov     AX, 0001                ; Fail (Couldn't remove a dir)
                Ret
Nuke            Endp


Done            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg

                Mov     AH, 0Eh                          ; Restore current
                Mov     DL, Tmp.CurrentDrive             ; Drive
                Int     21h

                Mov     AH, 3Bh                          ; And current Dir
                Mov     DX, Offset Tmp.CurrentDir
                Int     21h

                @DosPrint M_DoneMsg                       ; Print "DONE."

                Ret
Done            Endp


Main            Proc    Near
                Assume  CS: Code_Seg, DS: Code_Seg
                
                Call    Init            ; Setup stuff & print banner
                Call    CommandLine     ; Parse command line
                Or      AX, AX          ; Valid command line?
                Jnz     M_Terminate     ; Nope, abort
                
                Call    Confirm         ; Are you sure you wanna do this?
                Or      AX, AX
                Jnz     M_NoErrors      ; No, abort
                Call    Nuke            ; Yes, start deleting
M_Done:
                Or      AX, AX
                Jz      M_NoErrors
                @DosPrint M_ErrorInNuke
M_NoErrors:
                Call    Done            ; Tidy up
M_Terminate:
                Mov     AH, 4Ch         ; Quit
                Int     21h
Main            Endp

M_Banner        db 'Nuke v1.50 - SubDirectory deletion utility',CR
                db '(c) 1991, 1992 Gen. Half-Track  Written in Turbo Assembly',CR,CRE
M_Usage         db 'USAGE: NUKE dirname [/O]', CR
                db 'Switches:  O = Override "ARE YOU SURE?" prompt',CRE
M_InvalidDrive  db '**ERROR: An invalid DRIVE was specified!', CRE                
M_NotFound      db ' not found.',CRE
M_Verified      db ' will be erased!',CR
                db 'Are you sure you want to do this? (DELETE to confirm, any other key aborts)',CRE
M_Aborted       db 'Program aborted...',CRE
M_DoneMsg       db 'Done.',CRE
M_ErrorInNuke   db 'An unknown error has occured...',CRE

                Org     $
                Tmp     S_TEMP ?
                TEMP_SIZE       EQU ($ - Tmp+1) Shr 1

Code_Seg        Ends
End             Start
