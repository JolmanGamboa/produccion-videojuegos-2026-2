## ============================================================================
## test_shaders.gd — Lo que de los shaders sí se puede automatizar
## ============================================================================
## Que un contorno «se vea bien» no se prueba con aserciones: eso se mira. Lo
## que sí se prueba, y es lo que rompe en silencio, son las tres cosas que
## pueden desconectarse sin que nada lance un error:
##
##   1. Que el material esté asignado y apunte al shader que se cree.
##   2. Que los `uniform` se llamen como los llama el código que los escribe.
##      Escribir un parámetro inexistente en Godot no falla: se ignora, y el
##      efecto simplemente no cambia nunca.
##   3. Que la condición de encendido sea la correcta, que en el contorno son
##      dos cosas a la vez y es fácil dejar solo una.
##
## El tercer punto es el que de verdad se le escapa a la revisión a ojo: un
## contorno que aparece también sobre un ejemplar prestado parece correcto hasta
## que alguien intenta pulsarlo.
## ----------------------------------------------------------------------------

class_name TestShaders
extends GdUnitTestSuite

const ESCENA_LIBRO: PackedScene = preload("res://src/components/sprites/libro_animado.tscn")
const ESCENA_RELOJ: PackedScene = preload("res://src/components/sprites/reloj_plazo.tscn")

const SHADER_CONTORNO: String = "res://src/shaders/contorno_interaccion.gdshader"
const SHADER_SELLO: String = "res://src/shaders/sello_registrando.gdshader"
const SHADER_PULSO: String = "res://src/shaders/pulso_plazo.gdshader"


## Nombres de los `uniform` que declara un shader.
func _uniformes(ruta: String) -> Array[String]:
	var shader: Shader = load(ruta)
	var nombres: Array[String] = []
	for entrada: Dictionary in shader.get_shader_uniform_list():
		nombres.append(str(entrada["name"]))
	return nombres


# --- Los archivos de shader --------------------------------------------------

func test_los_tres_shaders_existen_y_cargan() -> void:
	for ruta: String in [SHADER_CONTORNO, SHADER_SELLO, SHADER_PULSO]:
		assert_bool(ResourceLoader.exists(ruta)).is_true()
		var shader: Shader = load(ruta)
		assert_object(shader).is_not_null()
		assert_object(shader).is_instanceof(Shader)
		assert_str(shader.code).contains("shader_type canvas_item")


func test_los_uniform_se_llaman_como_los_escribe_el_codigo() -> void:
	# Un `set_shader_parameter()` con un nombre que no existe no da error: se
	# ignora en silencio y el efecto se queda quieto para siempre.
	assert_array(_uniformes(SHADER_CONTORNO)).contains(["color_contorno", "grosor", "intensidad"])
	assert_array(_uniformes(SHADER_SELLO)).contains(["intensidad", "frecuencia", "velocidad"])
	assert_array(_uniformes(SHADER_PULSO)).contains(["urgencia", "color_pulso", "ritmo", "amplitud"])


func test_el_sello_desplaza_el_muestreo_y_no_la_geometria() -> void:
	# La distinción que pide la reflexión de la guía, comprobada sobre el
	# código: el shader toca las coordenadas de lectura, no VERTEX.
	var codigo: String = (load(SHADER_SELLO) as Shader).code
	assert_str(codigo).contains("uv_ondulado")
	assert_str(codigo).contains("texture(TEXTURE, uv_ondulado)")
	assert_bool(codigo.contains("VERTEX")).is_false()


func test_el_pulso_se_anima_solo_con_el_tiempo() -> void:
	# El Reto 2 pide que el resplandor no dependa de que GDScript le actualice
	# los parámetros cada fotograma. Que use TIME es justamente eso.
	var codigo: String = (load(SHADER_PULSO) as Shader).code
	assert_str(codigo).contains("TIME")
	# Y que no toque el alfa: el resplandor no puede encender el vacío de
	# alrededor ni recortar la silueta del reloj.
	assert_str(codigo).contains("vec4(encendido, texel.a)")


# --- El material llega al nodo ----------------------------------------------

func test_el_contorno_tiene_su_material_y_esta_apagado_al_nacer() -> void:
	var libro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	add_child(libro)
	await get_tree().process_frame

	var material: ShaderMaterial = libro.contorno.material as ShaderMaterial
	assert_object(material).is_not_null()
	assert_str(material.shader.resource_path).is_equal(SHADER_CONTORNO)
	assert_bool(libro.contorno.visible).is_false()


func test_cada_ejemplar_tiene_su_propio_material_de_contorno() -> void:
	# Con un material compartido, fijar el color de un estante se lo llevarían
	# también los ejemplares de los demás.
	var uno: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	var otro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	add_child(uno)
	add_child(otro)
	await get_tree().process_frame

	uno.fijar_color_contorno(Color.RED)
	otro.fijar_color_contorno(Color.BLUE)

	var color_uno: Color = (uno.contorno.material as ShaderMaterial).get_shader_parameter("color_contorno")
	var color_otro: Color = (otro.contorno.material as ShaderMaterial).get_shader_parameter("color_contorno")
	assert_bool(color_uno.is_equal_approx(Color.RED)).is_true()
	assert_bool(color_otro.is_equal_approx(Color.BLUE)).is_true()


func test_el_color_pedido_antes_del_ready_no_se_pierde() -> void:
	# La sala arma la tarjeta entera y la añade al árbol después, así que
	# reparte los colores antes de que este componente tenga nodos.
	var libro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	libro.fijar_color_contorno(Color.GREEN)
	add_child(libro)
	await get_tree().process_frame

	var color: Color = (libro.contorno.material as ShaderMaterial).get_shader_parameter("color_contorno")
	assert_bool(color.is_equal_approx(Color.GREEN)).is_true()


