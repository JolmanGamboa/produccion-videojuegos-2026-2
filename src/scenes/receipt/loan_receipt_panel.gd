extends Control

## ============================================================================
## loan_receipt_panel.gd — Comprobante del préstamo
## ============================================================================
## Es la pantalla de confirmación que pide el laboratorio: muestra el detalle
## del ejemplar tomándolo del catálogo, deja aplicar los pases de lectura
## guardados en disco y solo entonces permite confirmar.
##
## Hasta que el lector confirma, el registro no se ha tocado: cancelar no deja
## rastro. Todo lo que se ve aquí llega por `receipt_changed`; esta pantalla no
## calcula días ni consulta al gestor.
## ----------------------------------------------------------------------------

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var lbl_libro: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/LblLibro
@onready var lbl_datos: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/LblDatos
@onready var lbl_sinopsis: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/LblSinopsis
@onready var lbl_plazo: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/GridDetalle/LblPlazoValor
@onready var lbl_pases_aplicados: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/GridDetalle/LblPasesValor
@onready var lbl_total: Label = $MarginContainer/VBoxContainer/PanelDetalle/MargenDetalle/VBoxDetalle/GridDetalle/LblTotalValor
@onready var panel_detalle: PanelContainer = $MarginContainer/VBoxContainer/PanelDetalle
@onready var lbl_pases_disponibles: Label = $MarginContainer/VBoxContainer/PanelPases/MargenPases/VBoxPases/LblPasesDisponibles
@onready var lbl_resultado_pase: Label = $MarginContainer/VBoxContainer/PanelPases/MargenPases/VBoxPases/LblResultadoPase
@onready var btn_aplicar_pase: Button = $MarginContainer/VBoxContainer/PanelPases/MargenPases/VBoxPases/BtnAplicarPase
@onready var btn_cancelar: Button = $MarginContainer/VBoxContainer/BotonesContainer/BtnCancelar
@onready var btn_confirmar: Button = $MarginContainer/VBoxContainer/BotonesContainer/BtnConfirmar
@onready var popup_exito: Control = $LoanSuccessPopup
@onready var lbl_mensaje_popup: Label = $LoanSuccessPopup/CentroPopup/PanelPopup/MargenPopup/VBoxPopup/LblMensajePopup
@onready var btn_seguir: Button = $LoanSuccessPopup/CentroPopup/PanelPopup/MargenPopup/VBoxPopup/BotonesPopup/BtnSeguir

## Identificador del ejemplar del comprobante vigente. Llega del bus.
var _libro_id: String = ""

## Verdadero una vez confirmado, para que el regreso automático a la sala no
## se dispare mientras el popup de confirmación está en pantalla.
var _confirmado: bool = false


func _ready() -> void:
	print("[loan_receipt_panel] Comprobante montado.")

	btn_aplicar_pase.pressed.connect(_on_aplicar_pase_pressed)
	btn_cancelar.pressed.connect(_on_cancelar_pressed)
	btn_confirmar.pressed.connect(_on_confirmar_pressed)

	EventBus.receipt_changed.connect(_on_receipt_changed)
	EventBus.passes_updated.connect(_on_passes_updated)
	EventBus.pass_result.connect(_on_pass_result)
	EventBus.loan_result.connect(_on_loan_result)
	EventBus.loan_state_changed.connect(_on_loan_state_changed)

	btn_confirmar.grab_focus()


# --- Reacción a los eventos del bus -----------------------------------------

