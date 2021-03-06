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

nume equ h'31'
denom equ h'32'
resultado equ h'33'
residuo equ h'34'

DEC_2 equ H'35'; Centenas
DEC_1 equ H'36'; Decenas
DEC_0 equ H'37'; Unidades

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
	andlw h'07'				;Mascara para descartar bits no usados
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
	movf opc,0
	xorlw h'04'				;Comparacion con 04H
	btfsc STATUS,Z
	goto decimal			;opc = 4
	movf opc,0
	xorlw h'05'				;Comparacion con 05H
	btfsc STATUS,Z
	goto puma_2			;opc = 5
	goto puma	


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
	call retardo_1seg		;Mantiene la se�al
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
	call retardo_1seg		;Mantiene la se�al
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
	movf hexH,0
	call datos				;Envia ascii de parte alta al display
	movf hexL,0
	call datos				;Envia ascii de parte baja al display
	call retardo_1seg		;Mantiene la se�al
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
	movlw d'9'
	movwf contador			;Inicializa contador con 8
	movf dato,0				;W=dato
	xorlw h'00'
	btfsc STATUS,Z
	goto cero_binario
	decf contador
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
	call retardo_1seg		;Mantiene la se�al
	movf PORTA,0			;Lectura del puerto A
	xorlw h'03'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto binario			;Puerto A en 3
	goto modo				;Puerto A cambio de valor
cero_binario:
	decf contador
	btfsc STATUS,Z			;Verifica si se ha llegado a 0
	goto interrupcion		;Contador ha llegado a 0	
	movlw a'0'
	call datos
	goto cero_binario

;Rutina para desplegar valor de entrada en decimal
decimal:
	;Inicializacion valores
	movlw h'00' 
	movwf DEC_2 ;DEC_2='00'
 	movwf DEC_1 ;DEC_1='00'
	movwf DEC_0 ;DEC_0='00'
	
	;;;Divisi�n entre 100
divi_100:	
	;Primero dividimos el numero hexadeciamal entre d'100' h'64'
	movf PORTD,0 			;W=PORTD
	movwf dato
	movwf nume  			;nume=W
	movlw h'64' 			;d'100'
	movwf denom  			;denom=100
	call divi  				;port/100

	;;;Divisi�n entre 10
divi_10: 
	movf residuo,0 			;W=residuo->PORTD/100
	movwf nume  			;nume=W
	movlw h'0A' 			;d'10'
	movwf denom  			;denom=10
	movf resultado,0 		;W=resultado
	call ascii
	movwf DEC_2  			;DEC_2=W  CENTENAS
	call divi  				;residuo_100/10

	;;;Divisi�n entre 1
divi_1: 
	movf residuo,0  		;W=residuo->PORTD/10
	movwf nume  			;nume=W
	movlw h'01' 			;d'01'
	movwf denom  			;denom=1
	movf resultado,0 		;W=resultado
	call ascii
	movwf DEC_1  			;DEC_1=W  DECENAS
	call divi  				;residuo_10/1
    movf resultado,0  		;W=resultado 
	call ascii 
   	movwf DEC_0  			;DEC_0=W UNIDADES

	movlw 0x80				;Cursor en el extremo superior derecho
	call comando			;Envia comando al display
	movf DEC_2,0
	call datos
	movf DEC_1,0
	call datos
	movf DEC_0,0
	call datos 
	call retardo_1seg		;Mantiene la se�al
	movf PORTA,0			;Lectura del puerto A
	xorlw h'04'				;Valida que el valor del puerto A
	btfsc STATUS,Z
	goto decimal			;Puerto A en 4
	goto modo

;;;DIVISION;;;
divi:
	;inicializamos
	movlw d'0'
	movwf resultado  		;R=0
	movwf residuo 			;residuo=0
	;Comprobamos denominador
	movf denom,0
	btfsc STATUS,Z
	goto indeterminada 		;Z=1
	;Comprobamos numenador
	movf nume,0
	btfsc STATUS,Z
	goto cero  				;Z=1

iteracion:
	movf denom,0
	subwf nume,1			;X = X - Y
	btfsc STATUS,Z
	goto mismo				;numerador = denominador 
	btfss STATUS,C 			;Z=0 comprobamos signo de operaci�n
	goto resto				;C=0 negativo ya no se pudo dividir mas 
	incf resultado			;C=1 positivo  resultado = resultado + 1
	goto iteracion

indeterminada: 
	movlw h'FF'
	movwf resultado  		;R=FF
	return 

