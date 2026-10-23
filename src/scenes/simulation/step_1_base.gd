extends Control

## ============================================================================
## step_1_base.gd — Sala de lectura (tarjetas auto-pobladas y desplegables)
## ============================================================================
## Cada ejemplar es una tarjeta construida en tiempo de ejecución a partir del
## catálogo, con el mismo lenguaje visual que los estantes. La tarjeta nace
## compacta —título, autor, extensión— y se despliega al abrirla para mostrar
## la sinopsis y los tres plazos dentro de ella misma.
##
## Esa es la razón de la forma: antes la pantalla apilaba cuatro bloques fijos
## —estante, ficha, plazos y total— y crecía hasta no caber. Ahora el detalle
## vive dentro del ejemplar al que pertenece y solo ocupa sitio cuando se pide.
##
## La pantalla sigue siendo reactiva: publica intenciones y se repinta con lo
## que llega del bus. No decide plazos ni sabe cuántos días compromete nada.
## ----------------------------------------------------------------------------

const ICONO_LIBRO: Texture2D = preload("res://src/assets/ui/icons/ic_libro.png")
const ICONO_CERRAR: Texture2D = preload("res://src/assets/ui/icons/ic_cerrar.png")

## Plazos que ofrece cada tarjeta, en el orden en que se dibujan.
const PLAZOS: Array = [
	["diario", "Diario", 1],
	["quincenal", "Quincenal", 15],
	["mensual", "Mensual", 30],
]

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lista: VBoxContainer = $MarginContainer/VBoxContainer/ScrollEstante/ListaLibros
@onready var lbl_estante: Label = $MarginContainer/VBoxContainer/LblEstante
@onready var lbl_estado: Label = $MarginContainer/VBoxContainer/LblEstado
@onready var lbl_total: Label = $MarginContainer/VBoxContainer/LblTotal

## Ejemplar abierto. Dato de presentación: quién está en consulta de verdad lo
## sabe el gestor, que lo publica por `consultation_changed`.
var _libro_seleccionado: String = ""

## Estado del ciclo recibido del bus. La sala lo representa, no lo decide.
var _estado_ciclo: String = EventBus.ESTADO_EN_ESTANTE

## Registro de préstamos vigentes, para marcar los ejemplares que ya salieron.
var _prestados: Dictionary = {}

## Mapa id de ejemplar → partes de su tarjeta, para no volver a buscarlas.
## Cada entrada guarda { raiz, detalle, boton, marca, plazos }.
var _tarjetas: Dictionary = {}


func _ready() -> void:
	print("[step_1_base] Sala de lectura montada.")

	EventBus.total_changed.connect(_on_total_changed)
	EventBus.loan_state_changed.connect(_on_loan_state_changed)
	EventBus.loan_result.connect(_on_loan_result)
	EventBus.consultation_changed.connect(_on_consultation_changed)
	EventBus.loans_updated.connect(_on_loans_updated)
	EventBus.category_changed.connect(_on_category_changed)


# --- Construcción dinámica del estante --------------------------------------

## Levanta una tarjeta por cada ejemplar del estante activo.
func _poblar_estante(categoria_id: String) -> void:
	for hijo: Node in lista.get_children():
		hijo.queue_free()
	_tarjetas.clear()

	var catalogo: CatalogoBiblioteca = GlobalManager.CATALOGO
	var categoria: CategoriaData = catalogo.buscar_categoria(categoria_id)

	if categoria == null:
		lbl_estante.text = "Vuelve a los estantes y elige uno para ver sus ejemplares."
		return

	lbl_estante.text = "%s — %s" % [categoria.nombre, categoria.descripcion]

	var indice: int = 0
	for libro: LibroData in catalogo.libros_de(categoria_id):
		var tarjeta: PanelContainer = _crear_tarjeta(libro, categoria)
		lista.add_child(tarjeta)
		_animar_entrada(tarjeta, indice)
		indice += 1

	print("[step_1_base] %d ejemplares construidos para el estante %s." % [indice, categoria_id])
	_actualizar_tarjetas()


