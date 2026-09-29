extends Node


# --- Constantes del dominio -------------------------------------------------

## Plazos disponibles, en días. Es la tabla que define el negocio.
const DURACIONES_PLAN: Dictionary = {
	"diario": 1,
	"quincenal": 15,
	"mensual": 30
}

## Etiqueta legible de cada plazo, para las pantallas que lo muestran.
const NOMBRES_PLAN: Dictionary = {
	"diario": "Diario",
	"quincenal": "Quincenal",
	"mensual": "Mensual"
}

## Una constante por ejemplar del catálogo: identificador, título y autor.
## Es la fuente única de verdad sobre qué libros existen en la biblioteca.
const CATALOGO: Dictionary = {
	"dune": {"titulo": "Dune", "autor": "Frank Herbert"},
	"neuromante": {"titulo": "Neuromante", "autor": "William Gibson"},
	"cien_anios": {"titulo": "Cien años de soledad", "autor": "Gabriel García Márquez"},
	"pragmatico": {"titulo": "El programador pragmático", "autor": "Hunt y Thomas"}
}

const PLAN_POR_DEFECTO: String = "diario"

# --- Máquina de estados del ciclo del ejemplar (Laboratorio 6) -------------

## Estados posibles de un ejemplar durante su ciclo de préstamo. Modelan el
## recorrido completo: el libro descansa en el estante, el lector lo consulta,
## el mostrador registra el préstamo y el ejemplar sale de la sala.
enum EstadoPrestamo { EN_ESTANTE, EN_CONSULTA, REGISTRANDO, PRESTADO }

## Transiciones permitidas desde cada estado. Cualquier salto que no aparezca
## en esta tabla es rechazado por `_cambiar_estado()`.
const TRANSICIONES: Dictionary = {
	EstadoPrestamo.EN_ESTANTE: [EstadoPrestamo.EN_CONSULTA],
	EstadoPrestamo.EN_CONSULTA: [EstadoPrestamo.REGISTRANDO, EstadoPrestamo.EN_ESTANTE],
	EstadoPrestamo.REGISTRANDO: [EstadoPrestamo.PRESTADO, EstadoPrestamo.EN_CONSULTA],
	EstadoPrestamo.PRESTADO: [EstadoPrestamo.EN_ESTANTE]
}

## Nombre público de cada estado, compartido con las pantallas vía EventBus.
const NOMBRES_ESTADO: Dictionary = {
	EstadoPrestamo.EN_ESTANTE: "en_estante",
	EstadoPrestamo.EN_CONSULTA: "en_consulta",
	EstadoPrestamo.REGISTRANDO: "registrando",
	EstadoPrestamo.PRESTADO: "prestado"
}

## Cuánto tarda el mostrador en sellar el préstamo. La interfaz anima dentro de
## esta ventana, de modo que la animación y el estado terminan juntos.
const DURACION_REGISTRO: float = 0.6

## Estado vigente del ciclo. Solo `_cambiar_estado()` puede modificarlo.
var _estado_prestamo: EstadoPrestamo = EstadoPrestamo.EN_ESTANTE

# --- Estado global de la biblioteca -----------------------------------------

## Colección única de datos lógicos. `prestamos` mapea id de libro → plazo.
var estado: Dictionary = {
	"plan_activo": PLAN_POR_DEFECTO,
	"prestamos": {},
	"total_dias": 0,
	"ejemplar_en_consulta": ""
}


func _ready() -> void:
	# Suscripción a las intenciones publicadas por la interfaz.
	EventBus.base_selected.connect(_on_base_selected)
	EventBus.item_added.connect(_on_item_added)
	EventBus.item_removed.connect(_on_item_removed)
	EventBus.item_opened.connect(_on_item_opened)
	EventBus.item_closed.connect(_on_item_closed)

	_recalcular()
	print("[global_manager] Registro de préstamos inicializado.")


# --- Suscriptores de intenciones de la GUI ----------------------------------

## Fija el plazo con el que se registrarán los siguientes préstamos.
func _on_base_selected(base_name: String) -> void:
	if _estado_prestamo != EstadoPrestamo.EN_CONSULTA:
		print("[global_manager] Plazo ignorado: no hay ningún ejemplar en consulta.")
		return

	if not DURACIONES_PLAN.has(base_name):
		push_warning("[global_manager] Plazo desconocido: " + base_name)
		return

	estado["plan_activo"] = base_name
	print("[global_manager] Plazo activo -> %s (%d días)" % [base_name, int(DURACIONES_PLAN[base_name])])


## Registra un ejemplar en préstamo con el plazo vigente. La solicitud solo se
## atiende si hay un ejemplar en consulta: ese es el permiso que da el estado.
func _on_item_added(item_id: String) -> void:
	# Transición de entrada. Si no es válida (no hay nada en consulta, o ya se
	# está registrando) la solicitud se descarta sin tocar el registro.
	if not _cambiar_estado(EstadoPrestamo.REGISTRANDO):
		return

	# El estado REGISTRANDO tiene duración real: es la ventana en la que la
	# interfaz anima el sello del préstamo y mantiene sus controles bloqueados.
	await get_tree().create_timer(DURACION_REGISTRO).timeout

	if not CATALOGO.has(item_id):
		push_warning("[global_manager] Ejemplar fuera de catálogo: " + item_id)
		_cambiar_estado(EstadoPrestamo.EN_CONSULTA)
		EventBus.loan_result.emit(false, "Ese ejemplar no pertenece al catálogo.")
		return

	var prestamos: Dictionary = estado["prestamos"]
	if prestamos.has(item_id):
		print("[global_manager] Ejemplar ya prestado: " + item_id)
		_cambiar_estado(EstadoPrestamo.EN_CONSULTA)
		EventBus.loan_result.emit(false, "«%s» ya está prestado. Devuélvelo antes de volver a sacarlo." % str(CATALOGO[item_id]["titulo"]))
		return

	prestamos[item_id] = estado["plan_activo"]
	print("[global_manager] Préstamo registrado: %s (%s)" % [item_id, str(estado["plan_activo"])])

	_cambiar_estado(EstadoPrestamo.PRESTADO)
	EventBus.loan_result.emit(true, "«%s» sale de la sala con plazo %s." % [
		str(CATALOGO[item_id]["titulo"]),
		str(NOMBRES_PLAN[estado["plan_activo"]])
	])
	_recalcular()

	# El estado PRESTADO es de cierre: se muestra la confirmación y el ejemplar
	# vuelve conceptualmente al estante para empezar un ciclo nuevo.
	await get_tree().create_timer(DURACION_REGISTRO).timeout
	estado["ejemplar_en_consulta"] = ""
	_cambiar_estado(EstadoPrestamo.EN_ESTANTE)


