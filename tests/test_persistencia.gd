## ============================================================================
## test_persistencia.gd — Regresiones encontradas durante el Laboratorio 10
## ============================================================================
## Las tres pruebas de esta suite fallaban cuando se escribieron. Cada una
## reproduce un defecto que las pruebas del laboratorio destaparon en el
## guardado, y queda aquí para que no vuelva: eso es lo que distingue una
## prueba de regresión de una prueba nueva.
##
## Los tres están registrados como Issues en GitHub y referenciados por su
## identificador en `TEST_REPORT.md`.
##
## Toca el archivo de guardado real, así que, igual que la suite de integración,
## respalda el estado del lector en `before()` y lo restituye en `after()`.
## ----------------------------------------------------------------------------

class_name TestPersistencia
extends GdUnitTestSuite

var _respaldo: Dictionary = {}


func before() -> void:
	_respaldo = GlobalManager.estado.duplicate(true)


func after() -> void:
	GlobalManager.estado = _respaldo
	GlobalManager._estado_prestamo = GlobalManager.EstadoPrestamo.EN_ESTANTE
	GlobalManager.guardar_datos()


func before_test() -> void:
	GlobalManager.estado["prestamos"] = {}
	GlobalManager.estado["pases"] = []
	GlobalManager.estado["borrador"] = {}
	GlobalManager.estado["plan_activo"] = "diario"
	GlobalManager._estado_prestamo = GlobalManager.EstadoPrestamo.EN_ESTANTE


# --- REG-01 ------------------------------------------------------------------

func test_reg_01_cargar_datos_deja_el_total_coherente() -> void:
	# Antes: `cargar_datos()` restituía los préstamos pero no recalculaba el
	# total, así que el estado quedaba con los préstamos nuevos y el total
	# viejo. No se notaba al arrancar porque `_ready()` recalculaba después.
	GlobalManager.estado["prestamos"] = {"dune": {"plan": "mensual", "extra_dias": 0}}
	GlobalManager.guardar_datos()

	# Se ensucia el total a propósito, como lo dejaría una sesión anterior.
	GlobalManager.estado["prestamos"] = {}
	GlobalManager.estado["total_dias"] = 999

	GlobalManager.cargar_datos()

	assert_int(int(GlobalManager.estado["total_dias"])).is_equal(30)


# --- REG-02 ------------------------------------------------------------------

func test_reg_02_el_plazo_activo_del_guardado_se_valida() -> void:
	# Antes: `plan_activo` era el único campo que entraba del disco sin pasar
	# por la tabla de plazos, al contrario que `prestamos` y `categoria_activa`.
	# Un guardado con un plazo inventado lo dejaba en el estado, y de ahí podía
	# llegar a `dias_de()`, que lo busca en DURACIONES_PLAN sin comprobarlo.
	var archivo: FileAccess = FileAccess.open(GlobalManager.SAVE_PATH, FileAccess.WRITE)
	assert_object(archivo).is_not_null()
	archivo.store_string(JSON.stringify({
		"version": GlobalManager.VERSION_GUARDADO,
		"plan_activo": "anual",
		"prestamos": {},
		"pases": [],
		"pases_emitidos": 0,
		"categoria_activa": ""
	}, "\t"))
	archivo.close()

	GlobalManager.cargar_datos()

	var plan: String = str(GlobalManager.estado["plan_activo"])
	assert_bool(GlobalManager.DURACIONES_PLAN.has(plan)).is_true()
	assert_str(plan).is_equal(GlobalManager.PLAN_POR_DEFECTO)


# --- REG-03 ------------------------------------------------------------------

func test_reg_03_los_identificadores_de_pase_no_se_repiten_tras_vaciar() -> void:
	# Antes: vaciar el registro reiniciaba `pases_emitidos` a cero, así que el
	# primer pase entregado después volvía a llamarse «pase_001», justo lo que
	# el contador persistido existía para evitar.
	GlobalManager.estado["prestamos"] = {"dune": {"plan": "diario", "extra_dias": 0}}
	EventBus.item_removed.emit("dune")
	var primero: String = str(GlobalManager.estado["pases"][0]["id"])

	EventBus.save_reset_requested.emit()
	assert_bool(GlobalManager.estado["pases"].is_empty()).is_true()

	GlobalManager.estado["prestamos"] = {"neuromante": {"plan": "diario", "extra_dias": 0}}
	EventBus.item_removed.emit("neuromante")
	var segundo: String = str(GlobalManager.estado["pases"][0]["id"])

	assert_str(segundo).is_not_equal(primero)
