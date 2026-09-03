extends Control

## ============================================================================
## config_panel.gd — Configuración de parámetros de la biblioteca
## ============================================================================
## Este panel es el único emisor de `EventBus.parameter_changed`. No sabe quién
## consume los datos: `MainApp` los persiste y la sala de lectura los aplica.
## ----------------------------------------------------------------------------

## Claves de estante en el mismo orden en que se listan en el OptionButton.
const CLAVES_ESTANTE: Array = [
	"ciencia_ficcion",
	"realismo_magico",
	"ingenieria_software"
]

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var opt_estante: OptionButton = $MarginContainer/VBoxContainer/GridContainer/OptEstante
@onready var sld_tamano: HSlider = $MarginContainer/VBoxContainer/GridContainer/SldTamano
@onready var lbl_estado: Label = $MarginContainer/VBoxContainer/LblEstado
@onready var btn_volver: Button = $MarginContainer/VBoxContainer/BtnVolver


func _ready() -> void:
	print("[config_panel] Panel de configuración montado.")

	opt_estante.item_selected.connect(_on_estante_seleccionado)
	sld_tamano.value_changed.connect(_on_tamano_cambiado)
	btn_volver.pressed.connect(_on_btn_volver_pressed)

	_refrescar_estado()


# --- Emisión de eventos de configuración ------------------------------------

## Publica el cambio de estante temático en el bus global.
func _on_estante_seleccionado(indice: int) -> void:
	var clave: String = CLAVES_ESTANTE[indice]
	EventBus.parameter_changed.emit(EventBus.PARAM_ESTANTE, clave)
	_refrescar_estado()


## Publica el nuevo tamaño de letra de las sinopsis.
func _on_tamano_cambiado(valor: float) -> void:
	EventBus.parameter_changed.emit(EventBus.PARAM_TAMANO_TEXTO, int(valor))
	_refrescar_estado()


## Regresa al vestíbulo publicando una solicitud de navegación.
func _on_btn_volver_pressed() -> void:
	EventBus.navigation_requested.emit(EventBus.RUTA_MENU)


# --- Contrato con MainApp ---------------------------------------------------

## Restituye los valores ya elegidos por el usuario en sesiones anteriores del
## panel. Se usa `set_value_no_signal()` para no reemitir eventos redundantes.
func aplicar_parametro(param_name: String, value: Variant) -> void:
	match param_name:
		EventBus.PARAM_ESTANTE:
			var indice: int = CLAVES_ESTANTE.find(str(value))
			if indice != -1:
				opt_estante.selected = indice
		EventBus.PARAM_TAMANO_TEXTO:
			sld_tamano.set_value_no_signal(float(value))
	_refrescar_estado()


# --- Presentación -----------------------------------------------------------

## Refleja en pantalla la configuración vigente.
func _refrescar_estado() -> void:
	lbl_estado.text = "Estante activo: %s   |   Tamaño de sinopsis: %d px" % [
		opt_estante.get_item_text(opt_estante.selected),
		int(sld_tamano.value)
	]
