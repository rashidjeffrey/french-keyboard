;****************************************************************************
;*                                                                          *
;*      Authors:        James Bigmore & Ramzan Mulji                        *
;*                                                                          *
;*      Date:           January 1992                                        *
;*                                                                          *
;*      File:           FRANCAIS.ASM            Assembly lanuage routine    *
;*                                              to interface to DOS BIOS    *
;*                                                                          *
;*      Descrpt:        This program sets up a French keyboard emulator.    *
;*                      It is a TSR handler, but normal key processing can  *
;*                      be resumed by calling the ENGLISH.EXE restore prog. *
;*                                                                          *
;*      Format:         francais <cr>                                       *
;*                                                                          *
;*--------------------------------------------------------------------------*
;*                                                                          *
;*      COPYRIGHT HATFIELD CS2 CONSULTANTS. 1992, ALL RIGHTS RESERVED.      *
;*                                                                          *
;*      This software may not be copied, disclosed or used in any manner    *
;*      without the express written consent of the copyright holder.        *
;*                                                                          *
;****************************************************************************


		page 60,132                     ;Page length/width for listing


;==============================Start of CODE segment==========================


cseg            segment byte public 'code'


		assume  cs:cseg,ss:stack,ds:dseg




;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x                            START OF install ROUTINE                      x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


install         proc    far


		jmp     set_vector              ;Jump to routine which sets up
						;new handler & exits as TSR




;-----------------------Initialisation of constants--------------------------


		;------------Miscellaneous constants------------

kbd_port        equ     60h             ;Keyboard port number

no_of_recs      equ     2fh             ;Number of key translations in table

release_test    equ     80h             ;Most sig. bit = 1

rec_length      equ     5h              ;No of fields in a table record


		;------------Special Key Scan Codes ------------

return_scan_co  equ     1ch
bk_spc_scan_co  equ     0eh
shift_scan_co   equ     2ah
ctrl_scan_co    equ     1dh
alt_scan_co     equ     38h
hat_scan_co     equ     1ah


		;------------Special Key press/release flags----

flag_off        equ     00h
flag_on         equ     01h


;-----------------------Initialisation of key translation table--------------

;               Format of fields in a record:

;               SCAN CODE , NORMAL ASCII , SHIFT ASCII, CTRL ASCII , ALT ASCII


table           db      02h,'&','1',00h,00h             ;Numeric keys
		db      03h,82h,'2',00h,'~'
		db      04h,'"','3',00h,'#'
		db      05h,27h,'4',00h,'{'
		db      06h,'(','5',00h,'['
		db      07h,15h,'6',1eh,'|'
		db      08h,8ah,'7',00h,'`'
		db      09h,'!','8','\','\'
		db      0ah,87h,'9',00h,'^'
		db      0bh,85h,'0',00h,'@'
		db      0ch,')','ø',00h,00h
		db      0dh,'-','_','_',00h


		db      10h,'a','A',01h,00h             ;Non Numeric keys
		db      11h,'z','Z',1ah,00h
		db      12h,'e','E',05h,00h
		db      13h,'r','R',12h,00h
		db      14h,'t','T',14h,00h
		db      15h,'y','Y',19h,00h
		db      16h,'u','U',15h,00h
		db      17h,'i','I',09h,00h
		db      18h,'o','O',0fh,00h
		db      19h,'p','P',10h,00h
		db      1bh,'$','œ',1dh,00h
		db      1eh,'q','Q',11h,00h
		db      1fh,'s','S',13h,00h
		db      20h,'d','D',04h,00h
		db      21h,'f','F',06h,00h
		db      22h,'g','G',47h,00h
		db      23h,'h','H',08h,00h
		db      24h,'j','J',0ah,00h
		db      25h,'k','K',0bh,00h
		db      26h,'l','L',0ch,00h
		db      27h,'m','M',0dh,00h
		db      28h,60h,'%',00h,00h
		db      2ch,'w','W',17h,00h
		db      2dh,'x','X',18h,00h
		db      2eh,'c','C',03h,00h
		db      2fh,'v','V',16h,00h
		db      30h,'b','B',02h,00h
		db      31h,'n','N',0eh,00h
		db      32h,',','?',00h,00h
		db      33h,';','.',00h,00h
		db      34h,':','/',00h,00h
		db      35h,'=','+',00h,00h


		db      39h,20h,00h,00h,00h             ;Space


		db      01h,1bh,00h,00h,00h             ;Escape



;-----------------------Special Key Status Flags-----------------------------

hat_status      db      00h
shift_status    db      00h
ctrl_status     db      00h
alt_status      db      00h




;---------------Local procedure to send special char to buffer----------------


spec_disp       proc    near
		push    ax                      ;Save registers used by proc

		mov     ah,05h                  ;Reg. al contains ASCII value
		int     16h                     ;Display translated key

		pop     ax
		ret                             ;and return to caller
