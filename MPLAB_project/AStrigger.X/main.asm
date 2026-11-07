#include "p10f200.inc"
    __CONFIG _WDT_OFF & _CP_OFF & _MCLRE_OFF
 
i    EQU   	 10   		 ;Delay register #1
j    EQU   	 11   		 ;Delay register #2
    ORG 0x0000   		 
INIT
    MOVLW ~((1<<T0CS)|(1<<NOT_GPPU))
    OPTION   			 ;Enable GPIO2 and pull-ups
    MOVLW (1 << GP1) | (1 << GP3)
    TRIS GPIO			 ; GP0, GP2 = outputs; GP1, GP3 = inputs
;init fire to 0
    ;BCF GPIO, GP0		 ;reset GP2 (stop fire)
; you know what.. the initial fire cant fire anyway, because the gun is open
; and at least you know the MCU started coretly
    
; Never ending loop    
LOOP
    CALL CHECK_TRIGGER
    CALL CHECK_RESET
    GOTO LOOP
    
  
CHECK_TRIGGER
    BTFSC GPIO, GP0		;Check if GP0 is 0 (trigger is pressed)
    RETLW 0
    CALL DEBOUNCE_DELAY		;If pressed check debounce
    BTFSC GPIO, GP0             ;Check if GP0 is 0 (trigger is pressed)
    RETLW 0
    GOTO FIRE			;If still pressed fire one shot
    
FIRE
    BSF GPIO, GP0		;Set GP0 (Fire)
WAIT_FIRE_CMPLT
    BTFSC GPIO, GP3		;Check if GP3 is 0 (reset is pressed)
    GOTO WAIT_FIRE_CMPLT
    BCF GPIO, GP0		;If pressed reset GP0 (stop fire)

FIRE_CMPLT
    BTFSS GPIO, GP3             ;Check if GP3 is 1 (trigger is not pressed)
    GOTO FIRE_CMPLT			 
    CALL DEBOUNCE_DELAY		;If not pressed check debounce
    BTFSS GPIO, GP3             ;Check if GP3 is 1 (trigger is not pressed)
    GOTO FIRE_CMPLT
    RETLW 0   			;If not pressed return to main loop and wait for next shot
       
    
    
CHECK_RESET
    BTFSC GPIO, GP1		;Check if GP1 is 0 (reset is pressed)
    RETLW 0
    CALL TOGGLE_DELAY		;If pressed check debounce
    BTFSC GPIO, GP1		;Check if GP1 is 0 (reset is pressed)
    RETLW 0
    GOTO AUTOMAT		;If pressed go to automat subroutine (change fire mode)
    
AUTOMAT
    BCF GPIO, GP0		;Reset GP0 (stop fire)
    BTFSC GPIO, GP3		;Check if GP3 is 0 (trigger is pressed)
    GOTO CONTINUE
    CALL DEBOUNCE_DELAY		;If pressed check debounce
    BTFSC GPIO, GP3		;Check if GP3 is 0 (trigger is pressed)
    GOTO CONTINUE
    GOTO AUTO_FIRE		;If pressed fire

CONTINUE
    BTFSS GPIO, GP1		;Check if GP1 is 1 (reset is not pressed)
    GOTO AUTOMAT
    CALL TOGGLE_DELAY		;If not pressed check debounce
    BTFSS GPIO, GP1		;Check if GP1 is 1 (reset is not pressed)
    GOTO AUTOMAT
    RETLW 0			;If not pressed go back to main loop (semi fire mode)

AUTO_FIRE
    BSF GPIO, GP0		;Set GP0 (fire)
    
    BTFSS GPIO, GP3             ;Check if GP3 is 1 (trigger is not pressed)
    GOTO AUTO_FIRE			
    CALL DEBOUNCE_DELAY		;If not pressed check debounce
    BTFSS GPIO, GP3             ;Check if GP3 is 1 (trigger is not pressed)
    GOTO AUTO_FIRE
    GOTO AUTOMAT		;If not pressed return and wait for trigger press

    
    
DEBOUNCE_DELAY   	 ;Start DEBOUNCE_DELAY subroutine here
    MOVLW D'5'                		 ;Load initial value for the delay    
    MOVWF i   			 ;Copy the value to the register i
    MOVWF j   			 ;Copy the value to the register j
DELAY_LOOP   		 ;Start delay loop
    DECFSZ i, F   		 ;Decrement i and check if it is not zero
    GOTO DELAY_LOOP   	 ;If not, then go to the DELAY_LOOP label
    DECFSZ j, F   		 ;Decrement j and check if it is not zero
    GOTO DELAY_LOOP   	 ;If not, then go to the DELAY_LOOP label
    RETLW 0   			 ;Else return from the subroutine
 
TOGGLE_DELAY   		 ;Start TOGGLE_DELAY subroutine here
    MOVLW D'40'   	             ;Load initial value for the delay    
    MOVWF i   			 ;Copy the value to the register i
    MOVWF j   			 ;Copy the value to the register j
DELAY_LOOP1   		 ;Start delay loop
    DECFSZ i, F   		 ;Decrement i and check if it is not zero
    GOTO DELAY_LOOP1       ;If not, then go to the DELAY_LOOP1 label
    DECFSZ j, F   		 ;Decrement j and check if it is not zero
    GOTO DELAY_LOOP1       ;If not, then go to the DELAY_LOOP1 label
    RETLW 0   			 ;Else return from the subroutine
 
    END