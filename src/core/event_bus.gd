extends Node


# --- Señales globales con tipado estático estricto --------------------------

## Solicitud de navegación. La emiten las instancias de `ButtonNav`; la escucha
## exclusivamente `main_app.gd`. `discard_previous` indica si la pantalla
## saliente debe retirarse de la pila de historial (caso de los regresos).
signal navigation_requested(target_scene: String, discard_previous: bool)

## Intención de fijar el plazo base del préstamo (diario, quincenal o mensual).
signal base_selected(base_name: String)

## Intención de llevar un ejemplar en préstamo con el plazo vigente.
signal item_added(item_id: String)

## Intención de devolver un ejemplar prestado.
signal item_removed(item_id: String)

## Notificación del nuevo total de días comprometidos, calculado por
## `GlobalManager`. La GUI lo muestra sin saber cómo se obtuvo.
signal total_changed(new_total: int)

## Notificación del registro completo de préstamos vigentes.
signal loans_updated(loans: Dictionary)

# --- Máquina de estados del préstamo (Laboratorio 6) ------------------------

## Intención de sacar un ejemplar del estante para consultarlo.
signal item_opened(item_id: String)

## Intención de devolver el ejemplar al estante sin llevárselo.
signal item_closed()

## Notificación del estado en que se encuentra el ciclo del ejemplar. La emite
## `GlobalManager`, dueño de la máquina de estados; las pantallas la usan para
## habilitar o bloquear sus controles y para disparar animaciones.
signal loan_state_changed(state_name: String)

## Resultado del registro de un préstamo, validado por `GlobalManager`.
signal loan_result(success: bool, message: String)

## Vocabulario compartido de estados. El bus los declara para que ni el gestor
## ni las pantallas dependan del enum interno del otro.
const ESTADO_EN_ESTANTE: String = "en_estante"
const ESTADO_EN_CONSULTA: String = "en_consulta"
const ESTADO_REGISTRANDO: String = "registrando"
const ESTADO_PRESTADO: String = "prestado"

# --- Catálogo único de rutas de escena --------------------------------------
# Las instancias de ButtonNav resuelven su destino desde el Inspector; estas
# constantes las usa `MainApp` para el arranque del sistema.

const RUTA_MENU: String = "res://src/scenes/main/menu_panel.tscn"
const RUTA_SALA_LECTURA: String = "res://src/scenes/simulation/step_1_base.tscn"
const RUTA_PRESTAMOS: String = "res://src/scenes/loans/loans_panel.tscn"
const RUTA_CONFIG: String = "res://src/scenes/config/config_panel.tscn"
const RUTA_CREDITOS: String = "res://src/scenes/credits/credits_panel.tscn"


func _ready() -> void:
	print("[event_bus] Canal global de eventos inicializado (Autoload activo).")
