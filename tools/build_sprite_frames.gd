extends SceneTree

## ============================================================================
## build_sprite_frames.gd — Herramienta de autor de las animaciones
## ============================================================================
## Genera los dos recursos `SpriteFrames` del proyecto a partir de sus hojas de
## sprites, recortando cada fotograma con un `AtlasTexture`.
##
## Existe por la misma razón que `build_catalogo.gd`: un `SpriteFrames` con
## setenta y cuatro sub-recursos no se escribe a mano sin equivocarse, y el
## formato de serialización de Godot no es algo que convenga adivinar. Aquí se
## declara qué tramo de la hoja es cada animación y el motor escribe el archivo.
##
## Uso, desde la raíz del proyecto:
##
##     godot --headless --script tools/build_sprite_frames.gd
##
## Reescribe los dos `.tres` por completo, así que no conviene ejecutarla si ya
## se tocaron en el editor.
## ----------------------------------------------------------------------------

## Hoja del libro: 6 columnas × 7 filas de 28 × 35 px, 42 fotogramas que van de
## cerrado a abierto, pasan hojas tres veces y vuelven a cerrarse.
const LIBRO_HOJA: String = "res://src/assets/sprites/libro_biblioteca.png"
const LIBRO_DESTINO: String = "res://src/assets/sprites/libro_biblioteca.tres"
const LIBRO_ANCHO: int = 28
const LIBRO_ALTO: int = 35
const LIBRO_COLUMNAS: int = 6

## Cada animación es un tramo de esa secuencia continua.
## [nombre, primer fotograma, último fotograma, velocidad, en bucle]
const LIBRO_ANIMACIONES: Array = [
	["cerrado", 0, 0, 1.0, false],
	["abriendo", 1, 11, 14.0, false],
	["pasando_hojas", 12, 23, 9.0, true],
	["cerrando", 24, 34, 14.0, false],
	["de_canto", 37, 39, 6.0, false],
]

## Hoja del reloj: 8 columnas × 4 filas de 32 × 32 px. Una fila por estado del
## plazo, ocho fotogramas de aguja en cada una.
const RELOJ_HOJA: String = "res://src/assets/sprites/reloj_plazo.png"
const RELOJ_DESTINO: String = "res://src/assets/sprites/reloj_plazo.tres"
const RELOJ_LADO: int = 32
const RELOJ_COLUMNAS: int = 8

## La aguja gira más deprisa cuanto menos queda: la urgencia se nota antes de
## leer el color, que es lo que pide no comunicar nada solo con color.
const RELOJ_ANIMACIONES: Array = [
	["al_dia", 0, 7, 4.0],
	["por_vencer", 8, 15, 6.0],
	["urgente", 16, 23, 9.0],
	["vencido", 24, 31, 13.0],
]


func _init() -> void:
	_construir_libro()
	_construir_reloj()
	quit()


## Recorta un fotograma de la hoja por su índice, en orden de lectura.
func _recorte(hoja: Texture2D, indice: int, ancho: int, alto: int, columnas: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = hoja
	@warning_ignore("integer_division")
	var fila: int = indice / columnas
	var columna: int = indice % columnas
	atlas.region = Rect2(columna * ancho, fila * alto, ancho, alto)
	return atlas


func _construir_libro() -> void:
	var hoja: Texture2D = load(LIBRO_HOJA)
	if hoja == null:
		push_error("[build_sprite_frames] No se pudo cargar " + LIBRO_HOJA)
		return

	var marcos: SpriteFrames = SpriteFrames.new()
	marcos.remove_animation("default")

	for anim: Array in LIBRO_ANIMACIONES:
		var nombre: String = str(anim[0])
		marcos.add_animation(nombre)
		marcos.set_animation_speed(nombre, float(anim[3]))
		marcos.set_animation_loop(nombre, bool(anim[4]))

		for i: int in range(int(anim[1]), int(anim[2]) + 1):
			marcos.add_frame(nombre, _recorte(hoja, i, LIBRO_ANCHO, LIBRO_ALTO, LIBRO_COLUMNAS))

		print("[build_sprite_frames] libro · %s: %d fotogramas" % [nombre, marcos.get_frame_count(nombre)])

	var error: int = ResourceSaver.save(marcos, LIBRO_DESTINO)
	print("[build_sprite_frames] %s escrito (error %d)" % [LIBRO_DESTINO, error])


func _construir_reloj() -> void:
	var hoja: Texture2D = load(RELOJ_HOJA)
	if hoja == null:
		push_error("[build_sprite_frames] No se pudo cargar " + RELOJ_HOJA)
		return

	var marcos: SpriteFrames = SpriteFrames.new()
	marcos.remove_animation("default")

	for anim: Array in RELOJ_ANIMACIONES:
		var nombre: String = str(anim[0])
		marcos.add_animation(nombre)
		marcos.set_animation_speed(nombre, float(anim[3]))
		marcos.set_animation_loop(nombre, true)

		for i: int in range(int(anim[1]), int(anim[2]) + 1):
			marcos.add_frame(nombre, _recorte(hoja, i, RELOJ_LADO, RELOJ_LADO, RELOJ_COLUMNAS))

		print("[build_sprite_frames] reloj · %s: %d fotogramas" % [nombre, marcos.get_frame_count(nombre)])

	var error: int = ResourceSaver.save(marcos, RELOJ_DESTINO)
	print("[build_sprite_frames] %s escrito (error %d)" % [RELOJ_DESTINO, error])
