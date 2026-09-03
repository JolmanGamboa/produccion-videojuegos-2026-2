extends Control

## ============================================================================
## credits_panel.gd — Créditos y autoría del proyecto
## ============================================================================
## Panel puramente informativo. Igual que los demás, regresa al vestíbulo
## publicando un evento en el bus global en lugar de cambiar la escena él mismo.
## ----------------------------------------------------------------------------

# --- Datos del autor (fuente única de verdad para la pantalla) --------------
const AUTOR: String = "Jolman Harley Gamboa Salamanca"
const CODIGO: String = "12242525509"
const PROGRAMA: String = "Ingeniería de Software — Universidad Antonio Nariño"
const ASIGNATURA: String = "Producción de Videojuegos (Sistemas Interactivos) 2026-2"

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lbl_datos: Label = $MarginContainer/VBoxContainer/LblDatos
@onready var btn_volver: Button = $MarginContainer/VBoxContainer/BtnVolver


func _ready() -> void:
	print("[credits_panel] Panel de créditos montado.")

	lbl_datos.text = "%s\nCódigo: %s\n%s\n%s" % [AUTOR, CODIGO, PROGRAMA, ASIGNATURA]
	btn_volver.pressed.connect(_on_btn_volver_pressed)


## Regresa al vestíbulo publicando una solicitud de navegación.
func _on_btn_volver_pressed() -> void:
	EventBus.navigation_requested.emit(EventBus.RUTA_MENU)
