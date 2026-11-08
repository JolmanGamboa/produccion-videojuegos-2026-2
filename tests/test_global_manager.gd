## ============================================================================
## test_global_manager.gd — Pruebas unitarias de las reglas del mostrador
## ============================================================================
## Suite unitaria: cada prueba examina una función del gestor **en aislamiento**,
## sobre una instancia propia que nunca entra en el árbol de escenas.
##
## Ese aislamiento es deliberado. `GlobalManager` es un Autoload, así que en
## ejecución siempre hay una instancia viva conectada al `EventBus` y al archivo
## de guardado. Si las pruebas usaran esa instancia, un fallo no distinguiría
## entre un error de cálculo y un efecto colateral de otra prueba. Al construir
## la instancia con `new()` y no añadirla al árbol, `_ready()` no se ejecuta: no
## hay suscripciones al bus, no se lee el disco y lo único que se mide es la
## función bajo prueba.
##
## La integración por el bus y el ciclo completo se prueban aparte, en
## `test_flujo_prestamo.gd`, que sí usa el Autoload real.
## ----------------------------------------------------------------------------

class_name TestGlobalManager
extends GdUnitTestSuite

const GuionGestor: GDScript = preload("res://src/core/global_manager.gd")

## Instancia aislada bajo prueba. Se reconstruye antes de cada caso para que
## ninguna prueba herede el estado que dejó la anterior.
var gestor: Node


func before_test() -> void:
	gestor = GuionGestor.new()


func after_test() -> void:
	gestor.free()


# --- UNI-01: cálculo de los días comprometidos -------------------------------

func test_dias_de_devuelve_el_plazo_base_de_cada_plan() -> void:
	# La tabla DURACIONES_PLAN es la regla de negocio: 1, 15 y 30 días.
	assert_int(gestor.dias_de({"plan": "diario", "extra_dias": 0})).is_equal(1)
	assert_int(gestor.dias_de({"plan": "quincenal", "extra_dias": 0})).is_equal(15)
	assert_int(gestor.dias_de({"plan": "mensual", "extra_dias": 0})).is_equal(30)


func test_dias_de_suma_las_ampliaciones_canjeadas_con_pases() -> void:
	# Dos pases de lectura sobre un plazo quincenal: 15 + 7 + 7 = 29.
	var registro: Dictionary = {
		"plan": "quincenal",
		"extra_dias": GuionGestor.DIAS_POR_PASE * 2
	}
	assert_int(gestor.dias_de(registro)).is_equal(29)


func test_dias_de_no_depende_del_plan_para_contar_las_ampliaciones() -> void:
	# Caso límite: el plazo más corto con una ampliación es mayor que el plazo
	# quincenal sin ampliar. El total no se puede deducir del nombre del plan.
	var ampliado: int = gestor.dias_de({"plan": "diario", "extra_dias": 21})
	var quincenal: int = gestor.dias_de({"plan": "quincenal", "extra_dias": 0})
	assert_int(ampliado).is_greater(quincenal)


# --- Saneamiento de lo leído del disco ---------------------------------------

func test_sanear_prestamos_conserva_el_registro_valido() -> void:
	var crudos: Dictionary = {
		"dune": {"plan": "mensual", "extra_dias": 7}
	}
	var limpios: Dictionary = gestor._sanear_prestamos(crudos)

	assert_int(limpios.size()).is_equal(1)
	assert_bool(limpios.has("dune")).is_true()
	assert_str(str(limpios["dune"]["plan"])).is_equal("mensual")
	assert_int(int(limpios["dune"]["extra_dias"])).is_equal(7)


func test_sanear_prestamos_descarta_el_ejemplar_fuera_de_catalogo() -> void:
	# Un guardado de una versión anterior puede nombrar libros que ya no están.
	var crudos: Dictionary = {
		"libro_que_no_existe": {"plan": "diario", "extra_dias": 0}
	}
	assert_bool(gestor._sanear_prestamos(crudos).is_empty()).is_true()


func test_sanear_prestamos_descarta_el_plazo_desconocido() -> void:
	# «anual» no está en DURACIONES_PLAN: admitirlo haría fallar dias_de().
	var crudos: Dictionary = {
		"dune": {"plan": "anual", "extra_dias": 0}
	}
	assert_bool(gestor._sanear_prestamos(crudos).is_empty()).is_true()


func test_sanear_prestamos_tolera_un_archivo_con_otra_forma() -> void:
	# JSON no garantiza tipos: lo leído puede no ser ni un diccionario.
	assert_bool(gestor._sanear_prestamos("no soy un diccionario").is_empty()).is_true()
	assert_bool(gestor._sanear_prestamos([1, 2, 3]).is_empty()).is_true()
	assert_bool(gestor._sanear_prestamos(null).is_empty()).is_true()


func test_sanear_pases_completa_los_campos_que_falten() -> void:
	# Un pase solo necesita «id»; el origen y los días tienen valor por defecto.
	var limpios: Array = gestor._sanear_pases([{"id": "pase_001"}])

	assert_int(limpios.size()).is_equal(1)
	assert_str(str(limpios[0]["origen"])).is_equal("Devolución")
	assert_int(int(limpios[0]["dias"])).is_equal(GuionGestor.DIAS_POR_PASE)


func test_sanear_pases_descarta_los_elementos_sin_identificador() -> void:
	var crudos: Array = [
		{"id": "pase_001", "origen": "Dune", "dias": 7},
		{"origen": "sin id"},
		"ni siquiera un diccionario"
	]
	assert_int(gestor._sanear_pases(crudos).size()).is_equal(1)


# --- Máquina de estados del ciclo del ejemplar -------------------------------

func test_la_tabla_de_transiciones_cubre_todos_los_estados() -> void:
	# Si un estado faltara en la tabla, `_cambiar_estado()` fallaría al
	# consultarla en lugar de rechazar la transición.
	var estados: Array = GuionGestor.NOMBRES_ESTADO.keys()
	for estado: int in estados:
		assert_bool(GuionGestor.TRANSICIONES.has(estado)).is_true()


func test_la_fsm_acepta_la_transicion_declarada() -> void:
	# El ciclo arranca en el estante y lo único permitido es pasar a consulta.
	assert_bool(gestor._cambiar_estado(GuionGestor.EstadoPrestamo.EN_CONSULTA)).is_true()


func test_la_fsm_rechaza_el_salto_que_no_esta_en_la_tabla() -> void:
	# Del estante no se puede pasar a prestado sin consultar ni confirmar: es
	# la garantía de que no existe un préstamo que nadie tramitó.
	assert_bool(gestor._cambiar_estado(GuionGestor.EstadoPrestamo.PRESTADO)).is_false()


func test_la_fsm_rechaza_quedarse_en_el_mismo_estado() -> void:
	# Reemitir el estado vigente no es una transición: devolver `true` haría que
	# las pantallas reaccionaran a un cambio que no ocurrió.
	assert_bool(gestor._cambiar_estado(GuionGestor.EstadoPrestamo.EN_ESTANTE)).is_false()