cero: ;0/* =0
	clrf residuo   			;residuo=0
	clrf resultado 			;resultado=0
	return 

mismo: ;X/X
	clrf residuo   			;residuo=0
	incf resultado 			;Solo cabe una vez 
	return 

resto:
	addwf nume,0 ;W=W+X
	movwf residuo
	return 

;Subrutina para la impresion del logo de los pumas
puma:
	call inicia_lcd
	;Definicion de caracter 1
	movlw h'40'			;Acceso a la CGRAM (posicion 1)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'07'			;Definicion de pixeles renglon 1
	call datos
	movlw h'1f'			;Definicion de pixeles renglon 2
	call datos
	movlw h'09'
	call datos
	movlw h'0d'
	call datos
	movlw h'04'
	call datos
	movlw h'06'
	call datos
	movlw h'00'
	call datos
	movlw h'03'
	call datos	
;Definicion de la segunda mitad del caracter
	movlw h'48'			;Acceso a la CGRAM (Caracter 2)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'1C'
	call datos
	movlw h'1f'
	call datos
	movlw h'12'
	call datos
	movlw h'16'
	call datos
	movlw h'04'
	call datos
	movlw h'0c'
	call datos
	movlw h'00'
	call datos
	movlw h'18'
	call datos
	call inicia_lcd
;Impresion del los carcateres
	movlw h'80'
	call comando
	movlw h'00'					;Caracter 0 definido
	call datos	
	movlw h'01'					;Caracter 1 definido
	call datos	
	call retardo_1seg
	call retardo_1seg
	goto modo				;Regresa a validar modo de entrada
	
puma_2:
	call inicia_lcd
	;Definicion de caracter 1
	movlw h'40'			;Acceso a la CGRAM (posicion 1)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'			;Definicion de pixeles renglon 1
	call datos
	movlw h'03'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'0f'			
	call datos
	movlw h'0C'			
	call datos
	movlw h'0E'			
	call datos
	movlw h'0F'			
	call datos

	;Definicion de caracter 2
	movlw h'48'			;Acceso a la CGRAM (posicion 2)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'1F'			;Definicion de pixeles renglon 1
	call datos
	movlw h'1F'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'1F'			
	call datos
	movlw h'0E'			
	call datos
	movlw h'0E'			
	call datos	
	movlw h'0E'			
	call datos

	;Definicion de caracter 3
	movlw h'50'			;Acceso a la CGRAM (posicion 3)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'			;Definicion de pixeles renglon 1
	call datos
	movlw h'18'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'1f'			
	call datos
	movlw h'1E'			
	call datos
	movlw h'06'			
	call datos
	movlw h'0E'			
	call datos	
	movlw h'1E'			
	call datos

	;Definicion de caracter 4
	movlw h'58'			;Acceso a la CGRAM (posicion 4)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'07'			;Definicion de pixeles renglon 1
	call datos
	movlw h'06'			
	call datos
	movlw h'06'			
	call datos
	movlw h'04'			
	call datos
	movlw h'07'			
	call datos
	movlw h'00'			
	call datos
	movlw h'00'			
	call datos	
	movlw h'00'			
	call datos

	;Definicion de caracter 5
	movlw h'60'			;Acceso a la CGRAM (posicion 5)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'0E'			;Definicion de pixeles renglon 1
	call datos
	movlw h'0E'			
	call datos
	movlw h'1F'			
	call datos
	movlw h'00'			
	call datos
	movlw h'11'			
	call datos
	movlw h'00'			
	call datos
	movlw h'1F'			
	call datos	
	movlw h'00'			
	call datos

	;Definicion de caracter 6
	movlw h'68'			;Acceso a la CGRAM (posicion 6)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'1C'			;Definicion de pixeles renglon 1
	call datos
	movlw h'0C'			
	call datos
	movlw h'0C'			
	call datos
	movlw h'04'			
	call datos
	movlw h'1C'			
	call datos
	movlw h'00'			
	call datos
	movlw h'00'			
	call datos	
	movlw h'00'			
	call datos
	
	call inicia_lcd

	;Impresion del los carcateres
	movlw h'80'
	call comando
	movlw h'00'					;Caracter 0 definido
	call datos	
	movlw h'01'					;Caracter 1 definido
	call datos
	movlw h'02'					;Caracter 2 definido
	call datos
	movlw h'c0'				;Cursor en posicion (1,2)
	call comando
	movlw h'03'					;Caracter 3 definido
	call datos
	movlw h'04'					;Caracter 4 definido
	call datos
	movlw h'05'					;Caracter 5 definido
	call datos
	call retardo_1seg
	call retardo_1seg
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