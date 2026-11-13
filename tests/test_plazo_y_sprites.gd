## ============================================================================
## test_plazo_y_sprites.gd — El plazo como tiempo, y el sprite que lo refleja
## ============================================================================
## Dos cosas que antes no se podían probar porque no existían: que los días
## corran y que el estado del objeto elija su animación.
##
## La parte del sprite no comprueba que se vea bien —eso no se automatiza— sino
## que el mapa de estado a animación esté completo y que los recursos tengan los
## fotogramas que dicen tener. Son justamente los errores que no dan la cara:
## un estado sin animación deja el libro congelado y no lanza ningún error.
## ----------------------------------------------------------------------------

class_name TestPlazoYSprites
extends GdUnitTestSuite

const MARCOS_LIBRO: SpriteFrames = preload("res://src/assets/sprites/libro_biblioteca.tres")
const MARCOS_RELOJ: SpriteFrames = preload("res://src/assets/sprites/reloj_plazo.tres")
const GuionGestor: GDScript = preload("res://src/core/global_manager.gd")

var gestor: Node
var _respaldo: Dictionary = {}


func before() -> void:
	_respaldo = GlobalManager.estado.duplicate(true)


func after() -> void:
	GlobalManager.estado = _respaldo
	GlobalManager._estado_prestamo = GlobalManager.EstadoPrestamo.EN_ESTANTE
	GlobalManager.guardar_datos()


func before_test() -> void:
	gestor = GuionGestor.new()
	gestor.estado = gestor.estado.duplicate(true)


func after_test() -> void:
	gestor.free()


## Construye un préstamo que empezó hace los días que se le pidan.
func _prestamo(plan: String, extra: int, dias_atras: int) -> Dictionary:
	return {
		"plan": plan,
		"extra_dias": extra,
		"inicio": gestor.ahora() - dias_atras * GuionGestor.SEGUNDOS_POR_DIA
	}


# --- Los días que quedan -----------------------------------------------------

func test_un_prestamo_recien_registrado_conserva_todo_el_plazo() -> void:
	assert_int(gestor.dias_restantes(_prestamo("mensual", 0, 0))).is_equal(30)


func test_los_dias_transcurridos_se_descuentan() -> void:
	assert_int(gestor.dias_restantes(_prestamo("mensual", 0, 12))).is_equal(18)


func test_las_ampliaciones_corren_la_fecha_de_vencimiento() -> void:
	# Un quincenal con doce días encima está a tres de vencer; un pase lo deja
	# a diez. Es lo que hace que canjear sirva de algo cuando aprieta el plazo.
	assert_int(gestor.dias_restantes(_prestamo("quincenal", 0, 12))).is_equal(3)
	assert_int(gestor.dias_restantes(_prestamo("quincenal", GuionGestor.DIAS_POR_PASE, 12))).is_equal(10)


func test_un_prestamo_vencido_cuenta_en_negativo() -> void:
	# El negativo no es un error: la pantalla lo usa para decir cuánto hace que
	# venció, y es información distinta de «vencido» a secas.
	assert_int(gestor.dias_restantes(_prestamo("diario", 0, 4))).is_equal(-3)


# --- El estado del plazo -----------------------------------------------------

func test_el_estado_del_plazo_recorre_los_cuatro_tramos() -> void:
	# Treinta días de plazo: holgado, por la mitad, apretado y vencido.
	assert_str(gestor.estado_plazo(_prestamo("mensual", 0, 0))).is_equal(GuionGestor.PLAZO_AL_DIA)
	assert_str(gestor.estado_plazo(_prestamo("mensual", 0, 18))).is_equal(GuionGestor.PLAZO_POR_VENCER)
	assert_str(gestor.estado_plazo(_prestamo("mensual", 0, 25))).is_equal(GuionGestor.PLAZO_URGENTE)
	assert_str(gestor.estado_plazo(_prestamo("mensual", 0, 31))).is_equal(GuionGestor.PLAZO_VENCIDO)


func test_el_dia_del_vencimiento_ya_cuenta_como_vencido() -> void:
	# Caso límite: con cero días restantes el plazo se cumplió. Dejarlo en
	# «urgente» haría que el reloj nunca llegara a rojo en un plazo diario.
	assert_int(gestor.dias_restantes(_prestamo("diario", 0, 1))).is_equal(0)
	assert_str(gestor.estado_plazo(_prestamo("diario", 0, 1))).is_equal(GuionGestor.PLAZO_VENCIDO)


# --- Adelantar el calendario -------------------------------------------------

func test_adelantar_el_calendario_envejece_los_prestamos() -> void:
	GlobalManager.estado["desfase_dias"] = 0
	GlobalManager.estado["prestamos"] = {
		"dune": {"plan": "mensual", "extra_dias": 0, "inicio": GlobalManager.ahora()}
	}
	var registro: Dictionary = GlobalManager.estado["prestamos"]["dune"]
	assert_str(GlobalManager.estado_plazo(registro)).is_equal(GlobalManager.PLAZO_AL_DIA)

	EventBus.time_advanced.emit(25)

	# Nada dentro del dominio distingue un día adelantado de uno transcurrido.
	assert_int(GlobalManager.dias_restantes(registro)).is_equal(5)
	assert_str(GlobalManager.estado_plazo(registro)).is_equal(GlobalManager.PLAZO_URGENTE)

	EventBus.time_advanced.emit(10)
	assert_str(GlobalManager.estado_plazo(registro)).is_equal(GlobalManager.PLAZO_VENCIDO)


