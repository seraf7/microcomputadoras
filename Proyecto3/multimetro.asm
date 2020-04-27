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
    goto voltaje
	org 5

voltaje:
	movf conv,0				;Lee valor del CAD
	movwf dato
	movlw h'00'
	movwf c0
	movwf c1
	movwf c2
verifica:
	movf dato,0				;W=dato
	sublw h'00'
	btfsc STATUS,C
	goto imprime	
	decf dato					;C=0 negativo mayor a 0
	movf c0,0
	sublw d'09'
	btfsc STATUS,C
	goto cont_0
	movlw h'00'					;C=0 negativo mayor a 9
	movwf c0
	movf c1,0
	sublw d'09'
	btfsc STATUS,C
	goto cont_1	
	movlw h'00'					;C=0 negativo mayor a 9
	movwf c1
	incf c2
	goto verifica				
	
cont_0:
	incf c0
	incf c0
	goto verifica
cont_1:
	incf c1
	goto verifica
imprime:
	end