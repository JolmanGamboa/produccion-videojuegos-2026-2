extends Button

## ============================================================================
## button_nav.gd — Botón de navegación reutilizable
## ============================================================================
## Componente de interfaz parametrizable desde el Inspector de Godot. Encapsula
## la intención de navegación común a todo el sistema, de modo que los paneles
## de Configuración y Créditos resuelven su regreso de forma declarativa, sin
## script controlador propio.
##
## Uso: instanciar `button_nav.tscn` dentro de cualquier panel y configurar
## `target_scene` y `discard_previous` desde el Inspector.
## ----------------------------------------------------------------------------

## Escena de destino. El filtro del Inspector solo admite archivos `.tscn`.
@export_file("*.tscn") var target_scene: String = ""

## Cuando es `true`, `MainApp` retira la pantalla saliente de la pila de
## historial en vez de apilar la entrante. Es el caso de los botones de regreso.
@export var discard_previous: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)


## Publica la intención de navegación en el canal global.
func _on_pressed() -> void:
	if target_scene.is_empty():
		push_error("[button_nav] '" + name + "' no tiene target_scene configurado en el Inspector.")
		return

	print("[button_nav] Intención publicada -> %s (descartar previa: %s)" % [target_scene, str(discard_previous)])
	EventBus.navigation_requested.emit(target_scene, discard_previous)
