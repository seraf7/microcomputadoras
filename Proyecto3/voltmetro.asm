;;;;;;;;;;;;;;;;
;Descripcion de puertos
;;;;;;;;;;;;;;;;
; PORTB bus de datos B0-D0 ... B7-D7
; RS - E0
; E - E1
; R/W - GND
; PORTA entrada anal�gica A0
; PORTD modo D0-S1 ... D2-S3

processor 16f877
include<p16f877.inc>

;Declaracion de constantes a usar 
valor equ h'20'
valor1 equ h'21'
valor2 equ h'22'
conv equ h'23'
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

contador equ H'38'; Unidades

c0  equ H'39'
c1  equ H'40'
c2  equ H'41'

    org 0
    goto inicio
	org 5

inicio:
	;Limpieza de puertos
	clrf PORTE
	clrf PORTB
	clrf PORTA
	clrf PORTD
	clrf PORTC
	;Configuracion de puertos
	bsf STATUS,RP0
	bcf STATUS,RP1			;Cambio al banco 1
	clrf TRISB				;TRISB como salida
	clrf TRISE				;TRISE como salida
	clrf TRISC				;TRISC como salida
	movlw h'ff'
	movwf TRISD				;TRISD como entrada
	;Configuracion del CAD
	clrf ADCON1				;ADCON1 como E/S anal�gica
	bcf STATUS,RP0			;Cambio al banco 0
	movlw b'11000001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 0, activaci�n del CAD

	call inicia_lcd			;Inicializacion del display

;Seleccion del modo
modo:
	movlw h'01'
	call comando			;Borrado del display
	movf PORTD,0			;Lectura del puerto D
	andlw b'00000111'		;Mascara para descartar bits no usados
	movwf opc				;Guardar opcion registrada
	;Validacion de la entrada
	movf opc,0				;W = opc, opcion ingresada
	btfsc STATUS,Z
	goto decimal			;opc = 0
	movf opc,0
	xorlw h'01'				;Comparacion con 01H			
	btfsc STATUS,Z
	goto hexadecimal		;opc = 1
	movf opc,0
	xorlw h'02'				;Comparacion con 02H			
	btfsc STATUS,Z
	goto binario			;opc = 2
	movf opc,0
	xorlw h'03'				;Comparacion con 03H
	btfsc STATUS,Z
	goto voltaje			;opc = 3
	goto modo
 
;Rutina para imprimir valor decimal del registro
decimal:
	;Inicializacion valores
	movlw h'00' 
	movwf DEC_2 ;DEC_2='00'
 	movwf DEC_1 ;DEC_1='00'
	movwf DEC_0 ;DEC_0='00'
	call conversion
	
	;;;Divisi�n entre 100
divi_100:	
	;Primero dividimos el numero hexadeciamal entre d'100' h'64'
	movf conv,0 			;W=conv
	movwf dato
	movwf nume  			;nume=W
	movlw h'64' 			;d'100'
	movwf denom  			;denom=100
	call divi  				;conv/100

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
	goto modo			;Va a rutina de conversion

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

;Rutina para desplegar valor de entrada en hexadecimal
hexadecimal:
	;Aplicacion de mascaras en los registros
	movlw h'0f'
	movwf hexL
	movlw h'f0'
	movwf hexH
	call conversion
	;Separacion de parte alta y baja
	movf conv,0				;Valor del CAD
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
	movf PORTD,0			;Lectura del puerto D
	xorlw h'01'				;Valida que el valor del puerto D
	btfsc STATUS,Z
	goto hexadecimal		;Puerto D en 1
	goto modo				;Puerto D cambio de valor

;Rutina para imprimir la entrada en formato binario
binario:
	call conversion
	movf conv,0				;Lee valor del CAD
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
	movf PORTD,0			;Lectura del puerto D
	xorlw h'02'				;Valida que el valor del puerto D
	btfsc STATUS,Z
	goto binario			;Puerto D en 2
	goto modo				;Puerto D cambio de valor
cero_binario:
	decf contador
	btfsc STATUS,Z			;Verifica si se ha llegado a 0
	goto interrupcion		;Contador ha llegado a 0	
	movlw a'0'
	call datos
	goto cero_binario

;Rutina para imprimir valor de voltaje
voltaje:
	call conversion
	movf conv,0				;Lee valor del CAD
	movwf dato
	movlw h'00'
	movwf c0
	movwf c1
	movwf c2
ciclo:
	movf dato,0				;W=dato
	sublw h'00'
	btfsc STATUS,C
	goto imprime	
	decf dato					;C=0 negativo mayor a 0
	movf c0,0
	xorlw d'08'
	btfss STATUS,Z
	goto cont_0					;C0=8
	movlw h'00'					;C=0 
	movwf c0
	movf c1,0
	sublw d'09'
	btfss STATUS,Z
	goto cont_1	
	movlw h'00'					;C=0 negativo mayor a 9
	movwf c1
	incf c2
	goto ciclo				
	
cont_0:
	incf c0
	incf c0
	goto ciclo
cont_1:
	incf c1
	goto ciclo
imprime:
	movf c2,0
	call ascii				;Obtiene valor ascii de parte baja
	movwf c2
	movf c1,0
	call ascii				;Obtiene valor ascii de parte baja
	movwf c1
	movf c0,0
	call ascii				;Obtiene valor ascii de parte baja
	movwf c0
	movf c2,0
	call datos
	movlw a'.'
	call datos
	movf c1,0
	call datos
	movf c0,0
	call datos
	movlw a'V'
	call datos
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
    bcf PORTC,0
    bsf PORTC,1
    call ret200
    bcf PORTC,1
	call ret200
	call ret200
    return

;Rutina para enviar datos al display
datos:
	movwf PORTB
    call ret200
    bsf PORTC,0
    bsf PORTC,1
    call ret200
    bcf PORTC,1
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

;Rutina de onversion de entrada anal�gica a digital
conversion:
	bsf ADCON0,2			;Inicia la conversion
espera:
	btfsc ADCON0,2			;Verifica si termin� la conversi�n
	goto espera				;Va a espera si la conversi�n continua
	movf ADRESH,W			;W = valor convertido	
	movwf conv				;conv = W
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