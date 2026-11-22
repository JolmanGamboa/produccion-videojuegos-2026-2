class_name RelojPlazo
extends Control

## ============================================================================
## reloj_plazo.gd — El plazo como sprite dirigido por los días que quedan
## ============================================================================
## El segundo objeto del proyecto cuyo sprite depende de su estado, y el que
## demuestra que el patrón no estaba atado al ciclo del ejemplar: aquí el estado
## no viene de una máquina de estados sino de una cuenta —cuántos días quedan
## sobre cuántos se pidieron— y el componente no necesita saberlo.
##
##     al_dia     → aro verde,   aguja lenta,  arco casi completo
##     por_vencer → aro dorado,  algo más viva, arco a la mitad
##     urgente    → aro naranja, aguja rápida, apenas queda arco
##     vencido    → aro rojo,    aguja a tope, sin arco
##
## El color no es lo único que distingue un estado de otro: cambian también la
## velocidad de la aguja y cuánto arco queda dibujado. Es la misma regla de
## accesibilidad que el proyecto adoptó en el Laboratorio 8 al dejar de
## comunicar el resultado de un préstamo solo con el color del texto.
## ----------------------------------------------------------------------------

const MARCOS: SpriteFrames = preload("res://src/assets/sprites/reloj_plazo.tres")

## Los nombres de las animaciones coinciden con el vocabulario que publica el
## bus, así que el estado del plazo se usa tal cual: no hay tabla que mantener.
const ESTADOS: Array[String] = [
	EventBus.PLAZO_AL_DIA,
	EventBus.PLAZO_POR_VENCER,
	EventBus.PLAZO_URGENTE,
	EventBus.PLAZO_VENCIDO,
]

## Cuánto late el reloj en cada tramo, y de qué color. Es el único dato que el
## juego le pasa al shader, y se escribe una vez por cambio de estado.
const PULSO_DE_ESTADO: Dictionary = {
	EventBus.PLAZO_AL_DIA: [0.0, Color(0.498, 0.659, 0.420)],
	EventBus.PLAZO_POR_VENCER: [0.3, Color(0.851, 0.627, 0.329)],
	EventBus.PLAZO_URGENTE: [0.65, Color(0.788, 0.416, 0.204)],
	EventBus.PLAZO_VENCIDO: [1.0, Color(0.737, 0.267, 0.227)],
}

@onready var sprite: AnimatedSprite2D = $Sprite

var _pendiente: String = EventBus.PLAZO_AL_DIA


func _ready() -> void:
	sprite.sprite_frames = MARCOS

	# Cada reloj necesita su propio material: los parámetros de un ShaderMaterial
	# compartido valdrían lo mismo para todas las filas, y entonces el préstamo
	# vencido haría latir también a los que van al día.
	sprite.material = sprite.material.duplicate()

	sprite.position = size / 2.0
	resized.connect(func() -> void: sprite.position = size / 2.0)
	aplicar_estado(_pendiente)


## Pone el reloj en el estado del plazo que se le indique.
func aplicar_estado(estado: String) -> void:
	if not ESTADOS.has(estado):
		return

	if sprite == null:
		_pendiente = estado
		return

	if sprite.animation == estado:
		return

	sprite.play(estado)
	tooltip_text = _descripcion(estado)
	_aplicar_pulso(estado)


## Escribe en el shader cuánto debe latir el reloj y de qué color. Una sola
## llamada por cambio de estado: el resto lo hace la GPU con TIME.
func _aplicar_pulso(estado: String) -> void:
	if not PULSO_DE_ESTADO.has(estado):
		return

	var ajuste: Array = PULSO_DE_ESTADO[estado]
	var material: ShaderMaterial = sprite.material as ShaderMaterial
	if material == null:
		return

	material.set_shader_parameter("urgencia", float(ajuste[0]))
	material.set_shader_parameter("color_pulso", ajuste[1] as Color)


## Texto equivalente al estado, para quien navegue con lector de pantalla o no
## distinga los colores del aro.
func _descripcion(estado: String) -> String:
	match estado:
		EventBus.PLAZO_AL_DIA:
			return "El plazo va holgado."
		EventBus.PLAZO_POR_VENCER:
			return "Va por la mitad del plazo."
		EventBus.PLAZO_URGENTE:
			return "Quedan pocos días."
		EventBus.PLAZO_VENCIDO:
			return "El plazo venció."
	return ""
