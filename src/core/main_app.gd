extends Control

## ============================================================================
## MainApp — Orquestador central de la Biblioteca Interactiva
## ============================================================================
## Escena principal del proyecto (`res://src/core/main_app.tscn`). Es el único
## nodo del sistema con autoridad para instanciar paneles, inyectarlos en el
## árbol visual y liberarlos de la memoria RAM.
##
## Responsabilidades:
##   1. Suscribirse de forma diferida (asíncrona) a `EventBus.navigation_requested`.
##   2. Liberar la escena activa previa con `queue_free()` y limpiar su
##      referencia lógica para prevenir fugas de memoria (memory leaks).
##   3. Persistir los parámetros globales publicados en el bus y replicarlos
##      sobre cada panel recién instanciado.
## ----------------------------------------------------------------------------

# --- Captura de nodos en caché (operador $ solo en la cabecera) -------------
@onready var view_container: Control = $ViewContainer

## Referencia a la escena actualmente montada en el árbol visual.
var current_scene: Node = null

## Estado global de la biblioteca. Sobrevive a la destrucción de los paneles.
var _parametros: Dictionary = {}


func _ready() -> void:
	# CONNECT_DEFERRED: el callback se ejecuta al final del frame, nunca dentro
	# de la propia emisión de la señal. Así el panel que solicita la navegación
	# termina de procesar su evento antes de que su nodo sea liberado.
	EventBus.navigation_requested.connect(_on_navigation_requested, CONNECT_DEFERRED)
	EventBus.parameter_changed.connect(_on_parameter_changed)

	print("[main_app] Orquestador suscrito al bus global. Cargando menú...")
	_cargar_panel(EventBus.RUTA_MENU)


# --- Suscriptores del bus global --------------------------------------------

## Callback de navegación: único punto del sistema que conmuta paneles.
func _on_navigation_requested(target_scene_path: String) -> void:
	print("[main_app] Evento de navegación recibido -> " + target_scene_path)
	_cargar_panel(target_scene_path)


## Callback de configuración: persiste el parámetro para los paneles futuros.
func _on_parameter_changed(param_name: String, value: Variant) -> void:
	_parametros[param_name] = value
	print("[main_app] Parámetro global actualizado: %s = %s" % [param_name, str(value)])


# --- Gestión del ciclo de vida de las escenas -------------------------------

## Libera el panel activo y monta el solicitado dentro de `ViewContainer`.
func _cargar_panel(target_scene_path: String) -> void:
	# 1. Liberación explícita de la memoria RAM del panel anterior.
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# 2. Carga y validación del recurso empaquetado.
	var escena_empaquetada: PackedScene = load(target_scene_path) as PackedScene
	if escena_empaquetada == null:
		push_error("[main_app] Ruta de escena inválida: " + target_scene_path)
		return

	# 3. Instanciación e inyección en el árbol visual.
	current_scene = escena_empaquetada.instantiate()
	view_container.add_child(current_scene)

	# 4. Replicación del estado global sobre el panel recién creado.
	_replicar_parametros(current_scene)


## Reenvía los parámetros ya conocidos al panel entrante, si sabe recibirlos.
func _replicar_parametros(panel: Node) -> void:
	if not panel.has_method("aplicar_parametro"):
		return
	for nombre: String in _parametros.keys():
		panel.call("aplicar_parametro", nombre, _parametros[nombre])