spec_disp       endp




;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x              THE START OF THE FRENCH KEYBOARD HANDLER FOR INT. 09h       x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


french_hdlr:    pushf                   ;Save registers used by handler
		push    ax
		push    bx
		push    cx
		push    dx
		push    si




;-----------------------Read Scan Code from the Port--------------------------


		cli                     ;Disable interrupts
		in      al,kbd_port     ;Read key scan code from keyboard port
		jmp     $+2             ;Does nothing
		jmp     $+2             ;Allow time for port read if fast
		jmp     $+2             ;processor is in use
		sti                     ;Enable interrupts



;-----------------------Test for Key Release---------------------------------


		test    al,release_test         ;Is it a key release?
		jz      hat                     ;NO. Test which key pressed




;-----------------------Test Released Key against Flags--------------------


hat_release:    mov     dl,al                   ;Copy scan code into reg. DL
		xor     dl,hat_scan_co          ;because XOR destroys value
		cmp     dl,release_test         ;Hat (^) released?
		jne     shift_release           ;NO. Test for shift release
		mov     hat_status,flag_off     ;YES. Reset hat status
		jmp     end_of_int


shift_release:  mov     dl,al                   ;Copy scan code into reg. DL
		xor     dl,shift_scan_co        ;because XOR destroys value
		cmp     dl,release_test         ;Shift released?
		jne     ctrl_release            ;NO. Test for control release
		mov     shift_status,flag_off   ;YES. Reset shift status
		jmp     end_of_int


ctrl_release:   mov     dl,al                   ;Copy scan code into reg. DL
		xor     dl,ctrl_scan_co         ;because XOR destroys value
		cmp     dl,release_test         ;Control released?
		jne     alt_release             ;NO. Test for alt
		mov     ctrl_status,flag_off    ;YES. Reset control status
		jmp     end_of_int


alt_release:    mov     dl,al                   ;Copy scan code into reg. DL
		xor     dl,alt_scan_co          ;because XOR destroys value
		cmp     dl,release_test         ;Alt released?
		jne     norm_release            ;NO. Release is a normal key
		mov     alt_status,flag_off     ;YES. Reset alt status
norm_release:   jmp     end_of_int




;-----------------------Process Special Key Combinations---------------------


hat:            cmp     al,hat_scan_co          ;Hat?
		jne     shift                   ;NO. Test for shift
		mov     hat_status,flag_on      ;YES. Set hat flag
		jmp     end_of_int


shift:          cmp     al,shift_scan_co        ;Shift?
		jne     ctrl                    ;NO. Test for control
		mov     shift_status,flag_on    ;YES. Set shift flag
		mov     ch,shift_scan_co        ;Send shift
		mov     cl,00h                  ;00h indicates extended code
		call    spec_disp
		jmp     end_of_int


ctrl:           cmp     al,ctrl_scan_co         ;Control?
		jne     alt                     ;NO. Test for alt
		mov     ctrl_status,flag_on     ;YES. Set control flag
		mov     ch,ctrl_scan_co         ;Send ctrl
		mov     cl,00h                  ;00h indicates extended code
		call    spec_disp
		jmp     end_of_int


alt:            cmp     al,alt_scan_co          ;Alt?
		jne     return                  ;NO. Test for return
		mov     alt_status,flag_on      ;YES. Set alt flag
		mov     ch,alt_scan_co          ;Send alt
		mov     cl,00h                  ;00h indicates extended code
		call    spec_disp
		jmp     end_of_int


return:         cmp     al,return_scan_co       ;Return?
		jne     bk_spc                  ;NO. Test for back space
		mov     ch,return_scan_co
		mov     cl,0dh                  ;YES. Send carriage return
		call    spec_disp
		mov     cl,0ah                  ;Send line feed
		call    spec_disp
		jmp     end_of_int


bk_spc:         cmp     al,bk_spc_scan_co       ;Backspace?
		jne     norm                    ;NO. Must be a normal key
		mov     ch,bk_spc_scan_co
		mov     cl,08h                  ;YES. Send Backspace
		call    spec_disp
		mov     cl,00h                  ;Send NULL
		call    spec_disp
		jmp     end_of_int




;-----------------------Process Normal Keys----------------------------------


norm:           lea     si,table                ;Load table address
		mov     cx,no_of_recs           ;Initialise loop count
		cmp     cx,0                    ;End of loop?
cycle:          jz      end_of_int              ;YES.Terminate interrupt service
		mov     bl,cs:byte ptr[si]      ;NO. Get scan code from table
		cmp     al,bl                   ;Same as code from port?
		je      test_hat_stat           ;YES. Test special key flags
		add     si,rec_length           ;Move along table by 1 record
		dec     cx                      ;Decrement loop count
		jmp     cycle                   ;Loop again




