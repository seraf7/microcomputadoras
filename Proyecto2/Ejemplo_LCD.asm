 ; PORTB BUS DE DATOS B0-D0 ... B7-D7
 ; RS - A0/E0
 ; E - A1/1
 ; R/W - GND

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

    org 0
    goto inicio
	org 5

inicio:
	  clrf PORTE
      CLRF PORTB 
      bsf STATUS,5
      bcf STATUS,6
   movlw b'000000000'
   movwf TRISB
   movlw 0x07
   movwf ADCON1
   movlw b'000000000'
   movwf TRISE
   bcf STATUS,5

   call inicia_lcd
 
otrom:  movlw 0x80
  call comando
  movlw a'F'
  call datos
  movlw a'I'
  call datos
  call retardo_1seg

especial:
	movlw h'40'			;Acceso a la CGRAM (caracter 1)
	call comando
	call retardo8
	;Escritura por renglones del caracter especial
	movlw h'07'
	call datos
	call retardo8
	movlw h'1f'
	call datos
	call retardo8
	movlw h'09'
	call datos
	call retardo8
	movlw h'0d'
	call datos
	call retardo8
	movlw h'04'
	call datos
	call retardo8
	movlw h'06'
	call datos
	call retardo8
	movlw h'00'
	call datos
	call retardo8
	movlw h'03'
	call datos
	call retardo8

	call inicia_lcd
	
	;movlw h'00'
	;call datos	
	;call retardo_1seg
	
;Segunda mitad del caracter
	movlw h'48'			;Acceso a la CGRAM (Caracter 2)
	call comando
	call retardo8
	;Escritura por renglones del caracter especial
	movlw h'1C'
	call datos
	call retardo8
	movlw h'1f'
	call datos
	call retardo8
	movlw h'12'
	call datos
	call retardo8
	movlw h'16'
	call datos
	call retardo8
	movlw h'04'
	call datos
	call retardo8
	movlw h'0c'
	call datos
	call retardo8
	movlw h'00'
	call datos
	call retardo8
	movlw h'18'
	call datos
	call retardo8

	call inicia_lcd
	
	movlw h'00'
	call datos	
	call retardo_1seg	
	movlw h'01'
	call datos	
	call retardo_1seg
	call retardo_1seg
	call retardo_1seg
	call retardo_1seg
	call retardo_1seg
	call retardo_1seg

  goto otrom
   
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
    bcf PORTE,0
    bsf PORTE,1
    call ret200
    bcf PORTE,1
	call ret200
	call ret200
    return

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

ret100ms: movlw 0x03 
rr  movwf valor
tres: movlw 0xff
 	movwf valor1
dos: movlw 0xff
 	movwf valor2
uno: decfsz valor2
  goto uno
 decfsz valor1
 goto dos
 decfsz valor
 goto tres
return

retardo_1seg:  ;Falta esta subrutina de 1 segundo
		 movlw h'40'
         movwf val1
lp_3:	 movlw h'100'
		 movwf val2
lp_2:	 movlw h'120'
 		 movwf val3
lp_1:	 decfsz val3
		 goto lp_1
		 decfsz val2
		 goto lp_2
		 decfsz val1
		 goto lp_3
	return

retardo8: ;Subrutina de retardo de aproximadamente 800useg
	MOVLW 36H
	MOVWF valor7
nueve:
	MOVLW 9FH
	MOVWF valor8
ocho: 
	MOVLW 8DH
	MOVWF valor9
siete: 
	DECFSZ valor9,1
	GOTO siete
	DECFSZ valor8,1
	GOTO ocho
	DECFSZ valor7,1
	GOTO nueve
	RETURN

	end
