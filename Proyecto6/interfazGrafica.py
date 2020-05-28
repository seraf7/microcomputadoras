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
def progress(dato):
    progressbar["value"]=currentValue




#Creamos ventana y damos dimensiones
ventana = Tk()
ventana.geometry('700x550')
ventana.configure(bg = 'black')
ventana.title("Volmetro")


progressbar=ttk.Progressbar(ventana,orient="horizontal",length=300,mode="determinate")

dato=puerto.read(3)	
cadena=dato.decode("utf-8") 

#Imagenes que usaremos
logoFI=PhotoImage(file="escudo_fi_color.png")
logoUNAM=PhotoImage(file="escudounam_negro.png")

#Definicion de etiquetas 
titulo = Label( ventana, text="Volmetro \n PIC16F887A", relief=RAISED, fg="green", bg='black', justify=CENTER, font=("fixedsys", 34),
	highlightcolor='white')
pantallaOn=Label( ventana, text="PWM: "+cadena+"/255", relief=RAISED, fg="green", bg='white', justify=CENTER, font=("fixedsys", 50),
	highlightcolor='white')


fiLbl = Label(ventana, image=logoFI)
unamLbl= Label(ventana, image=logoUNAM)
integrantes =Label(ventana, text="Elaborado por:\nCastillo López Humberto Serafín\nGarcía Racilla Sandra",justify=CENTER, fg="green",font=("fixedsys", 10), bg="black")



#Definimos botones





#Inicializamos objetos
titulo.pack(padx=1, pady=15)
#Ubicamos a los objetos en lugar especifico en la ventana
integrantes.place(x=220, y=450)
fiLbl.place(x=75, y=450)
unamLbl.place(x=500, y=450)
pantallaOn.pack(padx=10, pady=10)
progressbar.pack(padx=10, pady=10)

maxValue=255

while True:
	dato=puerto.read(3)
	cadena=dato.decode("utf-8") 
	pantallaOn['text']="PWM: "+cadena+"/255"
	currentValue=int(cadena)
	progressbar["value"]=currentValue
	progressbar["maximum"]=maxValue
	progressbar.after(500, progress(currentValue))
	progressbar.update()




#dato=puerto.readline()	
#print(dato)
#Inicio del programa
ventana.mainloop()

#Cerrar conexion
puerto.close()
print("Puerto Cerrado")


#sys.exit(0)