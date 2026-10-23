extends Control

## ============================================================================
## step_1_base.gd — Sala de lectura (estante auto-poblado)
## ============================================================================
## Los lomos del estante ya no están puestos a mano en la escena: se construyen
## recorriendo los ejemplares que el catálogo tiene en el estante activo. Pasar
## de cuatro libros a diecisiete no costó ni un nodo nuevo.
##
## La pantalla sigue siendo puramente reactiva: publica intenciones y se
## repinta con lo que llega del bus. No decide plazos, no sabe cuántos días
## compromete un préstamo y no conoce al gestor.
## ----------------------------------------------------------------------------

const ICONO_LIBRO: Texture2D = preload("res://src/assets/ui/icons/ic_libro.png")

## Ancho mínimo de cada lomo. Define cuántos caben por fila sin apretarse.
const ANCHO_LOMO: float = 240.0

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var grid_libros: GridContainer = $MarginContainer/VBoxContainer/ScrollEstante/GridLibros
@onready var lbl_estante: Label = $MarginContainer/VBoxContainer/LblEstante
@onready var lbl_libro: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblLibro
@onready var lbl_datos: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblDatos
@onready var lbl_sinopsis: Label = $MarginContainer/VBoxContainer/FichaLibro/MarginFicha/VBoxFicha/LblSinopsis
@onready var lbl_estado: Label = $MarginContainer/VBoxContainer/LblEstado
@onready var lbl_total: Label = $MarginContainer/VBoxContainer/LblTotal
@onready var btn_plazo_diario: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoDiario
@onready var btn_plazo_quincenal: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoQuincenal
@onready var btn_plazo_mensual: Button = $MarginContainer/VBoxContainer/PlazosContainer/BtnPlazoMensual
@onready var btn_cerrar: Button = $MarginContainer/VBoxContainer/BtnCerrar
@onready var ficha_libro: PanelContainer = $MarginContainer/VBoxContainer/FichaLibro

## Ejemplar abierto. Dato de presentación: quién está en consulta de verdad lo
## sabe el gestor, que lo publica por `consultation_changed`.
var _libro_seleccionado: String = ""

## Estado del ciclo recibido del bus. La sala lo representa, no lo decide.
var _estado_ciclo: String = EventBus.ESTADO_EN_ESTANTE

## Registro de préstamos vigentes, para marcar los lomos que ya salieron.
var _prestados: Dictionary = {}

## Verdadero mientras el mostrador registra o confirma un préstamo.
var _estante_ocupado: bool = false

## Mapa id de ejemplar → lomo construido. Se rehace con cada estante.
var _lomos: Dictionary = {}


func _ready() -> void:
	print("[step_1_base] Sala de lectura montada.")

	btn_plazo_diario.pressed.connect(_on_plazo_pressed.bind("diario"))
	btn_plazo_quincenal.pressed.connect(_on_plazo_pressed.bind("quincenal"))
	btn_plazo_mensual.pressed.connect(_on_plazo_pressed.bind("mensual"))
	btn_cerrar.pressed.connect(_on_cerrar_pressed)

	# Suscripción reactiva: la interfaz se actualiza de forma pasiva.
	EventBus.total_changed.connect(_on_total_changed)
	EventBus.loan_state_changed.connect(_on_loan_state_changed)
	EventBus.loan_result.connect(_on_loan_result)
	EventBus.consultation_changed.connect(_on_consultation_changed)
	EventBus.loans_updated.connect(_on_loans_updated)
	EventBus.category_changed.connect(_on_category_changed)

	_limpiar_ficha()


# --- Construcción dinámica del estante --------------------------------------

## Levanta un lomo por cada ejemplar del estante activo. Es el auto-poblado:
## el número de botones lo decide el catálogo, no la escena.
func _poblar_estante(categoria_id: String) -> void:
	for hijo: Node in grid_libros.get_children():
		hijo.queue_free()
	_lomos.clear()

	var catalogo: CatalogoBiblioteca = GlobalManager.CATALOGO
	var categoria: CategoriaData = catalogo.buscar_categoria(categoria_id)

	if categoria == null:
		lbl_estante.text = "Vuelve a los estantes y elige uno para ver sus ejemplares."
		return

	lbl_estante.text = "%s — %s" % [categoria.nombre, categoria.descripcion]

	var indice: int = 0
	for libro: LibroData in catalogo.libros_de(categoria_id):
		var lomo: Button = _crear_lomo(libro)
		grid_libros.add_child(lomo)
		_lomos[libro.id] = lomo
		_animar_entrada_lomo(lomo, indice)
		indice += 1

	print("[step_1_base] %d ejemplares construidos para el estante %s." % [indice, categoria_id])
	_actualizar_estante()


## Arma el botón de un ejemplar a partir de su recurso.
func _crear_lomo(libro: LibroData) -> Button:
	var lomo: Button = Button.new()
	lomo.text = libro.titulo
	lomo.icon = ICONO_LIBRO
	lomo.custom_minimum_size = Vector2(ANCHO_LOMO, 64)
	lomo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lomo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lomo.pressed.connect(_on_libro_pressed.bind(libro.id))
	return lomo


## Un lomo se puede tomar solo si el ejemplar está disponible y el mostrador no
## está ocupado. Avisarlo en el propio botón evita que el lector descubra que el
## libro ya salió solo después de elegir un plazo.
func _actualizar_estante() -> void:
	var catalogo: CatalogoBiblioteca = GlobalManager.CATALOGO

	for item_id: String in _lomos.keys():
		var lomo: Button = _lomos[item_id]
		var libro: LibroData = catalogo.buscar_libro(item_id)
		if libro == null:
			continue

		var prestado: bool = _prestados.has(item_id)
		lomo.disabled = _estante_ocupado or prestado
		lomo.text = libro.titulo
		if prestado:
			lomo.text += "  ·  prestado"
		lomo.tooltip_text = "Este ejemplar está fuera de la sala." if prestado else libro.autor


