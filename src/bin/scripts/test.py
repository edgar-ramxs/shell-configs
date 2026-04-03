import customtkinter as ctk
from tkinter import messagebox
import sys

# Configurar apariencia
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Configurar ventana
        self.title("App de Ejemplo - WSL2")
        self.geometry("600x400")
        
        # Crear grid layout
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)
        
        # Frame principal
        self.main_frame = ctk.CTkFrame(self)
        self.main_frame.grid(row=0, column=0, padx=20, pady=20, sticky="nsew")
        self.main_frame.grid_columnconfigure(0, weight=1)
        
        # Título
        self.title_label = ctk.CTkLabel(
            self.main_frame,
            text="Aplicación Python en WSL2",
            font=ctk.CTkFont(size=24, weight="bold")
        )
        self.title_label.grid(row=0, column=0, padx=20, pady=20)
        
        # Entry para nombre
        self.name_label = ctk.CTkLabel(
            self.main_frame,
            text="Ingresa tu nombre:",
            font=ctk.CTkFont(size=14)
        )
        self.name_label.grid(row=1, column=0, padx=20, pady=(10, 5))
        
        self.name_entry = ctk.CTkEntry(
            self.main_frame,
            placeholder_text="Tu nombre aquí",
            width=300
        )
        self.name_entry.grid(row=2, column=0, padx=20, pady=5)
        
        # Slider
        self.slider_label = ctk.CTkLabel(
            self.main_frame,
            text="Selecciona un valor:",
            font=ctk.CTkFont(size=14)
        )
        self.slider_label.grid(row=3, column=0, padx=20, pady=(20, 5))
        
        self.slider = ctk.CTkSlider(
            self.main_frame,
            from_=0,
            to=100,
            width=300,
            command=self.slider_callback
        )
        self.slider.set(50)
        self.slider.grid(row=4, column=0, padx=20, pady=5)
        
        self.slider_value_label = ctk.CTkLabel(
            self.main_frame,
            text="Valor: 50",
            font=ctk.CTkFont(size=12)
        )
        self.slider_value_label.grid(row=5, column=0, padx=20, pady=5)
        
        # Switch
        self.switch = ctk.CTkSwitch(
            self.main_frame,
            text="Modo oscuro",
            command=self.switch_callback
        )
        self.switch.select()
        self.switch.grid(row=6, column=0, padx=20, pady=20)
        
        # Botón principal
        self.submit_button = ctk.CTkButton(
            self.main_frame,
            text="Saludar",
            command=self.submit_action,
            width=200,
            height=40
        )
        self.submit_button.grid(row=7, column=0, padx=20, pady=10)
        
        # Label de resultado
        self.result_label = ctk.CTkLabel(
            self.main_frame,
            text="",
            font=ctk.CTkFont(size=14),
            text_color="green"
        )
        self.result_label.grid(row=8, column=0, padx=20, pady=10)
    
    def slider_callback(self, value):
        self.slider_value_label.configure(text=f"Valor: {int(value)}")
    
    def switch_callback(self):
        if self.switch.get():
            ctk.set_appearance_mode("dark")
        else:
            ctk.set_appearance_mode("light")
    
    def submit_action(self):
        name = self.name_entry.get()
        slider_val = int(self.slider.get())
        
        if name.strip():
            message = f"¡Hola {name}! Tu valor seleccionado es {slider_val}"
            self.result_label.configure(text=message, text_color="green")
        else:
            self.result_label.configure(text="Por favor ingresa un nombre", text_color="red")

if __name__ == "__main__":
    try:
        app = App()
        app.mainloop()
    except Exception as e:
        print(f"Error: {e}")
        print("\n--- Instrucciones para WSL2 ---")
        print("1. Instala un servidor X en Windows: VcXsrv o X410")
        print("2. Inicia el servidor X en Windows")
        print("3. En WSL2, ejecuta: export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0")
        print("4. Ejecuta de nuevo este script")
        sys.exit(1)
