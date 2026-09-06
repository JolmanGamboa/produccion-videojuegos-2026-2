extends Control

## ============================================================================
## menu_panel.gd — Vestíbulo de la Biblioteca Interactiva
## ============================================================================
## Este panel NO conoce ninguna otra escena ni llama a `change_scene_to_file()`.
## Solo publica solicitudes de navegación en el bus global; MainApp decide.
## ----------------------------------------------------------------------------

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lbl_titulo: Label = $MarginContainer/VBoxContainer/LblTitulo
@onready var btn_sala: Button = $MarginContainer/VBoxContainer/BtnSala
@onready var btn_config: Button = $MarginContainer/VBoxContainer/BtnConfig
@onready var btn_creditos: Button = $MarginContainer/VBoxContainer/BtnCreditos
@onready var btn_salir: Button = $MarginContainer/VBoxContainer/BtnSalir


func _ready() -> void:
	print("[menu_panel] Vestíbulo de la biblioteca montado.")
	lbl_titulo.text = "Biblioteca Interactiva"

	# Reactividad parametrizada: un único callback cohesivo recibe la ruta
	# destino mediante bind(), evitando una función por botón.
	btn_sala.pressed.connect(_on_navegar_pressed.bind(EventBus.RUTA_SALA_LECTURA))
	btn_config.pressed.connect(_on_navegar_pressed.bind(EventBus.RUTA_CONFIG))
	btn_creditos.pressed.connect(_on_navegar_pressed.bind(EventBus.RUTA_CREDITOS))
	btn_salir.pressed.connect(_on_btn_salir_pressed)


## Publica la solicitud de navegación en el canal global.
func _on_navegar_pressed(ruta_destino: String) -> void:
	print("[menu_panel] Publicando navigation_requested -> " + ruta_destino)
	EventBus.navigation_requested.emit(ruta_destino)


## Cierre limpio de la aplicación liberando los recursos del equipo.
func _on_btn_salir_pressed() -> void:
	print("[menu_panel] Cerrando la biblioteca y liberando recursos...")
	get_tree().quit()