## Devuelve un ejemplar y lo retira del registro.
func _on_item_removed(item_id: String) -> void:
	# Una devolución en mitad de un registro dejaría el ciclo descuadrado.
	if _estado_prestamo == EstadoPrestamo.REGISTRANDO:
		print("[global_manager] Devolución bloqueada: hay un préstamo en curso.")
		return

	var prestamos: Dictionary = estado["prestamos"]
	if not prestamos.has(item_id):
		return

	prestamos.erase(item_id)
	print("[global_manager] Ejemplar devuelto: " + item_id)
	_recalcular()


## Saca un ejemplar del estante para consultarlo. Cambiar de libro mientras ya
## se está consultando no es una transición: solo cambia cuál está abierto.
func _on_item_opened(item_id: String) -> void:
	if not CATALOGO.has(item_id):
		push_warning("[global_manager] Ejemplar fuera de catálogo: " + item_id)
		return

	if _estado_prestamo == EstadoPrestamo.REGISTRANDO or _estado_prestamo == EstadoPrestamo.PRESTADO:
		print("[global_manager] Consulta bloqueada: hay un préstamo en curso.")
		return

	estado["ejemplar_en_consulta"] = item_id
	print("[global_manager] Ejemplar en consulta: " + item_id)

	_cambiar_estado(EstadoPrestamo.EN_CONSULTA)
	EventBus.loan_result.emit(true, "Elige el plazo para llevarte «%s»." % str(CATALOGO[item_id]["titulo"]))


## Devuelve el ejemplar al estante sin registrarlo.
func _on_item_closed() -> void:
	if not _cambiar_estado(EstadoPrestamo.EN_ESTANTE):
		return

	estado["ejemplar_en_consulta"] = ""
	EventBus.loan_result.emit(true, "El ejemplar volvió al estante.")


# --- Máquina de estados -----------------------------------------------------

## Único punto del sistema que modifica el estado del ciclo. Valida la
## transición contra `TRANSICIONES` y notifica el cambio por el bus.
## Devuelve `true` solo si la transición se realizó.
func _cambiar_estado(nuevo_estado: EstadoPrestamo) -> bool:
	if nuevo_estado == _estado_prestamo:
		return false

	var permitidas: Array = TRANSICIONES[_estado_prestamo]
	if not permitidas.has(nuevo_estado):
		push_warning("[global_manager] Transición inválida: %s -> %s" % [
			str(NOMBRES_ESTADO[_estado_prestamo]),
			str(NOMBRES_ESTADO[nuevo_estado])
		])
		print("[global_manager] Transición rechazada: %s -> %s" % [
			str(NOMBRES_ESTADO[_estado_prestamo]),
			str(NOMBRES_ESTADO[nuevo_estado])
		])
		return false

	var anterior: EstadoPrestamo = _estado_prestamo
	_estado_prestamo = nuevo_estado

	print("[global_manager] Ciclo del ejemplar: %s -> %s" % [
		str(NOMBRES_ESTADO[anterior]),
		str(NOMBRES_ESTADO[nuevo_estado])
	])
	EventBus.loan_state_changed.emit(str(NOMBRES_ESTADO[nuevo_estado]))
	return true


# --- Cálculo centralizado ---------------------------------------------------

## Suma los días comprometidos y notifica el estado al sistema completo.
func _recalcular() -> void:
	var total: int = 0
	var prestamos: Dictionary = estado["prestamos"]

	for item_id: String in prestamos.keys():
		total += int(DURACIONES_PLAN[prestamos[item_id]])

	estado["total_dias"] = total

	EventBus.total_changed.emit(total)
	EventBus.loans_updated.emit(obtener_resumen())


## Construye el resumen legible de los préstamos vigentes.
## Devuelve: { item_id: { titulo, autor, plan, dias } }
func obtener_resumen() -> Dictionary:
	var resumen: Dictionary = {}
	var prestamos: Dictionary = estado["prestamos"]

	for item_id: String in prestamos.keys():
		var plan: String = str(prestamos[item_id])
		var libro: Dictionary = CATALOGO[item_id]
		resumen[item_id] = {
			"titulo": libro["titulo"],
			"autor": libro["autor"],
			"plan": NOMBRES_PLAN[plan],
			"dias": int(DURACIONES_PLAN[plan])
		}

	return resumen


## Reemite el estado vigente. La invoca `MainApp` al montar un panel nuevo, de
## forma que la interfaz entrante se sincronice sin consultar a este nodo.
func emitir_estado_actual() -> void:
	EventBus.total_changed.emit(int(estado["total_dias"]))
	EventBus.loans_updated.emit(obtener_resumen())
	EventBus.loan_state_changed.emit(str(NOMBRES_ESTADO[_estado_prestamo]))
