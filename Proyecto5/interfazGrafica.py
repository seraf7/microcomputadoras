#Libreria comunicacion serial
#Para instalarla ejecuta siguiente linea en consola
#  python -m pip install PySerial
import serial,time

#Bibliotecas Interfaz
from tkinter import *
from tkinter import ttk
from tkinter import filedialog
from tkinter import messagebox
import tkinter 


#Creamos puerto serial
puerto=serial.Serial('COM1',9600)
#Tiempo hasta recibir caracter
puerto.timeout=3
time.sleep(2)
print("Conexion establecida")


#Definicion de funciones
def recibe():
	dato=puerto.readline()
	senial=dato.decode("utf-8") 
	pantallaOn['text']=dato
	if(senial=="$"): #Interrupción
		interrupcion()
	else:
		print("Sigue sensando\n")


def hexa():
	print("Hexadecimal")
	opcion=str(1)
	cadena=opcion.encode('utf-8')
	puerto.write(cadena)
	recibe()

def deci():
	opcion=str(0)
	cadena=opcion.encode('utf-8')
	puerto.write(cadena)
	print("Decimal")
	recibe()

def bina():
	print("Binario")
	opcion=str(2)
	cadena=opcion.encode('utf-8')
	puerto.write(cadena)
	recibe()

def volt():
	print("Volt")
	opcion=str(3)
	cadena=opcion.encode('utf-8')
	puerto.write(cadena)
	recibe()

def interrupcion():
	print("Interrupción\n")
	pantallaOn.pack_forget()
	pantallaOn.place_forget()
	dec_btn.pack_forget()
	dec_btn.place_forget()
	hexa_btn.pack_forget()
	hexa_btn.place_forget()
	bin_btn.pack_forget()
	bin_btn.place_forget()
	volt_btn.pack_forget()
	volt_btn.place_forget()
	pantallaInt.pack(padx=10, pady=10)





#Creamos ventana y damos dimensiones
ventana = Tk()
ventana.geometry('700x550')
ventana.configure(bg = 'black')
ventana.title("Volmetro")

dato=puerto.readline()
print(dato,"\n")


#Imagenes que usaremos
logoFI=PhotoImage(file="escudo_fi_color.png")
logoUNAM=PhotoImage(file="escudounam_negro.png")

#Definicion de etiquetas 
titulo = Label( ventana, text="Volmetro \n PIC16F887A", relief=RAISED, fg="green", bg='black', justify=CENTER, font=("fixedsys", 34),
	highlightcolor='white')
pantallaOn=Label( ventana, text=dato, relief=RAISED, fg="green", bg='white', justify=CENTER, font=("fixedsys", 50),
	highlightcolor='white')
pantallaInt=Label( ventana, text="TIEMPO TERMINADO", relief=RAISED, fg="red", bg='gray', justify=CENTER, font=("fixedsys", 50),
	highlightcolor='white')
fiLbl = Label(ventana, image=logoFI)
unamLbl= Label(ventana, image=logoUNAM)
integrantes =Label(ventana, text="Elaborado por:\nCastillo López Humberto Serafín\nGarcía Racilla Sandra",justify=CENTER, fg="green",font=("fixedsys", 10), bg="black")


#Definimos botones
hexa_btn = Button(ventana, text="Hexadecimal",width=15, justify=CENTER, command=hexa)
dec_btn = Button(ventana, text="Decimal",width=15, justify=CENTER, command=deci)
bin_btn = Button(ventana, text="Binario",width=15, justify=CENTER, command=bina)
volt_btn = Button(ventana, text="Volt",width=15, justify=CENTER, command=volt)

#Inicializamos objetos
titulo.pack(padx=1, pady=15)
pantallaOn.pack(padx=10, pady=10)

#Ubicamos a los objetos en lugar especifico en la ventana
integrantes.place(x=220, y=450)
fiLbl.place(x=75, y=450)
unamLbl.place(x=500, y=450)
dec_btn.place(x= 40,y=200)
hexa_btn.place(x= 40,y=230)
bin_btn.place(x= 40,y=260)
volt_btn.place(x= 40,y=290)

pantallaOn.after(1000,recibe)

ventana.after(0, recibe)
#dato=puerto.readline()	
#print(dato)
#Inicio del programa
ventana.mainloop()

#Cerrar conexion
puerto.close()
print("Puerto Cerrado")


#sys.exit(0)