# --- Emisión de intenciones -------------------------------------------------

## Publica la intención de sacar el ejemplar del estante para consultarlo.
func _on_libro_pressed(item_id: String) -> void:
	print("[step_1_base] Intención item_opened -> " + item_id)
	EventBus.item_opened.emit(item_id)


## Publica el plazo elegido. El gestor arma con él el borrador del préstamo y
## abre el comprobante; esta pantalla no registra nada.
func _on_plazo_pressed(base_name: String) -> void:
	if _libro_seleccionado.is_empty():
		lbl_estado.text = "Abre un ejemplar del estante antes de elegir el plazo."
		return

	print("[step_1_base] Intención base_selected -> " + base_name)
	EventBus.base_selected.emit(base_name)


## Publica la intención de devolver el ejemplar al estante sin llevárselo.
func _on_cerrar_pressed() -> void:
	print("[step_1_base] Intención item_closed")
	EventBus.item_closed.emit()


# --- Reacción a los eventos del bus -----------------------------------------

## Repuebla el estante cuando cambia la categoría que se está recorriendo.
func _on_category_changed(category_id: String) -> void:
	_poblar_estante(category_id)


## Refresca el total sin conocer cómo ni quién lo calculó.
func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Días comprometidos en préstamo: %d" % new_total


## Guarda qué ejemplares están prestados para reflejarlo en el estante.
func _on_loans_updated(loans: Dictionary) -> void:
	_prestados = loans
	_actualizar_estante()


## Reacciona al estado del ciclo: habilita lo que ese estado permite y, cuando
## el gestor abre el comprobante, lleva al lector hasta él.
func _on_loan_state_changed(state_name: String) -> void:
	_estado_ciclo = state_name
	print("[step_1_base] Estado del ciclo recibido: " + state_name)

	var en_consulta: bool = state_name == EventBus.ESTADO_EN_CONSULTA
	_estante_ocupado = state_name != EventBus.ESTADO_EN_ESTANTE and not en_consulta

	_actualizar_estante()

	for boton: Button in [btn_plazo_diario, btn_plazo_quincenal, btn_plazo_mensual]:
		boton.disabled = not en_consulta
	btn_cerrar.disabled = not en_consulta

	match state_name:
		EventBus.ESTADO_EN_COMPROBANTE:
			# El borrador ya está armado: el comprobante es la pantalla que lo
			# muestra y permite confirmarlo.
			EventBus.navigation_requested.emit(EventBus.RUTA_COMPROBANTE, false)
		EventBus.ESTADO_EN_ESTANTE:
			lbl_estado.remove_theme_color_override("font_color")


## Muestra el veredicto del mostrador: el gestor dice qué pasó, la sala lo pinta.
func _on_loan_result(success: bool, message: String) -> void:
	# El prefijo en texto evita que el veredicto dependa solo del color.
	lbl_estado.text = ("Listo · " if success else "Atención · ") + message

	if not success:
		lbl_estado.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
		_animar_resultado()
	else:
		lbl_estado.add_theme_color_override("font_color", Color(0.75, 0.9, 0.78))


## Restaura o limpia la ficha según cuál sea el ejemplar en consulta. Esto es
## lo que permite salir del panel a mitad de una consulta y volver sin perderla.
func _on_consultation_changed(item_id: String) -> void:
	_libro_seleccionado = item_id

	if item_id.is_empty():
		_limpiar_ficha()
		return

	_mostrar_ficha(item_id)


# --- Animaciones programáticas (Tween) --------------------------------------

## Los lomos entran escalonados, de modo que se ve que el estante se construye
## a partir del catálogo en vez de estar dibujado de antemano.
func _animar_entrada_lomo(lomo: Button, indice: int) -> void:
	lomo.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_interval(indice * 0.04)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(lomo, "modulate:a", 1.0, 0.22)


## La ficha destella cuando el mostrador rechaza algo, para que el aviso se note.
func _animar_resultado() -> void:
	ficha_libro.pivot_offset = ficha_libro.size / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ficha_libro, "scale", Vector2(1.015, 1.015), 0.12)
	tween.tween_property(ficha_libro, "scale", Vector2.ONE, 0.18)


## Resalta el ejemplar abierto dentro del estante.
func _animar_apertura(lomo: Button) -> void:
	lomo.pivot_offset = lomo.size / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lomo, "scale", Vector2(1.05, 1.05), 0.14)
	tween.tween_property(lomo, "scale", Vector2.ONE, 0.14)


# --- Presentación -----------------------------------------------------------

## Despliega la ficha del ejemplar abierto con los datos de su recurso.
func _mostrar_ficha(item_id: String) -> void:
	var libro: LibroData = GlobalManager.CATALOGO.buscar_libro(item_id)
	if libro == null:
		return

	lbl_libro.text = "%s — %s" % [libro.titulo, libro.autor]
	lbl_datos.text = "%d  ·  %d páginas" % [libro.anio, libro.paginas]
	lbl_sinopsis.text = libro.sinopsis

	if _lomos.has(item_id):
		_animar_apertura(_lomos[item_id])


## Restablece la ficha a su estado vacío.
func _limpiar_ficha() -> void:
	lbl_libro.text = "Ningún libro abierto"
	lbl_datos.text = ""
	lbl_sinopsis.text = "Selecciona un libro del estante para leer su descripción."
	lbl_estado.text = "Abre un libro y elige su plazo de préstamo."
