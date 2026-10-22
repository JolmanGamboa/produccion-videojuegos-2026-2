extends Control

## ============================================================================
## categories_panel.gd — Estantes de la biblioteca (interfaz auto-poblada)
## ============================================================================
## Ninguna de las tarjetas de esta pantalla existe en la escena: se construyen
## en tiempo de ejecución recorriendo el catálogo de `GlobalManager`. Añadir un
## estante nuevo es crear un recurso y soltarlo en la colección; esta pantalla
## lo muestra sin que haya que tocar una sola línea de aquí.
##
## La vista no decide nada: publica `category_selected` y es el gestor quien
## valida el estante y lo fija como activo.
## ----------------------------------------------------------------------------

const ICONO_ENTRAR: Texture2D = preload("res://src/assets/ui/icons/ic_libro.png")

## Cuánto tarda cada tarjeta en aparecer después de la anterior. Escalonar la
## entrada deja ver que la lista se construye, en vez de aparecer de golpe.
const RETARDO_ENTRE_TARJETAS: float = 0.06

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lista: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ListaCategorias

## Préstamos vigentes, para poder decir cuántos ejemplares quedan en cada
## estante. Llega del bus; esta pantalla no lo calcula.
var _prestados: Dictionary = {}

## Tarjetas ya construidas, indexadas por el identificador de su estante.
var _tarjetas: Dictionary = {}

## Verdadero mientras corre la animación de salida hacia la sala, para que un
## segundo clic no dispare dos navegaciones.
var _navegando: bool = false


func _ready() -> void:
	print("[categories_panel] Estantes montados.")

	EventBus.loans_updated.connect(_on_loans_updated)

	_poblar_estantes()


# --- Construcción dinámica de la interfaz -----------------------------------

## Recorre el catálogo y levanta una tarjeta por estante.
func _poblar_estantes() -> void:
	for hijo: Node in lista.get_children():
		hijo.queue_free()
	_tarjetas.clear()

	var catalogo: CatalogoBiblioteca = GlobalManager.CATALOGO
	var indice: int = 0

	for categoria: CategoriaData in catalogo.categorias:
		var tarjeta: PanelContainer = _crear_tarjeta(categoria)
		lista.add_child(tarjeta)
		_tarjetas[categoria.id] = tarjeta
		_animar_entrada(tarjeta, indice)
		indice += 1

	print("[categories_panel] %d estantes construidos desde el catálogo." % indice)


## Arma la tarjeta de un estante: icono, nombre, descripción, cuántos
## ejemplares guarda y el botón para entrar.
func _crear_tarjeta(categoria: CategoriaData) -> PanelContainer:
	var tarjeta: PanelContainer = PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margen: MarginContainer = MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_bottom", 16)
	tarjeta.add_child(margen)

	var fila: HBoxContainer = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	margen.add_child(fila)

	# El icono se tiñe con el color del estante. El color refuerza, no informa:
	# el nombre y el icono ya dicen de qué estante se trata.
	var icono: TextureRect = TextureRect.new()
	icono.texture = categoria.icono
	icono.modulate = categoria.color
	icono.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(icono)

	var textos: VBoxContainer = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 4)
	fila.add_child(textos)

	var lbl_nombre: Label = Label.new()
	lbl_nombre.text = categoria.nombre
	lbl_nombre.theme_type_variation = &"TituloFicha"
	textos.add_child(lbl_nombre)

	var lbl_desc: Label = Label.new()
	lbl_desc.text = categoria.descripcion
	lbl_desc.theme_type_variation = &"SubtituloPantalla"
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(lbl_desc)

	var lbl_conteo: Label = Label.new()
	lbl_conteo.theme_type_variation = &"EtiquetaSeccion"
	lbl_conteo.name = "LblConteo"
	textos.add_child(lbl_conteo)

	var btn_entrar: Button = Button.new()
	btn_entrar.text = "Ver estante"
	btn_entrar.icon = ICONO_ENTRAR
	btn_entrar.custom_minimum_size = Vector2(190, 46)
	btn_entrar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_entrar.pressed.connect(_on_estante_pressed.bind(categoria.id))
	fila.add_child(btn_entrar)

	_refrescar_conteo(categoria.id, lbl_conteo)
	return tarjeta


## Escribe cuántos ejemplares guarda el estante y cuántos siguen disponibles.
func _refrescar_conteo(categoria_id: String, etiqueta: Label) -> void:
	var catalogo: CatalogoBiblioteca = GlobalManager.CATALOGO
	var total: int = catalogo.contar_libros(categoria_id)

	var disponibles: int = 0
	for libro: LibroData in catalogo.libros_de(categoria_id):
		if not _prestados.has(libro.id):
			disponibles += 1

	if disponibles == total:
		etiqueta.text = "%d ejemplares · todos disponibles" % total
	else:
		etiqueta.text = "%d ejemplares · %d disponibles" % [total, disponibles]


# --- Reacción a los eventos del bus -----------------------------------------

## Los préstamos cambian cuántos ejemplares quedan en cada estante.
func _on_loans_updated(loans: Dictionary) -> void:
	_prestados = loans

	for categoria_id: String in _tarjetas.keys():
		var etiqueta: Label = (_tarjetas[categoria_id] as Node).find_child("LblConteo", true, false)
		if etiqueta != null:
			_refrescar_conteo(categoria_id, etiqueta)


# --- Emisión de intenciones -------------------------------------------------

## Entra al estante elegido. Se anima primero y se navega después, para que el
## lector vea cuál seleccionó antes de que la pantalla cambie.
func _on_estante_pressed(categoria_id: String) -> void:
	if _navegando:
		return

	_navegando = true
	print("[categories_panel] Intención category_selected -> " + categoria_id)
	EventBus.category_selected.emit(categoria_id)

	_animar_seleccion(_tarjetas[categoria_id])


# --- Animaciones programáticas (Tween) --------------------------------------

## Entrada escalonada: cada tarjeta aparece un poco después de la anterior,
## de modo que se ve que la lista se está construyendo.
func _animar_entrada(tarjeta: PanelContainer, indice: int) -> void:
	tarjeta.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_interval(indice * RETARDO_ENTRE_TARJETAS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(tarjeta, "modulate:a", 1.0, 0.28)


## La tarjeta elegida crece un instante y luego se navega al estante.
func _animar_seleccion(tarjeta: PanelContainer) -> void:
	tarjeta.pivot_offset = tarjeta.size / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tarjeta, "scale", Vector2(1.03, 1.03), 0.16)
	tween.tween_property(tarjeta, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(_entrar_a_la_sala)


## Publica la navegación una vez terminada la animación.
func _entrar_a_la_sala() -> void:
	EventBus.navigation_requested.emit(EventBus.RUTA_SALA_LECTURA, false)
