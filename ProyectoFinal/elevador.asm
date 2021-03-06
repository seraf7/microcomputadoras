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

pasos1 equ h'32'
val_1 equ h'33'
val_2 equ h'34'
pasos2 equ h'35'

contI1 equ H'36'		;Contadores para interrupcion
contI2 equ H'37'

giroAnt equ h'38'

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
	clrf ADCON1				;Se configura el ADCON1 como E/S anal�gica

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
	call stopMotor
	call busca_piso
	movf PORTD,W		;W = PORTD
	andlw b'00000111'	;Mascara para discriminar valores
	movwf boton			;boton = PORTD modificado
	movf boton,W		;W = boton, lee los botones
	btfsc STATUS,Z		;Verifica si hay una solicitud
	goto elevador		;Z = 1, no hay solicitud
	movf piso,W			;W = piso, se obtiene piso actual
	subwf boton,W		;W = boton - piso
	btfsc STATUS,Z		;Verifica si piso = boton
	goto elevador		;Z = 1, solicitud en el mismo piso
	btfsc STATUS,C		;Verifica si debe subir o bajar
	goto subir			;C = 1, boton > piso, sube
	goto bajar			;C = 0, boton < piso, baja

bajar:
	movlw a' '			;W = caracter 1
	call datos			;Envia caracter
	movlw h'7F'
	call datos			;Envia caracter
bajada:
	call busca_piso
	movf piso,W			;W = piso
	subwf boton,W		;W = boton - piso
	btfsc STATUS,Z		;Verifica que piso = giros
	goto elevador		;Z = 1, lleg� al piso solicitado
	;;Implementaci�n motor			;Z = 0, no ha llegado al piso solicitado
	call motorAbajo
	movlw h'c0'				;Cursor en posicion (1,2)
	call comando
	movlw a'M'			;W = caracter 1
	call datos			;Envia caracter
	movlw a'o'			;W = caracter 1
	call datos			;Envia caracter
	movlw a't'			;W = caracter 1
	call datos			;Envia caracter
	call retardo_1seg
	goto bajada

subir:
	movlw a' '			;W = caracter 1
	call datos			;Envia caracter
	movlw h'7E'
	call datos			;Envia caracter
subida:
	call busca_piso
	movf boton,W		;W = boton
	subwf piso,W		;W = boton - piso
	btfsc STATUS,Z		;Verifica si se han terminado los giros
	goto elevador		;Z = 1, lleg� al piso solicitado
	;;Implementaci�n motor			;Z = 0, no ha llegado al piso solicitado
	call motorArriba
	movlw h'c0'				;Cursor en posicion (1,2)
	call comando
	movlw a'M'			;W = caracter 1
	call datos			;Envia caracter
	movlw a'o'			;W = caracter 1
	call datos			;Envia caracter
	movlw a't'			;W = caracter 1
	call datos			;Envia caracter
	call retardo_1seg
	goto subida

;Rutina para buscar el piso actual
busca_piso:
	movlw h'80'			;Coloca el cursor al inicio del display
	call comando		;Envia comando
	call sensores		;Busca piso en el que se encuentra elevador 
	movf giro,W			;Lee piso actual
	sublw h'01'			;Valida piso 1
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso1			;Z = 1, esta en el piso 1
	movf giro,W			;Lee piso actual
	sublw h'02'			;Valida piso 2
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso2			;Z = 1, esta en el piso 1
	movf giro,W			;Lee piso actual
	sublw h'04'			;Valida piso 3
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso3			;Z = 1, esta en el piso 1

piso1:
	movlw a'1'			;W = caracter 1
	call datos			;Envia caracter
	goto salida
piso2:
	movlw h'80'
	call comando
	movlw a'2'			;W = caracter 1
	call datos			;Envia caracter
	goto salida
piso3:
	movlw a'3'			;W = caracter 1
	call datos			;Envia caracter
	goto salida
salida:
	call retardo_1seg
	return

;Rutina valida entrada de sensores 
sensores:
	clrf piso				;Limpia piso
	call leer_sensores
	movf s1,W				;W = s1
	sublw d'30'				;W = 10 - s1
	btfsc STATUS,C			;Verificamos valor del carry
	goto negro1				;C = 1, 10 >= s1, linea negra
	movf s2,W				;W = s2
	sublw d'30'				;W = 20 - s2
	btfsc STATUS,C			;Verificamos valor del carry
	goto negro2				;C = 1, 20 >= s2, linea negra
	movf s3,W				;W = s3
	sublw d'100'			;W = 100 - s3
	btfss STATUS,C			;Verificamos valor del carry
	goto sin_piso			;C = 0, 100 < s3, linea blanca
	movlw d'80'				;W = 60
	subwf s3,W				;W = s3 - 60
	btfss STATUS,C			;Verificamos valor del carry
	goto sin_piso			;C = 0, s3 < 60, linea blanca
	goto negro3				;�ltimo piso le�do 3

