extends Node

## ============================================================================
## EventBus — Canal único de señales globales (Singleton + Observer)
## ============================================================================
## Registrado como Autoload bajo el identificador exacto `EventBus`.
##
## Regla arquitectónica del Sprint 1: ningún panel conoce a otro panel, ni al
## `GlobalManager`, ni toca el árbol de escenas. Cada actor publica intenciones
## en este canal y los responsables reaccionan:
##
##   GUI ──intención──▶ EventBus ──▶ GlobalManager (único registro de préstamos)
##                          │                 │
##                          │                 └──▶ total_changed / loans_updated ──▶ GUI
##                          └──▶ MainApp (única autoridad sobre el árbol)
## ----------------------------------------------------------------------------

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
