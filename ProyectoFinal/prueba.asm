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

	org 0
	goto inicio
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
	clrf ADCON1				;Se configura el ADCON1 como E/S analógica
	bcf STATUS,RP0			;Cambio al banco de memoria 1
	clrf PORTB				;Limpia el puerto B

	;Inicializacion de variables
	clrf boton
	clrf giro
	clrf piso 

	;Inicializacion del display
	call inicia_lcd


elevador:
	movlw h'01'
	call comando		;Borrado del display
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
	goto elevador		;Z = 1, llegó al piso solicitado
	;;Implementación motor			;Z = 0, no ha llegado al piso solicitado
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
	goto elevador		;Z = 1, llegó al piso solicitado
	;;Implementación motor			;Z = 0, no ha llegado al piso solicitado
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
	sublw d'10'				;W = 10 - s1
	btfsc STATUS,C			;Verificamos valor del carry
	call negro1
	;bsf piso,0	 			;C = 1, 10 >= s1, linea negra
	movf s2,W				;W = s2
	sublw d'20'				;W = 10 - s2
	btfsc STATUS,C			;Verificamos valor del carry
	call negro2
	;bsf piso,1				;C = 1, 10 >= s2, linea negra
	bsf piso,2				;piso[2] = 1
	movf s3,W				;W = s3
	sublw d'100'			;W = 100 - s3
	btfss STATUS,C			;Verificamos valor del carry
	bcf piso,2				;C = 0, 100 < s3, linea blanca
	movlw d'60'				;W = 60
	subwf s3,W				;W = s3 - 60
	btfss STATUS,C			;Verificamos valor del carry
	bcf	piso,2				;C = 0, s3 < 60, linea blanca
	movf piso,W				;W = piso
	btfss STATUS,Z
	call negro3				;Último piso leído 3
	;Z=1 No está en ningún piso
	movf giro,W				;W = piso leido anteriormente
	movwf piso
	return

negro1:
	bsf piso,0
	movlw d'1'
	movwf giro 
 	return
negro2:
	bsf piso,1
	movlw d'2'
	movwf giro 
 	return 
negro3:
	bsf piso,2
	movlw d'4'
	movwf giro 
 	return  

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

	end