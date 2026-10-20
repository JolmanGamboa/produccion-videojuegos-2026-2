extends Control

# --- Iconografía de las filas construidas en tiempo de ejecución ------------
# Las filas no existen en la escena, así que sus iconos no se pueden asignar
# desde el Inspector: se cargan una sola vez aquí y se reparten a cada botón.
const ICONO_AMPLIAR: Texture2D = preload("res://src/assets/ui/icons/ic_ampliar.png")
const ICONO_DEVOLVER: Texture2D = preload("res://src/assets/ui/icons/ic_devolver.png")
const ICONO_PASE: Texture2D = preload("res://src/assets/ui/icons/ic_pase.png")

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lista_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ListaContainer
@onready var lbl_resumen: Label = $MarginContainer/VBoxContainer/LblResumen
@onready var lbl_pases: Label = $MarginContainer/VBoxContainer/PanelPases/MarginPases/VBoxPases/EncabezadoPases/LblPases
@onready var lbl_detalle_pases: Label = $MarginContainer/VBoxContainer/PanelPases/MarginPases/VBoxPases/LblDetallePases
@onready var lbl_resultado_pase: Label = $MarginContainer/VBoxContainer/PanelPases/MarginPases/VBoxPases/LblResultadoPase
@onready var btn_vaciar: Button = $MarginContainer/VBoxContainer/BtnVaciar

## Cantidad de pases disponibles, recibida del bus. La vista no la calcula: la
## usa para habilitar o deshabilitar los botones de canje de cada fila.
var _pases_disponibles: int = 0


func _ready() -> void:
	print("[loans_panel] Panel de préstamos montado.")

	# Suscripción reactiva: la vista se redibuja cuando el registro cambia.
	EventBus.loans_updated.connect(_on_loans_updated)
	EventBus.total_changed.connect(_on_total_changed)
	EventBus.loan_state_changed.connect(_on_loan_state_changed)
	EventBus.passes_updated.connect(_on_passes_updated)
	EventBus.pass_result.connect(_on_pass_result)

	btn_vaciar.pressed.connect(_on_vaciar_pressed)


# --- Reacción a los eventos del bus -----------------------------------------

## Redibuja la lista completa con el registro recibido.
func _on_loans_updated(loans: Dictionary) -> void:
	_limpiar_lista()

	if loans.is_empty():
		_agregar_mensaje_vacio()
		return

	for item_id: String in loans.keys():
		_agregar_fila(item_id, loans[item_id])


## Refresca el resumen de días sin calcular nada por su cuenta.
func _on_total_changed(new_total: int) -> void:
	lbl_resumen.text = "Días comprometidos en total: %d" % new_total


## Redibuja el tablero de pases con la colección recibida.
func _on_passes_updated(passes: Array) -> void:
	_pases_disponibles = passes.size()
	lbl_pases.text = "Pases de lectura disponibles: %d" % _pases_disponibles

	if passes.is_empty():
		lbl_detalle_pases.text = "Devuelve un ejemplar para ganar tu primer pase."
	else:
		var origenes: Array[String] = []
		for pase: Dictionary in passes:
			origenes.append("%s (+%d días)" % [str(pase["origen"]), int(pase["dias"])])
		lbl_detalle_pases.text = "Ganados por devolver: " + ", ".join(origenes)

	# Los botones de canje dependen de que haya pases: se refresca la lista.
	_actualizar_botones_canje()


## Muestra el veredicto del canje. El gestor dice qué pasó, la vista lo pinta.
func _on_pass_result(success: bool, message: String) -> void:
	lbl_resultado_pase.text = message
	var color: Color = Color(0.62, 0.84, 0.66) if success else Color(0.91, 0.55, 0.55)
	lbl_resultado_pase.add_theme_color_override("font_color", color)


## Reacciona al estado del ciclo: mientras un préstamo se está registrando,
## las devoluciones quedan bloqueadas para no descuadrar el registro.
func _on_loan_state_changed(state_name: String) -> void:
	_bloquear_filas(state_name == EventBus.ESTADO_REGISTRANDO)


## Desactiva los botones de todas las filas mientras el registro está ocupado.
func _bloquear_filas(bloquear: bool) -> void:
	for fila: Node in lista_container.get_children():
		for control: Node in fila.get_children():
			if control is Button:
				(control as Button).disabled = bloquear

	if not bloquear:
		_actualizar_botones_canje()


## Habilita el canje solo en las filas que puedan aprovecharlo. Las filas se
## marcan con un grupo para no depender de su posición dentro del contenedor.
func _actualizar_botones_canje() -> void:
	for boton: Node in get_tree().get_nodes_in_group("btn_canje"):
		(boton as Button).disabled = _pases_disponibles == 0


# --- Construcción dinámica de la lista --------------------------------------

## Destruye las filas previas liberando su memoria.
func _limpiar_lista() -> void:
	for fila: Node in lista_container.get_children():
		fila.queue_free()


## Crea una fila con los datos del préstamo y su botón de devolución.
func _agregar_fila(item_id: String, datos: Dictionary) -> void:
	var fila: HBoxContainer = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)

	var etiqueta: Label = Label.new()
	var extra: int = int(datos["extra_dias"])
	var detalle_extra: String = (" · ampliado +%d" % extra) if extra > 0 else ""
	etiqueta.text = "%s — %s · plazo %s%s · %d días" % [
		str(datos["titulo"]),
		str(datos["autor"]),
		str(datos["plan"]),
		detalle_extra,
		int(datos["dias"])
	]
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(etiqueta)

	# Canje: el "gasto" de un pase sobre este préstamo concreto.
	var btn_canjear: Button = Button.new()
	btn_canjear.text = "Ampliar (1 pase)"
	btn_canjear.custom_minimum_size = Vector2(170, 40)
	btn_canjear.icon = ICONO_AMPLIAR
	btn_canjear.disabled = _pases_disponibles == 0
	btn_canjear.add_to_group("btn_canje")
	btn_canjear.pressed.connect(_on_canjear_pressed.bind(item_id))
	fila.add_child(btn_canjear)

	var btn_devolver: Button = Button.new()
	btn_devolver.text = "Devolver"
	btn_devolver.icon = ICONO_DEVOLVER
	btn_devolver.custom_minimum_size = Vector2(150, 40)
	# Reactividad parametrizada: el mismo callback sirve a todas las filas.
	btn_devolver.pressed.connect(_on_devolver_pressed.bind(item_id))
	fila.add_child(btn_devolver)

	lista_container.add_child(fila)


## Estado vacío: la biblioteca no tiene ejemplares fuera de sus estantes.
func _agregar_mensaje_vacio() -> void:
	var etiqueta: Label = Label.new()
	etiqueta.text = "No hay ejemplares prestados. Todos los libros están en sus estantes."
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista_container.add_child(etiqueta)


# --- Emisión de intenciones -------------------------------------------------

## Publica la devolución del ejemplar. El registro lo actualiza GlobalManager.
func _on_devolver_pressed(item_id: String) -> void:
	print("[loans_panel] Intención item_removed -> " + item_id)
	EventBus.item_removed.emit(item_id)


## Publica el canje de un pase sobre este préstamo. Quién valida y descuenta es
## el gestor; la vista solo pide.
func _on_canjear_pressed(item_id: String) -> void:
	print("[loans_panel] Intención pass_redeemed -> " + item_id)
	EventBus.pass_redeemed.emit(item_id)


## Publica el vaciado del registro guardado.
func _on_vaciar_pressed() -> void:
	print("[loans_panel] Intención save_reset_requested")
	EventBus.save_reset_requested.emit()