## Arma la tarjeta de un ejemplar: cabecera siempre visible y detalle plegado.
func _crear_tarjeta(libro: LibroData, categoria: CategoriaData) -> PanelContainer:
	var raiz: PanelContainer = PanelContainer.new()
	raiz.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margen: MarginContainer = MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_bottom", 12)
	raiz.add_child(margen)

	var columna: VBoxContainer = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)

	# --- Cabecera: lo que se ve con la tarjeta plegada ---
	var cabecera: HBoxContainer = HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 14)
	columna.add_child(cabecera)

	var icono: TextureRect = TextureRect.new()
	icono.texture = ICONO_LIBRO
	icono.modulate = categoria.color
	icono.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.add_child(icono)

	var textos: VBoxContainer = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 2)
	cabecera.add_child(textos)

	var lbl_titulo: Label = Label.new()
	lbl_titulo.text = libro.titulo
	lbl_titulo.theme_type_variation = &"TituloFicha"
	lbl_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(lbl_titulo)

	var lbl_datos: Label = Label.new()
	lbl_datos.text = "%s  ·  %d  ·  %d páginas" % [libro.autor, libro.anio, libro.paginas]
	lbl_datos.theme_type_variation = &"SubtituloPantalla"
	lbl_datos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(lbl_datos)

	# Marca textual de disponibilidad: no basta con apagar el botón, porque
	# apagado no dice por qué.
	var marca: Label = Label.new()
	marca.theme_type_variation = &"EtiquetaSeccion"
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cabecera.add_child(marca)

	var boton: Button = Button.new()
	boton.custom_minimum_size = Vector2(170, 44)
	boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boton.pressed.connect(_on_tarjeta_pressed.bind(libro.id))
	cabecera.add_child(boton)

	# --- Detalle: aparece solo al abrir el ejemplar ---
	var detalle: VBoxContainer = VBoxContainer.new()
	detalle.visible = false
	detalle.add_theme_constant_override("separation", 10)
	columna.add_child(detalle)

	var lbl_sinopsis: Label = Label.new()
	lbl_sinopsis.text = libro.sinopsis
	lbl_sinopsis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.add_child(lbl_sinopsis)

	var lbl_plazos: Label = Label.new()
	lbl_plazos.text = "Plazo de préstamo"
	lbl_plazos.theme_type_variation = &"EtiquetaSeccion"
	detalle.add_child(lbl_plazos)

	var fila_plazos: HBoxContainer = HBoxContainer.new()
	fila_plazos.add_theme_constant_override("separation", 10)
	detalle.add_child(fila_plazos)

	var botones_plazo: Array[Button] = []
	for plazo: Array in PLAZOS:
		var btn: Button = Button.new()
		btn.text = "%s (%d %s)" % [plazo[1], plazo[2], "día" if plazo[2] == 1 else "días"]
		btn.custom_minimum_size = Vector2(0, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_plazo_pressed.bind(str(plazo[0])))
		fila_plazos.add_child(btn)
		botones_plazo.append(btn)

	_tarjetas[libro.id] = {
		"raiz": raiz,
		"detalle": detalle,
		"boton": boton,
		"marca": marca,
		"plazos": botones_plazo
	}
	return raiz


## Pone cada tarjeta en el aspecto que le corresponde: disponible, prestada o
## abierta. Es el único sitio que decide qué se puede pulsar.
func _actualizar_tarjetas() -> void:
	var ocupado: bool = _estado_ciclo == EventBus.ESTADO_REGISTRANDO \
		or _estado_ciclo == EventBus.ESTADO_PRESTADO \
		or _estado_ciclo == EventBus.ESTADO_EN_COMPROBANTE

	for item_id: String in _tarjetas.keys():
		var partes: Dictionary = _tarjetas[item_id]
		var prestado: bool = _prestados.has(item_id)
		var abierta: bool = item_id == _libro_seleccionado

		var boton: Button = partes["boton"]
		var marca: Label = partes["marca"]

		marca.text = "prestado" if prestado else ""
		boton.disabled = ocupado or (prestado and not abierta)
		boton.text = "Cerrar ficha" if abierta else "Ver ficha"
		boton.icon = ICONO_CERRAR if abierta else ICONO_LIBRO
		boton.tooltip_text = "Este ejemplar está fuera de la sala." if prestado else ""

		for btn: Button in partes["plazos"]:
			btn.disabled = ocupado or prestado

		_desplegar(partes, abierta)


