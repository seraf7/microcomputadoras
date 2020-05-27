 ; PORTB BUS DE DATOS B0-D0 ... B7-D7
 ; RS - D0
 ; E - D1
 ; R/W - GND
 ; PORTA entrada analógica A0

processor 16f877
include<p16f877.inc>
 
valor equ h'20'
valor1 equ h'21'
valor2 equ h'22'
contador equ h'23'
dato equ h'24'

val1 equ h'25'
val2 equ h'26'
val3 equ h'27'

valor7 equ h'28'
valor8 equ h'29'
valor9 equ h'30'

conv equ h'31'

DEC_2 equ H'32'; Centenas
DEC_1 equ H'33'; Decenas
DEC_0 equ H'34'; Unidades

nume equ h'35'
denom equ h'36'
resultado equ h'37'
residuo equ h'38'

    org 0
    goto inicio
	org 5

inicio:
	;Limpieza de puertos
	clrf PORTD
    clrf PORTB
	clrf PORTA 
	;Configuracion de puertos
    bsf STATUS,5
    bcf STATUS,6			;Cambio al banco 1
   	clrf TRISB				;TRISB como salida
   	clrf TRISD				;TRISD como salida
	;Configuracion del CAD
   	clrf ADCON1				;ACON! como E/S analogica
	;Configuracion de la comunicación serial
	bsf TXSTA,BRGH			;Seleccion de alta velocidad
	movlw d'129'			;W = 129
	movwf SPBRG				;BAUDS = 9600
	bcf TXSTA,SYNC			;Uso de comunicacion asincrona
	bsf TXSTA,TXEN			;Activacion de transmision

   	bcf STATUS,5			;Cambio al banco 0
	movlw b'11000001'		;Configura el ADCON0 con el reloj interno, 
	movwf ADCON0			;lectura de canal 0, activación del CAD
	
	bsf RCSTA,SPEN			;Habilitacion del puerto serie
	bsf RCSTA,CREN			;CREN=1 SE HABILITA AL RECEPTOR

	clrf conv				;Limpia variable de conversion
	
   	call inicia_lcd			;Inicializa el display
 
otrom:  
	movlw 0x80
  	call comando
  	movlw a'F'
  	call datos
  	movlw a'I'
  	call datos
  	call retardo_1seg
  	call especial			;Registra caracteres epeciales

;Rutina de impresion de niveles
niveles:
	call conversion			;Llama rutina de conversion A/D
	movlw h'01'				;Cursor a Home, borrado de posiciones
  	call comando
	movlw h'80'				;Cursor en posicion (1,1)
	call comando
	;Validar que el valor sea diferente a 0
	movlw d'1'				;W = 1
	subwf conv,W			;W = conv - 1
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 1
	movlw h'00'				;C = 1, conv => 1
	call datos				;Imprime nivel 1
	;Verificar si el valor es mayor a 31
	movlw d'31'				;W = 31
	subwf conv,W			;W = conv - 31
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 31
	movlw h'01'				;C = 1, conv => 31
	call datos				;Imprime nivel 2
	;Verificar si el valor es mayor a 63
	movlw d'63'				;W = 63
	subwf conv,W			;W = conv - 63
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 63
	movlw h'02'				;C = 1, conv => 63
	call datos				;Imprime nivel 3
	;Verificar si el valor es mayor a 95
	movlw d'95'				;W = 95
	subwf conv,W			;W = conv - 95
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 95
	movlw h'03'				;C = 1, conv => 95
	call datos				;Imprime nivel 4
	;Verificar si el valor es mayor a 127
	movlw d'127'			;W = 127
	subwf conv,W			;W = conv - !27
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 127
	movlw h'04'				;C = 1, conv => 127
	call datos				;Imprime nivel 5
	;Verificar si el valor es mayor a 159
	movlw d'159'			;W = 159
	subwf conv,W			;W = conv - 159
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 159
	movlw h'05'				;C = 1, conv => 159
	call datos				;Imprime nivel 6
	;Verificar si el valor es mayor a 191
	movlw d'191'			;W = 191
	subwf conv,W			;W = conv - 191
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 191
	movlw h'06'				;C = 1, conv => 191
	call datos				;Imprime nivel 7
	;Verificar si el valor es mayor a 223
	movlw d'223'			;W = 223
	subwf conv,W			;W = conv - 223
	btfss STATUS,C			;Verifica estado de C
	goto retardo			;C = 0, conv < 223
	movlw h'07'				;C = 1, conv => 223
	call datos				;Imprime nivel 8
retardo:  	
	nop						;Sin operacion

;Rutina de impresion de valor numerico
numero:
	movlw h'c0'				;Cursor en posicion (1,2)
	call comando
	movlw a'P'
	call datos				;Impresion de caracter ASCII
	movlw a'W'
	call datos				;Impresion de caracter ASCII
	movlw a'M'
	call datos				;Impresion de caracter ASCII
	movlw a':'
	call datos				;Impresion de caracter ASCII
	movlw a' '
	call datos				;Impresion de espacio
	call decimal			;Imprimir valor convertido
	movlw a'/'				;Impresion de caracter ASCII /
	call datos
	movlw a'2'
	call datos				;Impresion de caracter ASCII
	movlw a'5'
	call datos				;Impresion de caracter ASCII
	movlw a'5'
	call datos
	call retardo_1seg		;Mantiene la señal
	goto niveles

;Rutina para imprimir valor decimal del registro
decimal:
	;Inicializacion valores 
	clrf DEC_2 ;DEC_2='00'
 	clrf DEC_1 ;DEC_1='00'
	clrf DEC_0 ;DEC_0='00'
	
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
;Impresion de caracteres
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
	return
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


;Rutina de definicion de carcateres especiales
especial:
	movlw h'40'			;Acceso a la CGRAM (caracter 1)
	call comando
	
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'15'
	call datos
	
;Segundo nivel de la imagen
	movlw h'48'			;Acceso a la CGRAM (Caracter 2)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Tercer nivel de imagen
	movlw h'50'			;Acceso a la CGRAM (Caracter 3)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Cuarto nivel de imagen
	movlw h'58'			;Acceso a la CGRAM (Caracter 4)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Quinto nivel de imagen
	movlw h'60'			;Acceso a la CGRAM (Caracter 5)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Sexto nivel de imagen
	movlw h'68'			;Acceso a la CGRAM (Caracter 6)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'00'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Septimo nivel de imagen
	movlw h'70'			;Acceso a la CGRAM (Caracter 7)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'00'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

;Octavo nivel de imagen
	movlw h'78'			;Acceso a la CGRAM (Caracter 8)
	call comando
	;Escritura por renglones del caracter especial
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos
	movlw h'0A'
	call datos
	movlw h'15'
	call datos

	call inicia_lcd
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

;Rutina de inicializacion del display
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

;Subrutina de retardo de 1 segundo
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
