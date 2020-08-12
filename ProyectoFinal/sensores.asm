processor 16f877
include <p16f877.inc>

s1 equ h'20'
s2 equ h'21'
s3 equ h'22'
piso equ h'23'

val1 equ h'24'
val2 equ h'25'
val3 equ h'26'

	org 0
	goto inicio
	org 5

inicio:
	;Configuracion del CAD
	bsf STATUS,RP0
	bcf STATUS,RP1			;Cambio al banco de memoria 0
	clrf TRISB				;Configura TRISB como salida
	clrf ADCON1				;Se configura el ADCON1 como E/S analógica
	bcf STATUS,RP0			;Cambio al banco de memoria 1
	clrf PORTB				;Limpia el puerto B

sensores:
	call leer_sensores
	movf s1,W				;W = s1
	sublw h'10'				;W = 10 - s1
	btfsc STATUS,C			;Verificamos valor del carry
	bsf piso,0				;C = 1, 10 >= s1, linea negra
	movf s2,W				;W = s2
	sublw h'10'				;W = 10 - s2
	btfsc STATUS,C			;Verificamos valor del carry
	bsf piso,1				;C = 1, 10 >= s2, linea negra
	movf s3,W				;W = s3
	sublw h'10'				;W = 10 - s3
	btfsc STATUS,C			;Verificamos valor del carry
	bsf piso,2				;C = 1, 10 >= s3, linea negra
	movf piso,W				;W = piso
	movwf PORTB				;PORTB = piso
	call retardo_1seg
	goto sensores

;Rutina para realizar la lectura de los sensores
leer_sensores:
	movlw b'11000001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 0, activación del CAD
	call conversion
	movwf s1				;s1 = valor sensor 1
	movlw b'11001001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 1, activación del CAD
	call conversion
	movwf s2				;s2 = valor sensor 2
	movlw b'11010001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 2, activación del CAD
	call conversion
	movwf s3				;s3 = valor sensor 3
	return

;Rutina para realizar la conversion del valor analogico
conversion:
	bsf ADCON0,2			;Inicia la convercion
espera:
	btfsc ADCON0,2			;Verifica si ha terminado la conversion
	goto espera				;Va a espera si la conversion continua
	movf ADRESH,W			;W = valor convertido
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