extends Control

# --- Captura de nodos en caché (operador $ solo aquí, nunca en bucles) ---
@onready var lbl_titulo: Label = $MarginContainer/VBoxContainer/LblTitulo
@onready var btn_simular: Button = $MarginContainer/VBoxContainer/BtnSimular
@onready var btn_salir: Button = $MarginContainer/VBoxContainer/BtnSalir


func _ready() -> void:
	print("[main] Sistema interactivo inicializado con éxito.")
	lbl_titulo.text = "Simulador Interactivo de Producción"

	# Conexión local por código de la señal de salida del sistema.
	btn_salir.pressed.connect(_on_btn_salir_pressed)


func _on_btn_salir_pressed() -> void:
	print("[main] Cerrando el sistema y liberando recursos...")
	get_tree().quit()
