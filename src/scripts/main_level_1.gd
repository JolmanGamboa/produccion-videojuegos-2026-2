extends Control


@onready var lbl_status_local: Label = $MarginContainer/VBoxContainer/LblStatusLocal
@onready var btn_ingrediente_1: Button = $MarginContainer/VBoxContainer/GridContainer/BtnIngrediente1
@onready var btn_ingrediente_2: Button = $MarginContainer/VBoxContainer/GridContainer/BtnIngrediente2


func _ready() -> void:
	print("[main_level_1] Entorno de simulación cargado.")
	lbl_status_local.text = "Selección: ninguna"

	btn_ingrediente_1.pressed.connect(_on_ingrediente_selected.bind("Harina", 1500))
	btn_ingrediente_2.pressed.connect(_on_ingrediente_selected.bind("Azúcar", 900))


func _on_ingrediente_selected(nombre: String, costo: int) -> void:
	var mensaje: String = "Selección: %s (+$%d)" % [nombre, costo]
	lbl_status_local.text = mensaje
	print("[main_level_1] " + mensaje)
