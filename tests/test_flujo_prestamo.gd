## ============================================================================
## test_flujo_prestamo.gd — Pruebas de integración y de sistema
## ============================================================================
## Las otras dos suites prueban funciones aisladas. Esta prueba lo contrario: el
## cableado. Aquí no se llama a ninguna función del gestor directamente, se
## publican intenciones en el `EventBus` y se comprueba qué hizo el Autoload
## real con ellas.
##
## Esa es la diferencia que pide documentar la guía. Una prueba unitaria puede
## pasar con el bus desconectado, porque llama a la función por su nombre. Si
## `GlobalManager` dejara de suscribirse a `base_selected`, las pruebas de
## `test_global_manager.gd` seguirían verdes y el proyecto estaría roto: el
## plazo elegido no llegaría a ninguna parte. Lo que detecta eso es esta suite.
##
## Trabaja sobre el Autoload real, así que toca el archivo de guardado de verdad
## —eso es justamente lo que verifica SIS-01—. Para no dejar la sesión del
## lector alterada, `before()` guarda una copia del estado y `after()` la
## restituye y la reescribe en disco.
## ----------------------------------------------------------------------------

class_name TestFlujoPrestamo
extends GdUnitTestSuite

## Ejemplar de trabajo. Está en el catálogo publicado y lo verifica la primera
## comprobación de cada caso, de modo que un cambio de catálogo se note como un
## fallo claro y no como un error dentro del gestor.
const EJEMPLAR: String = "dune"
const PLAZO: String = "quincenal"
const DIAS_PLAZO: int = 15

## Copia del estado del lector, para devolverlo como estaba al terminar.
var _respaldo: Dictionary = {}

## Cargas útiles capturadas del bus durante el caso en curso.
var _comprobantes: Array[Dictionary] = []
var _estados: Array[String] = []


func before() -> void:
	_respaldo = GlobalManager.estado.duplicate(true)

	EventBus.receipt_changed.connect(_capturar_comprobante)
	EventBus.loan_state_changed.connect(_capturar_estado)


func after() -> void:
	EventBus.receipt_changed.disconnect(_capturar_comprobante)
	EventBus.loan_state_changed.disconnect(_capturar_estado)

	GlobalManager.estado = _respaldo
	GlobalManager._estado_prestamo = GlobalManager.EstadoPrestamo.EN_ESTANTE
	GlobalManager.guardar_datos()


func before_test() -> void:
	# Punto de partida limpio. El estado del ciclo se fija a mano, sin pasar por
	# `_cambiar_estado()`: es montaje de la prueba, no una transición del
	# dominio, y hacerlo por la puerta del dominio obligaría a recorrer el ciclo
	# entero solo para volver al principio.
	GlobalManager.estado = {
		"plan_activo": "diario",
		"prestamos": {},
		"pases": [],
		"pases_emitidos": 0,
		"total_dias": 0,
		"ejemplar_en_consulta": "",
		"categoria_activa": "",
		"borrador": {}
	}
	GlobalManager._estado_prestamo = GlobalManager.EstadoPrestamo.EN_ESTANTE

	_comprobantes.clear()
	_estados.clear()


func _capturar_comprobante(comprobante: Dictionary) -> void:
	_comprobantes.append(comprobante)


func _capturar_estado(nombre: String) -> void:
	_estados.append(nombre)


# --- INT-01: el plazo elegido llega al gestor por el bus ---------------------

func test_int_01_elegir_el_plazo_abre_el_comprobante() -> void:
	assert_object(GlobalManager.CATALOGO.buscar_libro(EJEMPLAR)).is_not_null()

	# Primera intención: el lector abre la ficha de un ejemplar.
	EventBus.item_opened.emit(EJEMPLAR)

	assert_str(str(GlobalManager.estado["ejemplar_en_consulta"])).is_equal(EJEMPLAR)
	assert_bool(_estados.has("en_consulta")).is_true()

	# Segunda intención: elige el plazo dentro de la tarjeta.
	EventBus.base_selected.emit(PLAZO)

	assert_bool(_estados.has("en_comprobante")).is_true()

	# El comprobante que viajó por el bus trae ya los datos del catálogo.
	var comprobante: Dictionary = _comprobantes.back()
	assert_bool(comprobante.is_empty()).is_false()
	assert_str(str(comprobante["id"])).is_equal(EJEMPLAR)
	assert_int(int(comprobante["dias_base"])).is_equal(DIAS_PLAZO)
	assert_int(int(comprobante["dias_total"])).is_equal(DIAS_PLAZO)
	assert_int(int(comprobante["pases_aplicados"])).is_equal(0)


