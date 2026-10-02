extends Control

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
@onready var btn_cerrar: Button = $MarginContainer/VBoxContainer/BtnCerrar
@onready var ficha_libro: PanelContainer = $MarginContainer/VBoxContainer/FichaLibro

## Lomo abierto en el estante. Estado de presentación, no de negocio: quién
## está en consulta de verdad lo sabe el GlobalManager.
var _libro_seleccionado: String = ""

## Estado del ciclo del ejemplar recibido del bus. La sala lo representa, no lo
## decide: habilita o bloquea sus controles y anima según lo que llega.
var _estado_ciclo: String = EventBus.ESTADO_EN_ESTANTE


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

	btn_cerrar.pressed.connect(_on_cerrar_pressed)

	# Suscripción reactiva: la interfaz se actualiza de forma pasiva.
	EventBus.total_changed.connect(_on_total_changed)
	EventBus.loan_state_changed.connect(_on_loan_state_changed)
	EventBus.loan_result.connect(_on_loan_result)

	_limpiar_ficha()


# --- Emisión de intenciones -------------------------------------------------

## Publica la intención de sacar el ejemplar del estante para consultarlo.
func _on_libro_pressed(item_id: String) -> void:
	_libro_seleccionado = item_id
	_mostrar_ficha(item_id)
	print("[step_1_base] Intención item_opened -> " + item_id)
	EventBus.item_opened.emit(item_id)


## Publica el plazo elegido y la intención de registrar el préstamo. Si el
## ciclo no está en consulta, el gestor descarta ambas intenciones.
func _on_plazo_pressed(base_name: String) -> void:
	print("[step_1_base] Intenciones base_selected(%s) e item_added(%s)" % [base_name, _libro_seleccionado])
	EventBus.base_selected.emit(base_name)
	EventBus.item_added.emit(_libro_seleccionado)


## Publica la intención de devolver el ejemplar al estante sin llevárselo.
func _on_cerrar_pressed() -> void:
	print("[step_1_base] Intención item_closed")
	EventBus.item_closed.emit()


# --- Reacción a los eventos del bus -----------------------------------------

## Refresca el total sin conocer cómo ni quién lo calculó.
func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Días comprometidos en préstamo: %d" % new_total


## Reacciona al estado del ciclo: habilita los controles que ese estado
## permite y dispara la animación correspondiente.
func _on_loan_state_changed(state_name: String) -> void:
	_estado_ciclo = state_name
	print("[step_1_base] Estado del ciclo recibido: " + state_name)

	var en_consulta: bool = state_name == EventBus.ESTADO_EN_CONSULTA
	var ocupado: bool = state_name == EventBus.ESTADO_REGISTRANDO or state_name == EventBus.ESTADO_PRESTADO

	# El estante solo se puede tocar cuando no hay un registro en curso.
	for boton: Button in [btn_dune, btn_neuromante, btn_cien_anios, btn_pragmatico]:
		boton.disabled = ocupado

	# Los plazos solo tienen sentido con un ejemplar abierto.
	for boton: Button in [btn_plazo_diario, btn_plazo_quincenal, btn_plazo_mensual]:
		boton.disabled = not en_consulta

	btn_cerrar.disabled = not en_consulta

	match state_name:
		EventBus.ESTADO_REGISTRANDO:
			_animar_registro()
		EventBus.ESTADO_PRESTADO:
			_animar_resultado(Color(0.45, 0.85, 0.5))
		EventBus.ESTADO_EN_ESTANTE:
			_libro_seleccionado = ""
			_limpiar_ficha()


## Muestra el veredicto del mostrador: el gestor dice qué pasó, la sala lo pinta.
func _on_loan_result(success: bool, message: String) -> void:
	lbl_estado.text = message
	if success:
		lbl_estado.add_theme_color_override("font_color", Color(0.75, 0.9, 0.78))
	else:
		lbl_estado.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
		_animar_resultado(Color(0.95, 0.5, 0.5))


# --- Animaciones programáticas (Tween) --------------------------------------

## Entrada al estado "registrando": la ficha se encoge y se atenúa, como si el
## ejemplar pasara al mostrador. Comunica que ya salió de manos del lector y
## que no se puede tocar mientras tanto.
func _animar_registro() -> void:
	ficha_libro.pivot_offset = ficha_libro.size / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ficha_libro, "scale", Vector2(0.88, 0.88), 0.3)
	tween.parallel().tween_property(ficha_libro, "modulate:a", 0.3, 0.3)
	tween.tween_property(ficha_libro, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(ficha_libro, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_on_registro_animado)


## Cierre de la animación: se restituyen los valores exactos para que ningún
## redondeo del Tween deje la ficha desalineada.
func _on_registro_animado() -> void:
	ficha_libro.scale = Vector2.ONE
	ficha_libro.modulate.a = 1.0


## El veredicto aparece con un destello de su color, para que se note sin
## tener que leerlo.
func _animar_resultado(color: Color) -> void:
	lbl_estado.add_theme_color_override("font_color", color)
	lbl_estado.pivot_offset = lbl_estado.size / 2.0
	lbl_estado.scale = Vector2(1.12, 1.12)
	lbl_estado.modulate.a = 0.2

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl_estado, "scale", Vector2.ONE, 0.35)
	tween.parallel().tween_property(lbl_estado, "modulate:a", 1.0, 0.35)


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
