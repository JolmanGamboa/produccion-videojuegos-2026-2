extends Node

## ============================================================================
## EventBus — Canal global de eventos (patrones Singleton + Observer)
## ============================================================================
## Registrado como Autoload en el editor bajo el identificador exacto
## `EventBus`, por lo que existe una única instancia viva durante todo el
## ciclo de vida de la aplicación.
##
## Regla arquitectónica: ningún panel de interfaz conoce a otro panel ni toca
## el árbol de escenas. Los paneles solo PUBLICAN eventos en este canal, y
## `main_app.gd` es el único SUSCRIPTOR autorizado a instanciar o liberar
## escenas. Esto elimina el acoplamiento por rutas absolutas que tenía el
## Laboratorio 1.
## ----------------------------------------------------------------------------

# --- Señales globales con tipado estático estricto --------------------------

## Solicitud de navegación hacia otro panel de la biblioteca.
## La emiten los paneles; la escucha exclusivamente `main_app.gd`.
signal navigation_requested(target_scene_path: String)

## Cambio de un parámetro global de la biblioteca (estante activo, tamaño de
## letra, etc.). La emite `config_panel.gd`; la escuchan `MainApp` (que lo
## persiste) y cualquier panel interesado en reaccionar en caliente.
signal parameter_changed(param_name: String, value: Variant)

# --- Catálogo único de rutas de escena --------------------------------------
# Centralizar las rutas aquí evita literales de texto dispersos: si una carpeta
# cambia de nombre, solo se edita este bloque.

const RUTA_MENU: String = "res://src/scenes/menu/menu_panel.tscn"
const RUTA_SALA_LECTURA: String = "res://src/scenes/step_1/step_1_base.tscn"
const RUTA_CONFIG: String = "res://src/scenes/config/config_panel.tscn"
const RUTA_CREDITOS: String = "res://src/scenes/credits/credits_panel.tscn"

# --- Nombres canónicos de los parámetros configurables ----------------------

const PARAM_ESTANTE: String = "estante_activo"
const PARAM_TAMANO_TEXTO: String = "tamano_texto"


func _ready() -> void:
	print("[event_bus] Canal global de eventos inicializado (Autoload activo).")