func test_int_02_aplicar_un_pase_amplia_el_comprobante() -> void:
	GlobalManager.estado["pases"] = [
		{"id": "pase_001", "origen": "Prueba", "dias": GlobalManager.DIAS_POR_PASE}
	]

	EventBus.item_opened.emit(EJEMPLAR)
	EventBus.base_selected.emit(PLAZO)
	EventBus.draft_pass_applied.emit()

	var comprobante: Dictionary = _comprobantes.back()
	assert_int(int(comprobante["dias_extra"])).is_equal(GlobalManager.DIAS_POR_PASE)
	assert_int(int(comprobante["dias_total"])).is_equal(DIAS_PLAZO + GlobalManager.DIAS_POR_PASE)
	assert_int(int(comprobante["pases_aplicados"])).is_equal(1)

	# El pase se consumió: no puede seguir disponible después de aplicarse.
	assert_bool(GlobalManager.estado["pases"].is_empty()).is_true()


func test_int_03_cancelar_el_comprobante_no_toca_el_registro() -> void:
	EventBus.item_opened.emit(EJEMPLAR)
	EventBus.base_selected.emit(PLAZO)
	EventBus.item_closed.emit()

	# Cancelar devuelve a la consulta y borra el borrador, sin registrar nada.
	assert_bool(_estados.has("en_consulta")).is_true()
	assert_bool(GlobalManager.obtener_comprobante().is_empty()).is_true()
	assert_bool(GlobalManager.estado["prestamos"].is_empty()).is_true()


# --- SIS-01: ciclo completo y persistencia en disco --------------------------

func test_sis_01_el_prestamo_sobrevive_al_reinicio() -> void:
	# Recorrido completo por el bus, tal como lo haría el lector.
	EventBus.item_opened.emit(EJEMPLAR)
	EventBus.base_selected.emit(PLAZO)
	EventBus.item_added.emit(EJEMPLAR)

	# El estado REGISTRANDO dura de verdad: el gestor espera un temporizador
	# para que la animación del sello y el cambio de estado terminen juntos.
	await await_millis(int(GlobalManager.DURACION_REGISTRO * 1000.0) + 300)

	assert_bool(GlobalManager.estado["prestamos"].has(EJEMPLAR)).is_true()
	assert_int(int(GlobalManager.estado["total_dias"])).is_equal(DIAS_PLAZO)
	assert_bool(_estados.has("prestado")).is_true()

	# Se simula el cierre del programa: el registro en memoria se pierde y lo
	# único que queda es el archivo que el gestor escribió al confirmar.
	GlobalManager.estado["prestamos"] = {}
	GlobalManager.estado["total_dias"] = 0
	assert_bool(GlobalManager.estado["prestamos"].is_empty()).is_true()

	GlobalManager.cargar_datos()

	# El préstamo vuelve con su plazo intacto.
	assert_bool(GlobalManager.estado["prestamos"].has(EJEMPLAR)).is_true()
	var registro: Dictionary = GlobalManager.estado["prestamos"][EJEMPLAR]
	assert_str(str(registro["plan"])).is_equal(PLAZO)
	assert_int(GlobalManager.dias_de(registro)).is_equal(DIAS_PLAZO)


func test_sis_02_devolver_entrega_un_pase_y_libera_el_ejemplar() -> void:
	GlobalManager.estado["prestamos"] = {EJEMPLAR: {"plan": PLAZO, "extra_dias": 0}}

	EventBus.item_removed.emit(EJEMPLAR)

	# Devolver a tiempo es lo que premia la biblioteca.
	assert_bool(GlobalManager.estado["prestamos"].has(EJEMPLAR)).is_false()
	assert_int(GlobalManager.estado["pases"].size()).is_equal(1)
	assert_int(int(GlobalManager.estado["pases"][0]["dias"])).is_equal(GlobalManager.DIAS_POR_PASE)
	assert_int(int(GlobalManager.estado["total_dias"])).is_equal(0)
