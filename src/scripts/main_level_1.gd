extends Control

## Controlador de la pantalla de selección de simulación (main_level_1.tscn).
## Demuestra reactividad local parametrizada: dos botones distintos se conectan
## a una única función controladora altamente cohesiva mediante .bind().

# --- Captura de nodos en caché (operador $ solo en la declaración @onready) ---
@onready var lbl_status_local: Label = $MarginContainer/VBoxContainer/LblStatusLocal
@onready var btn_ingrediente_1: Button = $MarginContainer/VBoxContainer/GridContainer/BtnIngrediente1
@onready var btn_ingrediente_2: Button = $MarginContainer/VBoxContainer/GridContainer/BtnIngrediente2


func _ready() -> void:
	print("[main_level_1] Entorno de simulación cargado.")
	lbl_status_local.text = "Selección: ninguna"

	# Reactividad local parametrizada: un mismo callback recibe datos distintos.
	btn_ingrediente_1.pressed.connect(_on_ingrediente_selected.bind("Harina", 1500))
	btn_ingrediente_2.pressed.connect(_on_ingrediente_selected.bind("Azúcar", 900))


## Callback unificado que recibe los parámetros inyectados con bind().
func _on_ingrediente_selected(nombre: String, costo: int) -> void:
	var mensaje: String = "Selección: %s (+$%d)" % [nombre, costo]
	lbl_status_local.text = mensaje
	print("[main_level_1] " + mensaje)
