;****************************************************************************
;*                                                                          *
;*       Authors:     James Bigmore & Ramzan Mulji                          *
;*                                                                          *
;*       Date:        January 1992                                          *
;*                                                                          *
;*       File:        ENGLISH.ASM      Assembly language routine            *
;*                                     to interface to DOS BIOS             *
;*                                                                          *
;*       Descrpt:     This routine restores the English keyboard. It must   *
;*                    only be called if the French keyboard version is      *
;*                    currently installed                                   *
;*                                                                          *
;*       Format:      english <cr>                                          *
;*                                                                          *
;*--------------------------------------------------------------------------*
;*                                                                          *
;*       COPYRIGHT HATFIELD CS2 CONSULTANTS. 1992, ALL RIGHTS RESERVED.     *
;*                                                                          *
;*       This software may not be copied, disclosed or used in any manner   *
;*       without the express written consent of the copyright holder.       *
;*                                                                          *
;****************************************************************************


		page 60,132                    ;Page length/width for listing





;==============================Start of the CODE Segment=====================


code            segment byte public 'code'

		assume  cs:code,ss:stack,ds:dseg




;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x                      THE restore ROUTINE                                 x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


restore         proc    far


		push    bp                      ;Save the stack frame
		mov     bp,sp                   ;Record SP in new BP




;---------------Restore  Original 09h Interrupt Vector Address---------------


		push    es                      ;Save return registers
		push    bx                      ;used by function 35h

		mov     al,60h                  ;Get stored vector address
		mov     ah,35h                  ;for 09h Keyboard Interrupt
		int     21h                     ;from vector 60h

		push    ds                      ;Save return registers
		push    dx                      ;used by function 25h

		mov     ax,es                   ;ES:BX returned by function 35h
		mov     ds,ax                   ;Original segment address
		mov     dx,bx                   ;Original offset address
		mov     al,09h                  ;Restore back into vector 09h
		mov     ah,25h                  ;by using function 25h
		int     21h

		pop     dx                      ;Restore original registers
		pop     ds                      ;used by function 25h

		pop     bx                      ;Restore original registers
		pop     es                      ;used by function 35h




;---------------Inform  User of Success--------------------------------------


		mov     ax,seg replace_mesg     ;Set DS to code segment
		mov     ds,ax
		mov     dx,offset replace_mesg  ;Restoration complete
		mov     ah,09h                  ;message to the user
		int     21h




;---------------Terminate Program and Return to DOS--------------------------


		mov     sp,bp                   ;SP indicates current BP
		pop     bp                      ;Restore original stack frame




		xor     al,al                   ;Set return code to 0
		mov     ah,4ch                  ;Terminate program
		int     21h                     ;and return to COMMAND.COM


restore         endp


;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;x                      END OF restore ROUTINE                              x
;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx




code            ends


;==============================End of CODE Segment===========================




;==============================Start of the STACK Segment====================


stack            segment byte stack  'stack'

		 dw      50h  dup (?)           ;Provide some stack area so prog
						;can terminate and return to DOS
stack            ends


;==============================End of the STACK Segment======================




;==============================Start of DATA Segment=========================


dseg            segment byte 'data'

replace_mesg    db      'English Keyboard Restored',0dh,0ah,'$'

dseg            ends


;==============================End of DATA Segment===========================


		end     restore         ;Inform linker of initial CS:IP


;****************************************************************************