negro1:
	bsf piso,0
	movlw d'1'
	movwf giro
	movwf giroAnt 
 	goto salida_sensores
negro2:
	bsf piso,1
	movlw d'2'
	movwf giro
	movwf giroAnt
	goto salida_sensores 
negro3:
	bsf piso,2
	movlw d'4'
	movwf giro
	movwf giroAnt
	goto salida_sensores 
sin_piso:
	movf giroAnt,W			;W = ultimo valor aceptado
	movwf giro				;giro = W
salida_sensores:
	return

;Rutina para realizar la lectura de los sensores
leer_sensores:
	movlw b'11000001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 0, activaci�n del CAD
	call conversion
	movwf s1				;s1 = valor sensor 1
	movlw b'11001001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 1, activaci�n del CAD
	call conversion
	movwf s2				;s2 = valor sensor 2
	movlw b'11010001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 2, activaci�n del CAD
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

;;; Ciclo->4 pasos
;;; Giro rotor->8 ciclos
;;; Reduccion 1:64
;;; Giro completo eje exterior->64 vueltas del rotor
;;; Una revolucion-> 4*8*64=2048 pasos
;Rutina subir elevador
motorArriba:
	movlw d'8'
	movwf pasos2				;pasos=512
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
	

	decfsz pasos2,1
	goto loopM2

	return 
	
;Rutina bajar elevador
motorAbajo:
	movlw d'8'
	movwf pasos2
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

	decfsz pasos2,1
	goto loopM1
	
	return 

;Rutina detener giro Motor
stopMotor:
	bcf PORTC,0				;A=0
	bcf PORTC,1				;B=0
	bcf PORTC,2				;C=0
	bcf PORTC,3				;D=0
	call retardo_15ms
	return

;Rutina de interrupcion
interrupcion:
	btfss INTCON,T0IF		;Verifica estado de T0IF
	goto sal_no_fue_TMR0	;T0IF = 0, no hay desbordamietno
	movlw d'54'				;W = 54
	subwf contI2,W			;W = contI2 - W
	btfsc STATUS,Z			;Verifica estado de Z
	goto pausa				;Z = 1, tiempo limite alcanzado
	movlw d'254'			;W = 254
	subwf contI1,W			;W = contI1 - W
	btfss STATUS,Z			;Verifica estado de Z
	goto inc1				;Z = 0, valores diferentes
	goto inc2				;Z = 1, va a rutina de tiempo terminado
inc1:
	incf contI1				;contI1++
	goto sal_int			;Sale de interrupcion
inc2:
	clrf contI1				;contI2 = 0
	incf contI2				;contI2++
sal_int:
	bcf INTCON,T0IF			;Limpia bandera T0IF, sin desbordamiento
sal_no_fue_TMR0:
	retfie					;Retorno de la interrupcion


pausa:
	movlw h'01'
	call comando		;Borrado del display
	movlw h'83'				;Cursor al inicio del display
	call comando
	movlw a'F'				;Impresi�n de mensaje en el display
	call datos
	movlw a'U'				;Impresi�n de mensaje en el display
	call datos
	movlw a'E'				;Impresi�n de mensaje en el display
	call datos
	movlw a'R'				;Impresi�n de mensaje en el display
	call datos
	movlw a'A'				;Impresi�n de mensaje en el display
	call datos
	movlw a' '				;Impresi�n de mensaje en el display
	call datos
	movlw a'D'				;Impresi�n de mensaje en el display
	call datos
	movlw a'E'				;Impresi�n de mensaje en el display
	call datos
	movlw a' '				;Impresi�n de mensaje en el display
	call datos
	movlw h'c3'				;Cursor en posicion (1,2)
	call comando
	movlw a'S'				;Impresi�n de mensaje en el display
	call datos
	movlw a'E'				;Impresi�n de mensaje en el display
	call datos
	movlw a'R'				;Impresi�n de mensaje en el display
	call datos
	movlw a'V'				;Impresi�n de mensaje en el display
	call datos
	movlw a'I'				;Impresi�n de mensaje en el display
	call datos
	movlw a'C'				;Impresi�n de mensaje en el display
	call datos
	movlw a'I'				;Impresi�n de mensaje en el display
	call datos
	movlw a'O'				;Impresi�n de mensaje en el display
	call datos
	clrf contI1
	clrf contI2
	call retardo_1seg
	call retardo_1seg
	call retardo_1seg
	movlw h'01'
	call comando		;Borrado del display
	goto sal_int



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
