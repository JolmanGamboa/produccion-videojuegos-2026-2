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

@onready var sprite: AnimatedSprite2D = $Sprite

var _pendiente: String = EventBus.PLAZO_AL_DIA


func _ready() -> void:
	sprite.sprite_frames = MARCOS
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
