;;;;;;;;;;;;;;;;
;Descripcion de puertos
;;;;;;;;;;;;;;;;
; PORTB bus de datos B0-D0 ... B7-D7
; RS - E0
; E - E1
; R/W - GND
; PORTA seleccion A0-S1 ... A3-S4
; PORTD informacion D0-S1 ... D7-S8

processor 16f877
include<p16f877.inc>

;Declaracion de constantes a usar 
valor equ h'20'
valor1 equ h'21'
valor2 equ h'22'
contador equ h'23'
dato equ h'24'

val1 equ h'25'
val2 equ h'26'
val3 equ h'27'

opc equ h'28'

    org 0
    goto inicio
	org 5

inicio:
	;Limpieza de puertos
	clrf PORTE
	clrf PORTB
	clrf PORTA
	clrf PORTD
	;Configuracion de puertos
	bsf STATUS,RP0
	bcf STATUS,RP1			;Cambio al banco 1
	clrf TRISB				;TRISB como salida
	movlw 0x07
	movwf ADCON1			;Uso digital del registro
	clrf TRISE				;TRISE como salida
	movlw h'ff'
	movwf TRISA				;TRISA como entrada
	bcf STATUS,RP0			;Cambio al banco 0

	call inicia_lcd			;Inicializacion del display

;Seleccion del modo
modo:
	movlw h'01'
	call comando			;Borrado del display
	movf PORTA,0			;Lectura del puerto A
	andlw h'03'				;Mascara para descartar bits no usados
	movwf opc				;Guardar opcion registrada
	;Validacion de la entrada
	movf opc,0				;W = opc, opcion ingresada
	btfsc STATUS,Z
	goto hola				;opc = 0
	goto otrom

;Rutina para imprimir HOLA
hola:
	movlw h'80'				;Cursor en el extremo superior derecho
	call comando			;Envia comando al display
	movlw a'H'				;W = H, ascii
	call datos				;Enviar caracter al display
	movlw a'O'				;W = O, ascii
	call datos
	movlw a'L'
	call datos
	movlw a'A'
	call datos
	call retardo_1seg		;Mantiene la señal
	movf PORTA,0			;Lectura del puerto A
	xorlw h'00'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto hola				;Puerto A en 0
	goto modo				;Puerto A cambio de valor

;Envio de datos al display 
otrom:
	movlw 0x80				;Cursor en el extremo superior derecho
	call comando			;Envia comando al display
	movlw a'F'				;W = 46H
	call datos				;Envia datos al display
	movlw a'I'				;W = 49H
	call datos
	call retardo_1seg		;Mantiene la señal
	goto modo
   
;Rutina de incializacion del display
inicia_lcd:
	movlw 0x30
    call comando
    call ret100ms
    movlw 0x30
    call comando
    call ret100ms
    movlw 0x38
    call comando
    movlw 0x0c
    call comando
    movlw 0x01
    call comando
    movlw 0x06 
    call comando
    movlw 0x02
    call comando
    return

;Rutina para enviar comando al display
comando:
	movwf PORTB 
    call ret200
    bcf PORTE,0
    bsf PORTE,1
    call ret200
    bcf PORTE,1
	call ret200
	call ret200
    return

;Rutina para enviar datos al display
datos:
	movwf PORTB
    call ret200
    bsf PORTE,0
    bsf PORTE,1
    call ret200
    bcf PORTE,1
    call ret200
    call ret200
    return

;Rutina de retardo de 200 milisegundos
ret200:
	movlw 0x02
    movwf valor1 
loop:
	movlw d'164'
    movwf valor
loop1:
	decfsz valor,1
    goto loop1
    decfsz valor1,1
    goto loop
    return

;Rutina de retardo de 100 milisegundos
ret100ms:
	movlw 0x03 
rr  movwf valor
tres:
	movlw 0xff
 	movwf valor1
dos:
	movlw 0xff
 	movwf valor2
uno:
	decfsz valor2
	goto uno
	decfsz valor1
	goto dos
	decfsz valor
	goto tres
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
	
	end