test_hat_stat:  cmp     hat_status,flag_on      ;Is the key 'hatted'?
		jne     test_shift_stat         ;NO. Maybe it's shifted


hatted_a:       cmp     al,10h                  ;YES. Is it an 'a'?
		jne     hatted_e
		mov     cl,83h
		jmp     display


hatted_e:       cmp     al,12h                  ;Is it an 'e'?
		jne     hatted_i
		mov     cl,88h
		jmp     display


hatted_i:       cmp     al,17h                  ;Is it an 'i'?
		jne     hatted_o
		mov     cl,8ch
		jmp     display


hatted_o:       cmp     al,18h                  ;Is it an 'o'?
		jne     hatted_u
		mov     cl,93h
		jmp     display


hatted_u:       cmp     al,16h                  ;Is it a 'u'?
		jne     test_shift_stat
		mov     cl,96h
		jmp     display




test_shift_stat:cmp     shift_status,flag_on    ;Is the key shifted?
		jne     test_ctrl_stat          ;NO. Maybe it's controlled
		mov     cl,cs:byte ptr[si]+2    ;YES. Obtain shifted ASCII
		jmp     display                 ;code version, then display


test_ctrl_stat: cmp     ctrl_status,flag_on     ;Is the key controlled?
		jne     test_alt_stat           ;NO. Maybe it's alted
		mov     cl,cs:byte ptr[si]+3    ;YES. Obtain controlled ASCII
		jmp     display                 ;code version, then display


test_alt_stat:  cmp     alt_status,flag_on      ;Is the key alted?
		jne     normal_char             ;NO. Must be a normal char
		mov     cl,cs:byte ptr[si]+4    ;YES. Obtain alted ASCII
		jmp     display                 ;code version, then display


normal_char:    mov     cl,cs:byte ptr[si]+1    ;Obtain normal key ASCII
						;code from the table


display:        mov     ch,al                   ;Put scan code in reg. ch
		mov     ah,05h
		int     16h                     ;Send French char to buffer




;-----------------------Terminate handle of interrupt-----------------------


end_of_int:     mov     al,20h                  ;To signify end of interrupt
		out     20h,al                  ;inform 8259 Int. controller
						;at port 20h



		pop     si                      ;Restore registers values
		pop     dx
		pop     cx
		pop     bx
		pop     ax
		popf

		iret                            ;Return from interrupt service


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x              THE END OF THE FRENCH KEYBOARD HANDLER FOR INT. 09h         x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx




;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x              THE START OF THE NEW INT. 09h HANDLER SET UP CODE           x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


set_vector:     push    bp                      ;Save the stack frame
		mov     bp,sp                   ;Record SP in new BP




		push    es                      ;Save return registers
		push    bx                      ;used by function 35h


		mov     al,09h                  ;Get keyboard interrupt
		mov     ah,35h                  ;09h vector address
		int     21h

		push    ds                      ;Save return registers
		push    dx                      ;used by function 25h

		mov     ax,es                   ;ES:BX returned
		mov     ds,ax                   ;New segment address
		mov     dx,bx                   ;New offset address
		mov     al,60h                  ;Store at vector 60h
		mov     ah,25h                  ;NOTE: 60h not used by DOS
		int     21h

		pop     dx                      ;Restore original registers
		pop     ds                      ;used by function 25h

		pop     bx                      ;Restore original registers
		pop     es                      ;used by function 35h




		push    ds                      ;Save return registers
		push    dx                      ;used by function 25h


		mov     ax,seg french_hdlr
		mov     ds,ax                   ;New segment address
		mov     dx,offset french_hdlr   ;New offset address
		mov     al,09h                  ;Store at vector 09h
		mov     ah,25h
		int     21h                     ;09h hdlr is now french_hdlr


		pop     dx                      ;Restore original registers
		pop     ds                      ;used by function 25h




		mov     ax,seg install_mesg     ;Set DS to segment
		mov     ds,ax
		mov     dx,offset install_mesg  ;Installation complete
		mov     ah,09h                  ;message to user
		int     21h




		mov     sp,bp                   ;SP indicates original BP
		pop     bp                      ;Restore original BP




		mov     dx,offset set_vector    ;Terminate but stay resident
		xor     al,al
		mov     ah,31h
		int     21h


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x              THE END OF THE NEW INT. 09h HANDLER SET UP CODE             x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


install         endp


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x                      END OF install ROUTINE                              x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx




cseg            ends


;=============================End of CODE segment============================




;=============================Start of STACK segment=========================


stack           segment byte stack  'stack'

		dw      50h  dup (?)

stack           ends


;==============================End of STACK segment===========================




;==============================Start of DATA segment==========================


dseg            segment byte 'data'

install_mesg    db      'French Keyboard Installed',0dh,0ah,'$'

dseg            ends


;==============================End of DATA segment============================



		end     install


;****************************************************************************
