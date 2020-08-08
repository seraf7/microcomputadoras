;;;Descripcion de puertos;;;
;PORTB bus de datos B0-D0 ... B7-D7
;R/W - GND
;RS - D6
;E - D7
;boton1-D0 ... boton3-D2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
processor 16f877
include<p16f877.inc>

;Declaracion de variables y constantes
valor equ h'20'
valor1 equ h'21'
valor2 equ h'22'

val1 equ h'23'
val2 equ h'24'
val3 equ h'25'

piso equ h'26'
boton equ h'27'
giro equ h'28'

	org 0
	goto inicio
	org 5

inicio:
	;Configuracion de puertos
	clrf PORTD
	clrf PORTB
	bsf STATUS,RP0		;Cambio al banco 1
	bcf STATUS,RP1
	clrf TRISB			;Puerto B como salida
	movlw b'00000111'	;D7...D3 como salidas
	movwf TRISD			;D2...D0 como entradas
	bcf STATUS,RP0		;Cambio al banco 0

	;Inicializacion de variables
	movlw h'04'
	movwf piso			;piso = 1
	clrf boton
	clrf giro
	
	;Inicializacion del display
	call inicia_lcd

elevador:
	call busca_piso
	movf PORTD,W		;W = PORTD
	andlw b'00000111'	;Mascara para discriminar valores
	movwf boton		;boton = PORTD modificado
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
	movf piso,W			;W = piso
	movwf giro			;giro = W
bajada:
	call busca_piso
	movf giro,W			;W = giro
	subwf boton,W		;W = boton - giro
	btfsc STATUS,Z		;Verifica que piso = giros
	goto elevador		;Z = 1, llegó al piso solicitado
	rrf giro			;Z = 0, no ha llegado al piso solicitado
	movf giro,W
	movwf piso			;Baja un piso
	goto bajada

subir:
	movf piso,W			;W = piso
	movwf giro			;giro = W
subida:
	call busca_piso
	movf boton,W		;W = giro
	subwf giro,W		;W = boton - giro
	btfsc STATUS,Z		;Verifica si se han terminado los giros
	goto elevador		;Z = 1, llegó al piso solicitado
	rlf giro			;Z = 0, no ha llegado al piso solicitado
	movf giro,W
	movwf piso			;Sube un piso
	goto subida

;Rutina para buscar el piso actual
busca_piso:
	movlw h'80'			;Coloca el cursor al inicio del display
	call comando		;Envia comando
	movf piso,W			;Lee piso actual
	sublw h'01'			;Valida piso 1
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso1			;Z = 1, esta en el piso 1
	movf piso,W			;Lee piso actual
	sublw h'02'			;Valida piso 2
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso2			;Z = 1, esta en el piso 1
	movf piso,W			;Lee piso actual
	sublw h'04'			;Valida piso 3
	btfsc STATUS,Z		;Verifica estado de Z
	goto piso3			;Z = 1, esta en el piso 1

piso1:
	movlw a'1'			;W = caracter 1
	call datos			;Envia caracter
	goto salida
piso2:
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

;Rutina de 1 segundo
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