## Pinta el comprobante. Un diccionario vacío significa que no hay préstamo en
## curso: puede ocurrir si se llega aquí sin pasar por la sala.
func _on_receipt_changed(receipt: Dictionary) -> void:
	if receipt.is_empty():
		_libro_id = ""
		lbl_libro.text = "Sin ejemplar seleccionado"
		lbl_datos.text = ""
		lbl_sinopsis.text = "Vuelve a la sala y elige un ejemplar con su plazo."
		lbl_plazo.text = "—"
		lbl_pases_aplicados.text = "—"
		lbl_total.text = "—"
		btn_confirmar.disabled = true
		return

	_libro_id = str(receipt["id"])
	btn_confirmar.disabled = false

	lbl_libro.text = "%s — %s" % [str(receipt["titulo"]), str(receipt["autor"])]
	lbl_datos.text = "%s  ·  %d  ·  %d páginas" % [
		str(receipt["categoria"]),
		int(receipt["anio"]),
		int(receipt["paginas"])
	]
	lbl_sinopsis.text = str(receipt["sinopsis"])

	lbl_plazo.text = "%s · %d días" % [str(receipt["plan"]), int(receipt["dias_base"])]

	var aplicados: int = int(receipt["pases_aplicados"])
	if aplicados == 0:
		lbl_pases_aplicados.text = "ninguno"
	else:
		lbl_pases_aplicados.text = "%d · +%d días" % [aplicados, int(receipt["dias_extra"])]

	lbl_total.text = "%d días" % int(receipt["dias_total"])
	_animar_actualizacion()


## Habilita el canje solo si quedan pases guardados.
func _on_passes_updated(passes: Array) -> void:
	lbl_pases_disponibles.text = "Pases de lectura disponibles: %d" % passes.size()
	btn_aplicar_pase.disabled = passes.is_empty() or _confirmado


## Veredicto del canje. El prefijo en texto evita depender solo del color.
func _on_pass_result(success: bool, message: String) -> void:
	lbl_resultado_pase.text = ("Listo · " if success else "Atención · ") + message
	var color: Color = Color(0.62, 0.84, 0.66) if success else Color(0.91, 0.55, 0.55)
	lbl_resultado_pase.add_theme_color_override("font_color", color)


## Veredicto del registro. Alimenta el mensaje del popup de confirmación.
func _on_loan_result(success: bool, message: String) -> void:
	if success and _confirmado:
		lbl_mensaje_popup.text = message
	elif not success:
		lbl_resultado_pase.text = "Atención · " + message
		lbl_resultado_pase.add_theme_color_override("font_color", Color(0.91, 0.55, 0.55))


## Reacciona al ciclo: bloquea durante el registro, levanta el popup al quedar
## prestado y regresa a la sala si el préstamo se canceló.
func _on_loan_state_changed(state_name: String) -> void:
	match state_name:
		EventBus.ESTADO_REGISTRANDO:
			btn_confirmar.disabled = true
			btn_cancelar.disabled = true
			btn_aplicar_pase.disabled = true
		EventBus.ESTADO_PRESTADO:
			popup_exito.show()
			btn_seguir.grab_focus()
		EventBus.ESTADO_EN_CONSULTA:
			# El gestor descartó el borrador: el lector vuelve al estante.
			if not _confirmado:
				EventBus.navigation_requested.emit(EventBus.RUTA_SALA_LECTURA, true)


# --- Emisión de intenciones -------------------------------------------------

## Aplica un pase al borrador. El gestor lo descuenta y reescribe el guardado.
func _on_aplicar_pase_pressed() -> void:
	print("[loan_receipt_panel] Intención draft_pass_applied")
	EventBus.draft_pass_applied.emit()


## Descarta el borrador y vuelve a la consulta.
func _on_cancelar_pressed() -> void:
	print("[loan_receipt_panel] Intención item_closed (cancelar)")
	EventBus.item_closed.emit()


## Confirma el préstamo. Es el único punto del flujo que escribe en el registro.
func _on_confirmar_pressed() -> void:
	if _libro_id.is_empty():
		return

	_confirmado = true
	print("[loan_receipt_panel] Intención item_added -> " + _libro_id)
	EventBus.item_added.emit(_libro_id)


# --- Animación programática (Tween) -----------------------------------------

## El detalle parpadea al recalcularse, para que se note que aplicar un pase
## cambió los días aunque el número quede lejos del botón que se pulsó.
func _animar_actualizacion() -> void:
	panel_detalle.modulate = Color(1.18, 1.12, 0.95)

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_detalle, "modulate", Color.WHITE, 0.32)