## Muestra u oculta el detalle de una tarjeta. El cambio de alto es inmediato
## —los contenedores de Godot no interpolan tamaños— así que lo que se anima es
## la opacidad, suficiente para que el despliegue no aparezca de golpe.
func _desplegar(partes: Dictionary, abierta: bool) -> void:
	var detalle: VBoxContainer = partes["detalle"]
	if detalle.visible == abierta:
		return

	detalle.visible = abierta
	if not abierta:
		return

	detalle.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(detalle, "modulate:a", 1.0, 0.2)


# --- Emisión de intenciones -------------------------------------------------

## Abre o cierra la ficha del ejemplar. Quién está en consulta lo decide el
## gestor: aquí solo se publica la intención.
func _on_tarjeta_pressed(item_id: String) -> void:
	if item_id == _libro_seleccionado:
		print("[step_1_base] Intención item_closed")
		EventBus.item_closed.emit()
		return

	print("[step_1_base] Intención item_opened -> " + item_id)
	EventBus.item_opened.emit(item_id)


## Publica el plazo elegido. El gestor arma el borrador y abre el comprobante.
func _on_plazo_pressed(base_name: String) -> void:
	if _libro_seleccionado.is_empty():
		lbl_estado.text = "Abre un ejemplar antes de elegir el plazo."
		return

	print("[step_1_base] Intención base_selected -> " + base_name)
	EventBus.base_selected.emit(base_name)


# --- Reacción a los eventos del bus -----------------------------------------

## Repuebla el estante cuando cambia la categoría que se está recorriendo.
func _on_category_changed(category_id: String) -> void:
	_poblar_estante(category_id)


## Refresca el total sin conocer cómo ni quién lo calculó.
func _on_total_changed(new_total: int) -> void:
	lbl_total.text = "Días comprometidos en préstamo: %d" % new_total


## Guarda qué ejemplares están prestados para reflejarlo en las tarjetas.
func _on_loans_updated(loans: Dictionary) -> void:
	_prestados = loans
	_actualizar_tarjetas()


## Despliega la tarjeta del ejemplar en consulta y pliega las demás. Esto es lo
## que permite salir de la sala a mitad de una consulta y volver sin perderla.
func _on_consultation_changed(item_id: String) -> void:
	_libro_seleccionado = item_id
	_actualizar_tarjetas()

	if item_id.is_empty():
		lbl_estado.text = "Abre un ejemplar y elige su plazo de préstamo."


## Reacciona al estado del ciclo: habilita lo que ese estado permite y, cuando
## el gestor abre el comprobante, lleva al lector hasta él.
func _on_loan_state_changed(state_name: String) -> void:
	# Un panel que ya está en la cola de borrado no debe reaccionar: sigue
	# suscrito al bus hasta el final del fotograma, y actuar aquí es lo que
	# provocaría una segunda navegación sobre una pantalla que ya no existe.
	if is_queued_for_deletion():
		return

	_estado_ciclo = state_name
	print("[step_1_base] Estado del ciclo recibido: " + state_name)

	_actualizar_tarjetas()

	match state_name:
		EventBus.ESTADO_EN_COMPROBANTE:
			EventBus.navigation_requested.emit(EventBus.RUTA_COMPROBANTE, false)
		EventBus.ESTADO_EN_ESTANTE:
			lbl_estado.remove_theme_color_override("font_color")


## Muestra el veredicto del mostrador: el gestor dice qué pasó, la sala lo pinta.
func _on_loan_result(success: bool, message: String) -> void:
	# El prefijo en texto evita que el veredicto dependa solo del color.
	lbl_estado.text = ("Listo · " if success else "Atención · ") + message
	var color: Color = Color(0.75, 0.9, 0.78) if success else Color(0.95, 0.5, 0.5)
	lbl_estado.add_theme_color_override("font_color", color)


# --- Animación programática (Tween) -----------------------------------------

## Las tarjetas entran escalonadas, de modo que se ve que el estante se
## construye a partir del catálogo en vez de estar dibujado de antemano.
func _animar_entrada(tarjeta: PanelContainer, indice: int) -> void:
	tarjeta.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_interval(indice * 0.05)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(tarjeta, "modulate:a", 1.0, 0.24)
