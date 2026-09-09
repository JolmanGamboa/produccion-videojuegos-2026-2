extends Control

## ============================================================================
## step_1_base.gd — Sala de lectura (Pantalla de simulación, Paso 1)
## ============================================================================
## Interfaz puramente reactiva. NO decide plazos, NO lleva la cuenta de qué
## libros están prestados y NO conoce al `GlobalManager`: solo publica
## intenciones en el `EventBus` y escucha `total_changed` para refrescar su
## etiqueta de días comprometidos.
##
## El único dato que conserva es de presentación: cuál lomo está seleccionado
## en el estante, que no participa en ningún cálculo.
##
## Flujo de uso: el lector abre un libro del estante (ve su ficha) y elige uno
## de los tres plazos de la parte inferior para llevárselo en préstamo.
## ----------------------------------------------------------------------------

## Catálogo de presentación. Los plazos y el registro NO viven aquí.
const LIBROS: Dictionary = {
	"dune": {
		"titulo": "Dune",
		"autor": "Frank Herbert",
		"anio": 1965,
		"sinopsis": "En el planeta desértico Arrakis, la casa Atreides queda atrapada en una guerra por el control de la especia, el recurso más valioso del universo conocido."
	},
	"neuromante": {
		"titulo": "Neuromante",
		"autor": "William Gibson",
		"anio": 1984,
		"sinopsis": "Un antiguo pirata informático recibe una última oportunidad de volver al ciberespacio, a cambio de asaltar una inteligencia artificial que nadie debería despertar."
	},
	"cien_anios": {
		"titulo": "Cien años de soledad",
		"autor": "Gabriel García Márquez",
		"anio": 1967,
		"sinopsis": "La crónica de siete generaciones de la familia Buendía en Macondo, donde lo extraordinario ocurre con la misma naturalidad que la lluvia."
	},
	"pragmatico": {
		"titulo": "El programador pragmático",
		"autor": "Hunt y Thomas",
		"anio": 1999,
		"sinopsis": "Un compendio de prácticas concretas para escribir código que resista el cambio, desde el principio DRY hasta la automatización del trabajo repetitivo."
	}
}

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var btn_dune: Button = $MarginContainer/VBoxContainer/GridLibros/BtnDune
@onready var btn_neuromante: Button = $MarginContainer/VBoxContainer/GridLibros/BtnNeuromante
@onready var btn_cien_anios: Button = $MarginContainer/VBoxContainer/GridLibros/BtnCienAnios
@onready var btn_pragmatico: Button = $MarginContainer/VBoxContainer/GridLibros/BtnPragmatico
@onready var lbl_libro: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblLibro
@onready var lbl_sinopsis: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblSinopsis
@onready var lbl_estado: Label = $MarginContainer/VBoxContainer/LblEstado
@onready var lbl_total: Label = $MarginContainer/VBoxContainer/LblTotal
@onready var btn_plazo_diario: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoDiario
@onready var btn_plazo_quincenal: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoQuincenal
@onready var btn_plazo_mensual: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoMensual

## Lomo seleccionado en el estante. Estado de presentación, no de negocio.
var _libro_seleccionado: String = ""


func _ready() -> void:
	print("[step_1_base] Sala de lectura montada.")

	# Mapeo programático de las intenciones: un único callback cohesivo por
	# tipo de acción, parametrizado con bind() en lugar de una función por
	# botón. La interfaz no decide nada, solo publica.
	btn_dune.pressed.connect(_on_libro_pressed.bind("dune"))
	btn_neuromante.pressed.connect(_on_libro_pressed.bind("neuromante"))
	btn_cien_anios.pressed.connect(_on_libro_pressed.bind("cien_anios"))
	btn_pragmatico.pressed.connect(_on_libro_pressed.bind("pragmatico"))

	btn_plazo_diario.pressed.connect(_on_plazo_pressed.bind("diario"))
	btn_plazo_quincenal.pressed.connect(_on_plazo_pressed.bind("quincenal"))
	btn_plazo_mensual.pressed.connect(_on_plazo_pressed.bind("mensual"))

	# Suscripción reactiva: la etiqueta se actualiza de forma pasiva.
	EventBus.total_changed.connect(_on_total_changed)

	_limpiar_ficha()


# --- Emisión de intenciones -------------------------------------------------

## Abre el libro del estante y lo deja listo para prestar.
func _on_libro_pressed(item_id: String) -> void:
	_libro_seleccionado = item_id
	_mostrar_ficha(item_id)
	lbl_estado.text = "Elige un plazo para llevarte este ejemplar."
	print("[step_1_base] Libro abierto: " + item_id)


## Publica el plazo elegido y la intención de llevarse el libro abierto.
func _on_plazo_pressed(base_name: String) -> void:
	if _libro_seleccionado.is_empty():
		lbl_estado.text = "Primero abre un libro del estante."
		return

	print("[step_1_base] Intenciones base_selected(%s) e item_added(%s)" % [base_name, _libro_seleccionado])
	EventBus.base_selected.emit(base_name)
	EventBus.item_added.emit(_libro_seleccionado)

	lbl_estado.text = "«%s» registrado en préstamo con plazo %s." % [
		str(LIBROS[_libro_seleccionado]["titulo"]),
		base_name
	]


# --- Reacción a los eventos del bus -----------------------------------------

## Refresca el total sin conocer cómo ni quién lo calculó.
func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Días comprometidos en préstamo: %d" % new_total


# --- Presentación -----------------------------------------------------------

## Despliega la ficha del ejemplar abierto.
func _mostrar_ficha(item_id: String) -> void:
	var libro: Dictionary = LIBROS[item_id]
	lbl_libro.text = "%s — %s (%d)" % [libro["titulo"], libro["autor"], libro["anio"]]
	lbl_sinopsis.text = str(libro["sinopsis"])


## Restablece la ficha a su estado vacío.
func _limpiar_ficha() -> void:
	lbl_libro.text = "Ningún libro abierto"
	lbl_sinopsis.text = "Selecciona un libro del estante para leer su descripción."
	lbl_estado.text = "Abre un libro y elige su plazo de préstamo."
