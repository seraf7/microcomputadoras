;;;Descripcion de puertos;;;
;PORTB bus de datos B0-D0 ... B7-D7
;R/W - GND
;RS - D6
;E - D7
;boton1-D0 ... boton3-D2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
processor 16f877
include <p16f877.inc>

;Declaracion de variables y constantes
s1 equ h'20'
s2 equ h'21'
s3 equ h'22'
piso equ h'23'
 
val1 equ h'24'
val2 equ h'25'
val3 equ h'26'

valor equ h'27'
valor1 equ h'28'
valor2 equ h'29'

boton equ h'30'
giro equ h'31'
giroAnt equ h'32'

contI1 equ H'43'		;Contadores para interrupcion
contI2 equ H'44'

	org 0
		goto inicio
	org 4
		goto interrupcion	;Vector de interrupcion
	org 5

inicio:
	clrf PORTD
	clrf PORTB

	;Configuracion del CAD
	bsf STATUS,RP0
	bcf STATUS,RP1			;Cambio al banco de memoria 0
	clrf TRISB				;Configura TRISB como salida
	movlw b'00000111'		;D7...D3 como salidas
	movwf TRISD				;D2...D0 como entradas
	movlw b'11110000'		;C7...C4 como entradas
	movwf TRISC				;C3...C0 como salidas
	clrf ADCON1				;Se configura el ADCON1 como E/S analógica
	
	;Configuracion de interrupciones
	movlw b'00000111'		;Uso de temporizador
	movwf OPTION_REG		;Predivisor del TMR0 = 256

	bcf STATUS,RP0			;Cambio al banco 0
	bcf INTCON,T0IF			;Limpia bandera de desborde en TMR0
	bsf INTCON,T0IE			;Habilita interrupcion por desbordamiento
	bsf INTCON,GIE			;Habilita interrupciones generales
	
	;Inicializacion de variables
	clrf boton
	clrf giro
	clrf piso 
	clrf contI1				;Limpia contador
	clrf contI2
	clrf PORTB				;Limpia el puerto B

	;Inicializacion del display
	call inicia_lcd

elevador:
	movlw h'01'
	call comando		;Borrado del display
	movlw h'80'				;Cursor al inicio del display
	call comando
	movlw a'E'				;Impresión de mensaje en el display
	call datos
	movlw a'J'				;Impresión de mensaje en el display
	call datos
	movlw a'E'				;Impresión de mensaje en el display
	call datos
	movlw a'C'				;Impresión de mensaje en el display
	call datos
	movlw a'U'				;Impresión de mensaje en el display
	call datos
	movlw a'C'				;Impresión de mensaje en el display
	call datos
	movlw a'I'				;Impresión de mensaje en el display
	call datos
	movlw a'Ó'				;Impresión de mensaje en el display
	call datos
	movlw a'N'				;Impresión de mensaje en el display
	call datos
	call retardo_1seg
	goto elevador

;Rutina de interrupcion
interrupcion:
	btfss INTCON,T0IF		;Verifica estado de T0IF
	goto sal_no_fue_TMR0	;T0IF = 0, no hay desbordamietno
inc1:
	incf contI2
	movlw d'229'			;W = 229
	subwf contI2,W			;W = contI2 - W
	btfss STATUS,Z			;Verifica estado de Z
	goto sal_int			;Z = 1, tiempo limite alcanzado
	call pausa
	clrf contI2
sal_int:
	bcf INTCON,T0IF			;Limpia bandera T0IF, sin desbordamiento
sal_no_fue_TMR0:
	retfie					;Retorna de la interrrupción

pausa:
	movlw h'01'
	call comando		;Borrado del display
	movlw h'83'				;Cursor al inicio del display
	call comando
	movlw a'F'				;Impresión de mensaje en el display
	call datos
	movlw a'U'				;Impresión de mensaje en el display
	call datos
	movlw a'E'				;Impresión de mensaje en el display
	call datos
	movlw a'R'				;Impresión de mensaje en el display
	call datos
	movlw a'A'				;Impresión de mensaje en el display
	call datos
	movlw a' '				;Impresión de mensaje en el display
	call datos
	movlw a'D'				;Impresión de mensaje en el display
	call datos
	movlw a'E'				;Impresión de mensaje en el display
	call datos
	movlw a' '				;Impresión de mensaje en el display
	call datos
	movlw h'c3'				;Cursor en posicion (1,2)
	call comando
	movlw a'S'				;Impresión de mensaje en el display
	call datos
	movlw a'E'				;Impresión de mensaje en el display
	call datos
	movlw a'R'				;Impresión de mensaje en el display
	call datos
	movlw a'V'				;Impresión de mensaje en el display
	call datos
	movlw a'I'				;Impresión de mensaje en el display
	call datos
	movlw a'C'				;Impresión de mensaje en el display
	call datos
	movlw a'I'				;Impresión de mensaje en el display
	call datos
	movlw a'O'				;Impresión de mensaje en el display
	call datos
	call retardo_3seg
	return

;Rutina de inicilizacion del display
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

;Rutina para enviar un comando al display
comando:
	movwf PORTB 
    call ret200
    bcf PORTD,6
    bsf PORTD,7
    call ret200
    bcf PORTD,7
	call ret200
	call ret200
    return

;Rutina para enviar un dato al display
datos:
	movwf PORTB
    call ret200
    bsf PORTD,6
    bsf PORTD,7
    call ret200
    bcf PORTD,7
    call ret200
    call ret200
    return

;Rutina de retardo de 200ms
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

;Rutina de retardo de 100ms
ret100ms:
	movlw 0x03 
	movwf valor
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

;Rutina de retardo de 3 segundo
retardo_3seg:
	movlw h'150'
    movwf val1
lp3:
	movlw h'200'
	movwf val2
lp2:
	movlw h'240'
 	movwf val3
lp1:
	decfsz val3
	goto lp1
	decfsz val2
	goto lp2
	decfsz val1
	goto lp3
	return

	end