;;;;;;;;;;;;;;;;
;Descripcion de puertos
;;;;;;;;;;;;;;;;
; PORTB bus de datos B0-D0 ... B7-D7
; RS - E0  /  D0
; E - E1   /  D1
; R/W - GND
; PORTA entrada analógica A0
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

datoRx equ H'42'

contI1 equ H'43'		;Contadores para interrupcion
contI2 equ H'44'

    org 0
    goto inicio			;Vector de reset

	org 4
	goto interrupcion	;Vector de interrupcion

	org 5				;Origen del programa

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
	clrf TRISD				;TRISD como salida
	;Configuracion del CAD
	clrf ADCON1				;ADCON1 como E/S analógica
	;Configuracion de la comunicación serial
	bsf TXSTA,BRGH			;Seleccion de alta velocidad
	movlw d'129'			;W = 129
	movwf SPBRG				;BAUDS = 9600
	bcf TXSTA,SYNC			;Uso de comunicacion asincrona
	bsf TXSTA,TXEN			;Activacion de transmision
	
	;Configuracion de interrupciones
	movlw b'00000111'		;Uso de temporizador
	movwf OPTION_REG		;Predivisor del TMR0 = 256

	bcf STATUS,RP0			;Cambio al banco 0
	bcf INTCON,T0IF			;Limpia bandera de desborde en TMR0
	bsf INTCON,T0IE			;Habilita interrupcion por desbordamiento
	bsf INTCON,GIE			;Habilita interrupciones generales
	clrf contI1				;Limpia contador
	clrf contI2

	movlw b'11000001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 0, activación del CAD

	bsf RCSTA,SPEN			;Habilitacion del puerto serie
	bsf RCSTA,CREN			;CREN=1 SE HABILITA AL RECEPTOR
	
	call inicia_lcd			;Inicializacion del display


;Rutina de recepcion serial
recibe:
	btfss PIR1,RCIF		;Se verifica que se haya recibido un dato
	goto recibe			;RCIF=0 Recepción en proceso
	movf RCREG,W		;RCIF=1 Recepción completa,
	movwf datoRx		;Carga datos en REGISTRO de RECEPCIÓN

;Seleccion del modo
modo:
	movlw h'01'
	call comando			;Borrado del display
	movf datoRx,W			;Lectura del dato
	movwf opc				;Guardar opcion registrada
	;Validacion de la entrada
	sublw a'0'				;Comparacion con caracter 0
	btfsc STATUS,Z
	goto decimal			;opc = 0
	movf opc,0
	xorlw a'1'				;Comparacion con 01H			
	btfsc STATUS,Z
	goto hexadecimal		;opc = 1
	movf opc,0
	xorlw a'2'				;Comparacion con 02H			
	btfsc STATUS,Z
	goto binario			;opc = 2
	movf opc,0
	xorlw a'3'				;Comparacion con 03H
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
	
	;;;División entre 100
divi_100:	
	;Primero dividimos el numero hexadeciamal entre d'100' h'64'
	movf conv,0 			;W=conv
	movwf dato
	movwf nume  			;nume=W
	movlw h'64' 			;d'100'
	movwf denom  			;denom=100
	call divi  				;conv/100

	;;;División entre 10
divi_10: 
	movf residuo,0 			;W=residuo->PORTD/100
	movwf nume  			;nume=W
	movlw h'0A' 			;d'10'
	movwf denom  			;denom=10
	movf resultado,0 		;W=resultado
	call ascii
	movwf DEC_2  			;DEC_2=W  CENTENAS
	call divi  				;residuo_100/10

	;;;División entre 1
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
	movf DEC_2,0			;W = DEC_2
	movwf TXREG				;TXREG = DEC_2, dato para transmitir
	call datos				;Envio de datos al display
	call transmite			;Envio de datos al puerto serial
	movf DEC_1,0
	movwf TXREG
	call datos
	call transmite
	movf DEC_0,0
	movwf TXREG
	call datos
	call transmite
	call salto
	call retardo_1seg		;Mantiene la señal
	goto recibe				;Va a rutina de recepcion

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
	btfss STATUS,C 			;Z=0 comprobamos signo de operación
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
	movwf TXREG
	call datos				;Envia ascii de parte alta al display
	call transmite			;Envia ascii de parte alta al puerto serial
	movf hexL,0
	movwf TXREG
	call datos				;Envia ascii de parte baja al display
	call transmite			;Envia ascii de parte alta al puerto serial
	call salto
	call retardo_1seg		;Mantiene la señal
	goto recibe				;
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
	goto paro				;Contador ha llegado a 0
	btfsc dato,7
	goto es_1				;Bit es 1
	goto es_0				;Bit es 0
es_1:
	movlw a'1'
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
	goto dec_con
es_0:
	movlw a'0'
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
dec_con:
	rlf dato
	decf contador
	goto verifica
paro:
	call salto				;Imprime salto de linea	
	call retardo_1seg		;Mantiene la señal
	goto recibe	
cero_binario:
	decf contador
	btfsc STATUS,Z			;Verifica si se ha llegado a 0
	goto paro				;Contador ha llegado a 0	
	movlw a'0'
	movwf TXREG
	call datos
	call transmite
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
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
	movlw a'.'
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
	movf c1,0
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
	movf c0,0
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Envia datos al puerto serial
	movlw a'V'
	movwf TXREG
	call datos				;Envia datos al display
	call transmite			;Endia datos al puerto serial
	call salto				;Imprime salto de linea
	call retardo_1seg
	goto recibe	

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
    bcf PORTD,0
    bsf PORTD,1
    call ret200
    bcf PORTD,1
	call ret200
	call ret200
    return

;Rutina para enviar datos al display
datos:
	movwf PORTB
    call ret200
    bsf PORTD,0
    bsf PORTD,1
    call ret200
    bcf PORTD,1
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

;Rutina de conversion de entrada analógica a digital
conversion:
	bsf ADCON0,2			;Inicia la conversion
espera:
	btfsc ADCON0,2			;Verifica si terminó la conversión
	goto espera				;Va a espera si la conversión continua
	movf ADRESH,W			;W = valor convertido	
	movwf conv				;conv = W
	return

;Rutina de transmision serial
transmite:
	bsf STATUS,RP0			;Cambio al banco 1
esp:
	btfss TXSTA,TRMT		;Verifica TRMT
	goto esp				;TRMT = 0, transmision en proceso
	bcf STATUS,RP0			;Cambio al banco de memoria 0
	return


;Rutina para imprimir un salto de linea
salto:
	movlw 0x0D				;Cursor posicionado al inicio de la linea
	movwf TXREG
	call transmite			;Transmite el dato
	movlw 0x0A				;Cursor en la siguiente linea
	movwf TXREG
	call transmite
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
	movlw a'$'				;W = Z (caracter)
	movwf TXREG				;Prepara dato a transmitir
	call transmite			;Envia datos a la terminal
	movlw h'80'				;Cursor al inicio del renglon
	call comando			;Envia datos al display
	movlw a'T'				;Impresión de mensaje en el display
	call datos
	movlw a'I'
	call datos
	movlw a'E'
	call datos
	movlw a'M'
	call datos
	movlw a'P'
	call datos
	movlw a'O'
	call datos
	movlw a' '
	call datos
	movlw a'T'
	call datos
	movlw a'E'
	call datos
	movlw a'R'
	call datos
	movlw a'M'
	call datos
	movlw a'I'
	call datos
	movlw a'N'
	call datos
	movlw a'A'
	call datos
	movlw a'D'
	call datos
	movlw a'O'
	call datos
alto:
	nop
	goto alto				;Mantiene interrupcion

	end