func test_el_resumen_lleva_los_dias_restantes_y_el_estado() -> void:
	GlobalManager.estado["desfase_dias"] = 0
	GlobalManager.estado["prestamos"] = {
		"dune": {
			"plan": "quincenal",
			"extra_dias": 0,
			"inicio": GlobalManager.ahora() - 10 * GlobalManager.SEGUNDOS_POR_DIA
		}
	}

	var fila: Dictionary = GlobalManager.obtener_resumen()["dune"]
	assert_int(int(fila["dias_restantes"])).is_equal(5)
	assert_str(str(fila["estado_plazo"])).is_equal(GlobalManager.PLAZO_POR_VENCER)


# --- Migración del guardado de la versión 1 ---------------------------------

func test_un_guardado_de_la_version_1_no_pierde_los_prestamos() -> void:
	# Quien venía de antes no tenía fecha de inicio. Descartar el archivo sería
	# lo cómodo; migrarlo es lo correcto, y el préstamo empieza a contar ahora.
	var archivo: FileAccess = FileAccess.open(GlobalManager.SAVE_PATH, FileAccess.WRITE)
	assert_object(archivo).is_not_null()
	archivo.store_string(JSON.stringify({
		"version": 1,
		"plan_activo": "mensual",
		"prestamos": {"dune": {"plan": "mensual", "extra_dias": 0}},
		"pases": [],
		"pases_emitidos": 0,
		"categoria_activa": ""
	}, "\t"))
	archivo.close()

	GlobalManager.estado["prestamos"] = {}
	GlobalManager.cargar_datos()

	assert_bool(GlobalManager.estado["prestamos"].has("dune")).is_true()
	var registro: Dictionary = GlobalManager.estado["prestamos"]["dune"]
	assert_bool(registro.has("inicio")).is_true()
	assert_int(GlobalManager.dias_restantes(registro)).is_equal(30)


# --- Los recursos de animación ----------------------------------------------

func test_cada_estado_del_ciclo_tiene_su_animacion_en_el_libro() -> void:
	# Un estado sin animación deja el libro congelado sin lanzar ningún error:
	# es el fallo silencioso que esta prueba existe para impedir.
	for nombre_estado: String in LibroAnimado.ANIMACION_DE_ESTADO.keys():
		var animacion: String = str(LibroAnimado.ANIMACION_DE_ESTADO[nombre_estado])
		assert_bool(MARCOS_LIBRO.has_animation(animacion)).is_true()
		assert_int(MARCOS_LIBRO.get_frame_count(animacion)).is_greater(0)


func test_el_libro_cubre_los_cinco_estados_del_ciclo() -> void:
	for nombre_estado: String in GuionGestor.NOMBRES_ESTADO.values():
		assert_bool(LibroAnimado.ANIMACION_DE_ESTADO.has(nombre_estado)).is_true()


func test_abrir_el_libro_encadena_con_pasar_hojas_en_bucle() -> void:
	# La ficha se queda abierta mientras el lector la mira, así que la animación
	# de apertura no puede quedarse en su último fotograma.
	assert_str(str(LibroAnimado.ENCADENA["abriendo"])).is_equal("pasando_hojas")
	assert_bool(MARCOS_LIBRO.get_animation_loop("pasando_hojas")).is_true()
	assert_bool(MARCOS_LIBRO.get_animation_loop("abriendo")).is_false()


func test_cada_estado_del_plazo_tiene_su_animacion_en_el_reloj() -> void:
	for estado: String in [
		GuionGestor.PLAZO_AL_DIA,
		GuionGestor.PLAZO_POR_VENCER,
		GuionGestor.PLAZO_URGENTE,
		GuionGestor.PLAZO_VENCIDO
	]:
		assert_bool(MARCOS_RELOJ.has_animation(estado)).is_true()
		assert_int(MARCOS_RELOJ.get_frame_count(estado)).is_equal(8)
		assert_bool(MARCOS_RELOJ.get_animation_loop(estado)).is_true()


func test_la_aguja_se_acelera_a_medida_que_aprieta_el_plazo() -> void:
	# La velocidad es el segundo canal del reloj: la urgencia se nota aunque no
	# se distingan los colores del aro.
	var al_dia: float = MARCOS_RELOJ.get_animation_speed(GuionGestor.PLAZO_AL_DIA)
	var por_vencer: float = MARCOS_RELOJ.get_animation_speed(GuionGestor.PLAZO_POR_VENCER)
	var urgente: float = MARCOS_RELOJ.get_animation_speed(GuionGestor.PLAZO_URGENTE)
	var vencido: float = MARCOS_RELOJ.get_animation_speed(GuionGestor.PLAZO_VENCIDO)

	assert_float(por_vencer).is_greater(al_dia)
	assert_float(urgente).is_greater(por_vencer)
	assert_float(vencido).is_greater(urgente)
