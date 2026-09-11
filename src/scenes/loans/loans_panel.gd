extends Control

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lista_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ListaContainer
@onready var lbl_resumen: Label = $MarginContainer/VBoxContainer/LblResumen


func _ready() -> void:
	print("[loans_panel] Panel de préstamos montado.")

	# Suscripción reactiva: la vista se redibuja cuando el registro cambia.
	EventBus.loans_updated.connect(_on_loans_updated)
	EventBus.total_changed.connect(_on_total_changed)


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
	etiqueta.text = "%s — %s · plazo %s (%d días)" % [
		str(datos["titulo"]),
		str(datos["autor"]),
		str(datos["plan"]),
		int(datos["dias"])
	]
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(etiqueta)

	var btn_devolver: Button = Button.new()
	btn_devolver.text = "Devolver"
	btn_devolver.custom_minimum_size = Vector2(120, 40)
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
