;;;;;;Programa Control motor a pasos
;Uso Puerto C
;IN1->C0
;IN2->C1
;IN3->C2
;IN4->C3
;Paso a Paso Unipolar

processor 16f877
include<p16f877.inc>

;Declaracion de constantes a usar
pasos1 equ h'20'
val_1 equ h'21'
val_2 equ h'22'
pasos2 equ h'23'

val1 equ h'25'
val2 equ h'26'
val3 equ h'27'
org 0
	goto inicio   ;Vector Reset
org 5 

inicio:
    ;Limpieza de puertos
	clrf PORTC
	;Configuracion de puertos
	bsf STATUS,RP0
	bcf STATUS,RP1			;Cambio al banco 1
	
	bcf TRISC,0				;bit 0 como salida
	bcf TRISC,1				;bit 1 como salida
	bcf TRISC,2				;bit 2 como salida
	bcf TRISC,3				;bit 3 como salida

	bcf STATUS,RP0			;Cambio al banco 0

;;; Ciclo->4 pasos
;;; Giro rotor->8 ciclos
;;; Reduccion 1:64
;;; Giro completo eje exterior->64 vueltas del rotor
;;; Una revolucion-> 4*8*64=2048 pasos
;Rutina subir elevador
motorArriba:
	movlw d'2'
	movwf pasos2				;pasos=512
loopM2_2:
	movlw d'255'
	movwf pasos1			;pasos=512o
loopM2:
	;Paso 1->AB
	bsf PORTC,0				;A=1
	bsf PORTC,1				;B=1
	bcf PORTC,2				;C=0
	bcf PORTC,3				;D=0
	call retardo_15ms
	;Paso 2->AD
	bsf PORTC,0				;A=1
	bcf PORTC,1				;B=0
	bcf PORTC,2				;C=0
	bsf PORTC,3				;D=1
	call retardo_15ms
	;Paso 3->DC
	bcf PORTC,0				;A=0
	bcf PORTC,1				;B=0
	bsf PORTC,2				;C=1
	bsf PORTC,3				;D=1
	call retardo_15ms
	;Paso 4->CB
	bcf PORTC,0				;A=0
	bsf PORTC,1				;B=1
	bsf PORTC,2				;C=1
	bcf PORTC,3				;D=0
	call retardo_15ms
	
	decfsz pasos1,1
	goto loopM2
	decfsz pasos2,1
	goto loopM2_2

	call stopMotor			;Termino ciclo
	call retardo_1seg
	
;Rutina bajar elevador
motorAbajo:
	movlw d'2'
	movwf pasos2
loopM1_2:
	movlw d'255'
	movwf pasos1				;pasos=512
loopM1:
	;Paso 1->AB
	bsf PORTC,0				;A=1
	bsf PORTC,1				;B=1
	bcf PORTC,2				;C=0
	bcf PORTC,3				;D=0
	call retardo_15ms
	;Paso 2->BC
	bcf PORTC,0				;A=0
	bsf PORTC,1				;B=1
	bsf PORTC,2				;C=1
	bcf PORTC,3				;D=0
	call retardo_15ms
	;Paso 3->CD
	bcf PORTC,0				;A=0
	bcf PORTC,1				;B=0
	bsf PORTC,2				;C=1
	bsf PORTC,3				;D=1
	call retardo_15ms
	;Paso 4->DA
	bsf PORTC,0				;A=1
	bcf PORTC,1				;B=0
	bcf PORTC,2				;C=0
	bsf PORTC,3				;D=1
	call retardo_15ms
	
	decfsz pasos1,1
	goto loopM1
	decfsz pasos2,1
	goto loopM1_2
	
	call stopMotor			;Termino ciclo
	call retardo_1seg


;Rutina detener giro Motor
stopMotor:
	bcf PORTC,0				;A=0
	bcf PORTC,1				;B=0
	bcf PORTC,2				;C=0
	bcf PORTC,3				;D=0
	call retardo_15ms
	return
;Rutina de retardo de 1 segundo
retardo_1seg:
	movlw h'40'
    movwf val1
lp_3:
	movlw h'100'
	movwf val2
lp_2:
	movlw h'120'
 	movwf val3
lp_1:
	decfsz val3
	goto lp_1
	decfsz val2
	goto lp_2
	decfsz val1
	goto lp_3
	return
;Rutina retardo 15 milisegundos
retardo_15ms:
	movlw d'155'
	movwf val_1
bucle_1:
	movlw d'155'
	movwf val_2
bucle_2:
	decfsz val_2,1
	goto bucle_2
	decfsz val_1,1
	goto bucle_1 	
	return 

fin:
end