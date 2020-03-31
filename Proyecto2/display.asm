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
hexL equ h'29'
hexH equ h'30'

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
	movwf TRISD				;TRISD como entrada
	bcf STATUS,RP0			;Cambio al banco 0

	call inicia_lcd			;Inicializacion del display

;Seleccion del modo
modo:
	movlw h'01'
	call comando			;Borrado del display
	movf PORTD,0
	movwf dato
	movf PORTA,0			;Lectura del puerto A
	andlw h'03'				;Mascara para descartar bits no usados
	movwf opc				;Guardar opcion registrada
	;Validacion de la entrada
	movf opc,0				;W = opc, opcion ingresada
	btfsc STATUS,Z
	goto hola				;opc = 0
	xorlw h'01'				;Comparacion con 01H			
	btfsc STATUS,Z
	goto nombre				;opc = 1
	movf opc,0
	xorlw h'02'				;Comparacion con 02H			
	btfsc STATUS,Z
	goto hexadecimal		;opc = 2
	movf opc,0
	xorlw h'03'				;Comparacion con 03H
	btfsc STATUS,Z
	goto binario			;opc = 3
	goto otrom

;Rutina para imprimir HOLA
hola:
	movlw h'80'				;Cursor en posicion (1, 1)
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

;Rutina para imprimir nombres
nombre:
	movlw h'80'				;Cursor en posicion (1, 1)
	call comando			;Envia comando al display
	movlw a'S'				;W = S, ascii
	call datos				;Envia caracter al display
	movlw a'A'
	call datos
	movlw a'N'
	call datos
	movlw a'D'
	call datos
	movlw a'R'
	call datos
	movlw a'A'
	call datos
	movlw h'c0'				;Cursor en posicion (1,2)
	call comando
	movlw a'S'				;W = S, ascii
	call datos				;Envia caracter al display
	movlw a'E'
	call datos
	movlw a'R'
	call datos
	movlw a'A'
	call datos
	movlw a'F'
	call datos
	movlw a'I'
	call datos
	movlw a'N'
	call datos
	call retardo_1seg		;Mantiene la señal
	movf PORTA,0			;Lectura del puerto A
	xorlw h'01'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto nombre				;Puerto A en 1
	goto modo				;Puerto A cambio de valor

;Rutina para desplegar valor de entrada en hexadecimal
hexadecimal:
	;Aplicacion de mascaras en los registros
	movlw h'0f'
	movwf hexL
	movlw h'f0'
	movwf hexH
	;Separacion de parte alta y baja
	movf PORTD,0			;Lee el puerto D
	andwf hexL,1			;Guarda la parte baja del registro
	andwf hexH,1			;Guarda la parte alta del registro
	;Ajuste de la parte alta
	rrf hexH,1				;Rotaciones a la derecha
	rrf hexH,1
	rrf hexH,1
	rrf hexH,1
	movf hexL,0
	call ascii				;Obtiene valor ascii de parte baja
	movwf hexL
	movf hexH,0
	call ascii				;Obtiene valor ascii de parte alta
	movwf hexH
	movlw 0x80				;Cursor en el extremo superior derecho
	call comando			;Envia comando al display
	movf hexH
	call datos				;Envia ascii de parte alta al display
	movf hexL
	call datos				;Envia ascii de parte baja al display
	call retardo_1seg		;Mantiene la señal
	movf PORTA,0			;Lectura del puerto A
	xorlw h'02'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto hexadecimal		;Puerto A en 2
	goto modo				;Puerto A cambio de valor

;Rutina para imprimir la entrada en formato binario
binario:
	movf PORTD,0			;Lee puerto D
	movwf dato				;Guarda entrada en dato
	movlw h'80'
	call comando
	movlw d'8'
	movwf contador			;Inicializa contador con 8
verifica:
	btfsc STATUS,Z			;Verifica si se ha llegado a 0
	goto interrupcion		;Contador ha llegado a 0
	btfsc dato,7
	goto es_1				;Bit es 1
	goto es_0				;Bit es 0
es_1:
	movlw a'1'
	call datos
	goto dec_con
es_0:
	movlw a'0'
	call datos
dec_con:
	rlf dato
	decf contador
	goto verifica
interrupcion:	
	call retardo_1seg		;Mantiene la señal
	movf PORTA,0			;Lectura del puerto A
	xorlw h'03'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto binario			;Puerto A en 3
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

;Rutina para obtener el representacion ascii de un caracter
ascii:
	movwf dato
	;Verificar si es mayor a 9
	sublw d'9'
	btfss STATUS,C
	goto mayor9			;Valor mayor a 9
	movf dato,0
	addlw h'30'			;Suma 30 para obtener ascii del numero
	movwf dato
	goto salir
mayor9:
	movf dato,0
	addlw d'55'			;Suma 55 para obtener ascii de A - F
	movwf dato
salir:
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