# --- La condición de encendido del contorno ---------------------------------

func test_el_contorno_exige_interaccion_y_cursor_a_la_vez() -> void:
	var libro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	add_child(libro)
	await get_tree().process_frame

	libro.marcar_interactuable(true)
	assert_bool(libro.contorno.visible).is_false()

	libro.marcar_cursor(true)
	assert_bool(libro.contorno.visible).is_true()

	# Un ejemplar que deja de poder prestarse pierde el borde aunque el cursor
	# siga encima: es el caso del libro que acaba de salir prestado.
	libro.marcar_interactuable(false)
	assert_bool(libro.contorno.visible).is_false()


func test_el_contorno_sigue_la_misma_animacion_que_el_ejemplar() -> void:
	# Si el borde se quedara en otro fotograma, dejaría de corresponderse con la
	# silueta en cuanto el libro se abriera.
	var libro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	add_child(libro)
	await get_tree().process_frame

	libro.aplicar_estado(EventBus.ESTADO_EN_CONSULTA)
	assert_str(str(libro.contorno.animation)).is_equal(str(libro.sprite.animation))


# --- El sello solo durante el registro --------------------------------------

func test_el_sello_se_monta_solo_mientras_se_registra() -> void:
	var libro: LibroAnimado = auto_free(ESCENA_LIBRO.instantiate())
	add_child(libro)
	await get_tree().process_frame

	assert_object(libro.sprite.material).is_null()

	libro.aplicar_estado(EventBus.ESTADO_REGISTRANDO)
	assert_object(libro.sprite.material).is_not_null()
	assert_str((libro.sprite.material as ShaderMaterial).shader.resource_path).is_equal(SHADER_SELLO)

	# Y se retira al terminar, para que los demás estados no paguen un shader
	# que no haría nada.
	libro.aplicar_estado(EventBus.ESTADO_PRESTADO)
	assert_object(libro.sprite.material).is_null()


# --- El pulso del reloj ------------------------------------------------------

func test_el_pulso_cubre_los_cuatro_tramos_del_plazo() -> void:
	for estado: String in RelojPlazo.ESTADOS:
		assert_bool(RelojPlazo.PULSO_DE_ESTADO.has(estado)).is_true()


func test_la_urgencia_crece_tramo_a_tramo() -> void:
	var anterior: float = -1.0
	for estado: String in RelojPlazo.ESTADOS:
		var urgencia: float = float(RelojPlazo.PULSO_DE_ESTADO[estado][0])
		assert_float(urgencia).is_greater(anterior)
		anterior = urgencia

	# Los extremos están fijados: un plazo holgado no late y uno vencido late
	# todo lo que el shader permite.
	assert_float(float(RelojPlazo.PULSO_DE_ESTADO[EventBus.PLAZO_AL_DIA][0])).is_equal(0.0)
	assert_float(float(RelojPlazo.PULSO_DE_ESTADO[EventBus.PLAZO_VENCIDO][0])).is_equal(1.0)


func test_el_reloj_escribe_la_urgencia_al_cambiar_de_estado() -> void:
	var reloj: RelojPlazo = auto_free(ESCENA_RELOJ.instantiate())
	add_child(reloj)
	await get_tree().process_frame

	var material: ShaderMaterial = reloj.sprite.material as ShaderMaterial
	assert_str(material.shader.resource_path).is_equal(SHADER_PULSO)

	reloj.aplicar_estado(EventBus.PLAZO_VENCIDO)
	assert_float(float(material.get_shader_parameter("urgencia"))).is_equal(1.0)

	reloj.aplicar_estado(EventBus.PLAZO_AL_DIA)
	assert_float(float(material.get_shader_parameter("urgencia"))).is_equal(0.0)


func test_cada_reloj_tiene_su_propio_material() -> void:
	# Con uno compartido, un préstamo vencido haría latir también los relojes de
	# los préstamos que van al día.
	var uno: RelojPlazo = auto_free(ESCENA_RELOJ.instantiate())
	var otro: RelojPlazo = auto_free(ESCENA_RELOJ.instantiate())
	add_child(uno)
	add_child(otro)
	await get_tree().process_frame

	uno.aplicar_estado(EventBus.PLAZO_VENCIDO)
	otro.aplicar_estado(EventBus.PLAZO_AL_DIA)

	assert_float(float((uno.sprite.material as ShaderMaterial).get_shader_parameter("urgencia"))).is_equal(1.0)
	assert_float(float((otro.sprite.material as ShaderMaterial).get_shader_parameter("urgencia"))).is_equal(0.0)


# --- El margen de las hojas de sprites --------------------------------------

func test_las_hojas_llevan_margen_para_el_muestreo_vecino() -> void:
	# Sin margen, los ocho vecinos que consulta el contorno en el borde de un
	# fotograma son píxeles del fotograma de al lado, y el borde sale con la
	# silueta equivocada. Es el fallo más difícil de diagnosticar del
	# laboratorio, porque el shader es correcto y aun así se ve mal.
	var libro: SpriteFrames = load("res://src/assets/sprites/libro_biblioteca.tres")
	var fotograma: AtlasTexture = libro.get_frame_texture("cerrado", 0) as AtlasTexture
	assert_object(fotograma).is_not_null()
	assert_int(int(fotograma.region.size.x)).is_equal(32)
	assert_int(int(fotograma.region.size.y)).is_equal(39)

	var reloj: SpriteFrames = load("res://src/assets/sprites/reloj_plazo.tres")
	var cuadro: AtlasTexture = reloj.get_frame_texture(EventBus.PLAZO_AL_DIA, 0) as AtlasTexture
	assert_int(int(cuadro.region.size.x)).is_equal(36)
	assert_int(int(cuadro.region.size.y)).is_equal(36)
