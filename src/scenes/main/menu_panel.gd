extends Control

## ============================================================================
## menu_panel.gd — Vestíbulo de la Biblioteca Interactiva
## ============================================================================
## La navegación hacia los demás entornos se resuelve de forma declarativa con
## instancias del componente `ButtonNav`, parametrizadas desde el Inspector.
## Este script conserva únicamente la responsabilidad que no es navegación:
## cerrar la aplicación de manera limpia.
## ----------------------------------------------------------------------------

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var btn_salir: Button = $MarginContainer/VBoxContainer/BtnSalir


func _ready() -> void:
	print("[menu_panel] Vestíbulo de la biblioteca montado.")
	btn_salir.pressed.connect(_on_btn_salir_pressed)


## Cierre limpio de la aplicación liberando los recursos del equipo.
func _on_btn_salir_pressed() -> void:
	print("[menu_panel] Cerrando la biblioteca y liberando recursos...")
	get_tree().quit()
