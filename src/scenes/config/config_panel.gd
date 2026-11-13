extends Control

## ============================================================================
## config_panel.gd — Configuración de sala
## ============================================================================
## La pantalla era puramente informativa hasta que el plazo pasó a ser tiempo
## que corre. Ahora alberga el calendario de la sala: un control que adelanta
## los días para poder ver vencer un préstamo sin esperar un mes real.
##
## Es una herramienta de observación, no una trampa. Nada dentro del dominio
## distingue un día adelantado de un día transcurrido —`GlobalManager.ahora()`
## suma el desfase y todas las cuentas pasan por ahí—, de modo que lo que se ve
## al adelantar es exactamente lo que se vería esperando.
## ----------------------------------------------------------------------------

@onready var lbl_calendario: Label = $MarginContainer/VBoxContainer/PanelCalendario/MargenCalendario/VBoxCalendario/LblCalendario
@onready var lbl_desfase: Label = $MarginContainer/VBoxContainer/PanelCalendario/MargenCalendario/VBoxCalendario/LblDesfase
@onready var btn_un_dia: Button = $MarginContainer/VBoxContainer/PanelCalendario/MargenCalendario/VBoxCalendario/BotonesCalendario/BtnUnDia
@onready var btn_una_semana: Button = $MarginContainer/VBoxContainer/PanelCalendario/MargenCalendario/VBoxCalendario/BotonesCalendario/BtnUnaSemana
@onready var btn_un_mes: Button = $MarginContainer/VBoxContainer/PanelCalendario/MargenCalendario/VBoxCalendario/BotonesCalendario/BtnUnMes


func _ready() -> void:
	print("[config_panel] Configuración de sala montada.")

	btn_un_dia.pressed.connect(_on_adelantar_pressed.bind(1))
	btn_una_semana.pressed.connect(_on_adelantar_pressed.bind(7))
	btn_un_mes.pressed.connect(_on_adelantar_pressed.bind(30))

	EventBus.calendar_changed.connect(_on_calendar_changed)


# --- Emisión de intenciones -------------------------------------------------

## Publica la intención de adelantar el calendario. Quién lleva la cuenta de los
## días es el gestor, igual que con todo lo demás.
func _on_adelantar_pressed(dias: int) -> void:
	print("[config_panel] Intención time_advanced -> %d" % dias)
	EventBus.time_advanced.emit(dias)


# --- Reacción a los eventos del bus -----------------------------------------

## Refleja el desfase vigente entre el calendario de la sala y el reloj real.
func _on_calendar_changed(desfase_dias: int) -> void:
	if desfase_dias == 0:
		lbl_desfase.text = "La sala va a la par del calendario real."
		return

	lbl_desfase.text = "La sala va %d %s por delante del calendario real." % [
		desfase_dias,
		"día" if desfase_dias == 1 else "días"
	]
