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

# --- Persistencia en disco (Laboratorio 7) ----------------------------------

## Ruta del archivo de guardado. `user://` apunta a la carpeta de datos del
## usuario en escritorio y al almacenamiento del navegador (IndexedDB) en la
## versión Web, de modo que el mismo código sirve para ambos destinos.
const SAVE_PATH: String = "user://save_data.json"

## Versión del esquema guardado. Si el archivo trae otra, se descarta en vez de
## interpretarlo mal: es preferible empezar limpio a corromper el registro.
const VERSION_GUARDADO: int = 1

## Días que añade un pase de lectura al plazo de un préstamo vigente.
const DIAS_POR_PASE: int = 7

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

## Colección única de datos lógicos.
## `prestamos` mapea id de libro → { plan, extra_dias }, donde `extra_dias`
## acumula las ampliaciones canjeadas con pases de lectura.
## `pases` es la colección persistida: cada elemento es { id, origen, dias }.
var estado: Dictionary = {
	"plan_activo": PLAN_POR_DEFECTO,
	"prestamos": {},
	"pases": [],
	"pases_emitidos": 0,
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
	EventBus.pass_redeemed.connect(_on_pass_redeemed)
	EventBus.save_reset_requested.connect(_on_save_reset_requested)

	# La carga va antes del primer cálculo: el total debe reflejar lo que había
	# en disco, no un registro vacío que luego se corrige.
	cargar_datos()

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

	prestamos[item_id] = {"plan": estado["plan_activo"], "extra_dias": 0}
	print("[global_manager] Préstamo registrado: %s (%s)" % [item_id, str(estado["plan_activo"])])

	# Cada cambio del registro se escribe en disco de inmediato: así un cierre
	# inesperado no deja la sesión a medias.
	guardar_datos()

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
	EventBus.consultation_changed.emit("")
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

	# Devolver a tiempo es lo que premia la biblioteca: cada devolución entrega
	# un pase de lectura, que queda guardado en disco junto al registro.
	_emitir_pase(str(CATALOGO[item_id]["titulo"]))

	guardar_datos()
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

	EventBus.consultation_changed.emit(item_id)
	_cambiar_estado(EstadoPrestamo.EN_CONSULTA)
	EventBus.loan_result.emit(true, "Elige el plazo para llevarte «%s»." % str(CATALOGO[item_id]["titulo"]))


## Devuelve el ejemplar al estante sin registrarlo.
func _on_item_closed() -> void:
	if not _cambiar_estado(EstadoPrestamo.EN_ESTANTE):
		return

	estado["ejemplar_en_consulta"] = ""
	EventBus.consultation_changed.emit("")
	EventBus.loan_result.emit(true, "El ejemplar volvió al estante.")


# --- Pases de lectura -------------------------------------------------------

## Crea un pase nuevo y lo añade a la colección. El contador `pases_emitidos`
## se persiste para que los identificadores no se repitan entre sesiones.
func _emitir_pase(origen: String) -> void:
	estado["pases_emitidos"] = int(estado["pases_emitidos"]) + 1

	var pase: Dictionary = {
		"id": "pase_%03d" % int(estado["pases_emitidos"]),
		"origen": origen,
		"dias": DIAS_POR_PASE
	}
	estado["pases"].append(pase)

	print("[global_manager] Pase entregado: %s (por devolver «%s»)" % [str(pase["id"]), origen])
	EventBus.pass_result.emit(true, "Ganaste un pase de lectura por devolver «%s»." % origen)


## Canjea un pase para ampliar el plazo de un préstamo vigente. Es el consumo
## que cierra el ciclo: el pase desaparece de la colección y el archivo de
## guardado se reescribe, de modo que no reaparece en la siguiente sesión.
func _on_pass_redeemed(item_id: String) -> void:
	# Un canje en mitad de un registro dejaría el total descuadrado.
	if _estado_prestamo == EstadoPrestamo.REGISTRANDO:
		print("[global_manager] Canje bloqueado: hay un préstamo en curso.")
		return

	var prestamos: Dictionary = estado["prestamos"]
	if not prestamos.has(item_id):
		EventBus.pass_result.emit(false, "Ese ejemplar no está en préstamo.")
		return

	var pases: Array = estado["pases"]
	if pases.is_empty():
		print("[global_manager] Canje rechazado: no hay pases disponibles.")
		EventBus.pass_result.emit(false, "No tienes pases de lectura. Devuelve un ejemplar para ganar uno.")
		return

	# Se consume el pase más antiguo, para que la colección se comporte como una
	# fila y el lector no tenga que elegir cuál gastar.
	var pase: Dictionary = pases.pop_front()
	var registro: Dictionary = prestamos[item_id]
	registro["extra_dias"] = int(registro["extra_dias"]) + int(pase["dias"])

	print("[global_manager] Pase %s canjeado en %s (+%d días)" % [
		str(pase["id"]),
		item_id,
		int(pase["dias"])
	])

	guardar_datos()
	_recalcular()

	EventBus.pass_result.emit(true, "«%s» amplió su plazo %d días. Quedan %d pases." % [
		str(CATALOGO[item_id]["titulo"]),
		int(pase["dias"]),
		pases.size()
	])


## Vacía el registro y reescribe el archivo de guardado. Permite repetir la
## prueba de persistencia sin salir del proyecto ni borrar el archivo a mano.
func _on_save_reset_requested() -> void:
	if _estado_prestamo != EstadoPrestamo.EN_ESTANTE:
		print("[global_manager] Reinicio bloqueado: hay una consulta o un registro en curso.")
		EventBus.pass_result.emit(false, "Cierra la consulta abierta antes de vaciar el registro.")
		return

	estado["prestamos"] = {}
	estado["pases"] = []
	estado["pases_emitidos"] = 0
	estado["plan_activo"] = PLAN_POR_DEFECTO

	print("[global_manager] Registro vaciado por petición del lector.")
	guardar_datos()
	_recalcular()
	EventBus.pass_result.emit(true, "Registro vaciado. El archivo de guardado quedó en blanco.")


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


# --- Persistencia en disco (FileAccess + JSON) ------------------------------
# Estas dos funciones son el guardado y la carga que pide la Guía de
# Laboratorio 7 (allí llamadas save_coupons() y load_coupons()). Aquí conservan
# la nomenclatura en español del proyecto y persisten el estado completo de la
# biblioteca, no solo los pases, porque un Vertical Slice en el que los pases
# sobrevivan pero los préstamos no sería incoherente.

## Escribe el estado persistente en `SAVE_PATH` como JSON. Se invoca después de
## cada cambio del registro: préstamo nuevo, devolución y canje de un pase.
func guardar_datos() -> void:
	var datos: Dictionary = {
		"version": VERSION_GUARDADO,
		"plan_activo": str(estado["plan_activo"]),
		"prestamos": estado["prestamos"],
		"pases": estado["pases"],
		"pases_emitidos": int(estado["pases_emitidos"])
	}

	var archivo: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if archivo == null:
		push_error("[global_manager] No se pudo escribir en %s (error %d)" % [
			SAVE_PATH,
			FileAccess.get_open_error()
		])
		return

	archivo.store_string(JSON.stringify(datos, "\t"))
	# El cierre explícito importa: en la versión Web es lo que dispara el
	# volcado del sistema de archivos virtual al almacenamiento del navegador.
	archivo.close()

	print("[global_manager] Estado guardado en %s (%d préstamos, %d pases)" % [
		SAVE_PATH,
		estado["prestamos"].size(),
		estado["pases"].size()
	])


## Lee `SAVE_PATH` y restituye el estado. Si el archivo no existe, está
## corrupto o trae otra versión del esquema, se arranca con el estado inicial
## en vez de interpretar datos que no se pueden validar.
func cargar_datos() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[global_manager] Sin guardado previo: se arranca con la sala vacía.")
		return

	var archivo: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if archivo == null:
		push_error("[global_manager] No se pudo leer %s (error %d)" % [
			SAVE_PATH,
			FileAccess.get_open_error()
		])
		return

	var contenido: String = archivo.get_as_text()
	archivo.close()

	var datos: Variant = JSON.parse_string(contenido)
	if not (datos is Dictionary):
		push_warning("[global_manager] El guardado no es un objeto JSON válido; se ignora.")
		return

	var guardado: Dictionary = datos
	if int(guardado.get("version", 0)) != VERSION_GUARDADO:
		push_warning("[global_manager] Versión de guardado incompatible; se ignora el archivo.")
		return

	estado["plan_activo"] = str(guardado.get("plan_activo", PLAN_POR_DEFECTO))
	estado["prestamos"] = _sanear_prestamos(guardado.get("prestamos", {}))
	estado["pases"] = _sanear_pases(guardado.get("pases", []))
	estado["pases_emitidos"] = int(guardado.get("pases_emitidos", estado["pases"].size()))

	print("[global_manager] Estado restaurado: %d préstamos y %d pases disponibles." % [
		estado["prestamos"].size(),
		estado["pases"].size()
	])


## Descarta del guardado los préstamos que no superen la validación: ejemplares
## fuera de catálogo, plazos desconocidos o registros con forma inesperada.
## JSON no conserva tipos, así que todo lo leído se reconstruye explícitamente.
func _sanear_prestamos(crudos: Variant) -> Dictionary:
	var limpios: Dictionary = {}
	if not (crudos is Dictionary):
		return limpios

	for clave: Variant in (crudos as Dictionary).keys():
		var item_id: String = str(clave)
		var registro: Variant = (crudos as Dictionary)[clave]

		if not CATALOGO.has(item_id) or not (registro is Dictionary):
			push_warning("[global_manager] Préstamo descartado del guardado: " + item_id)
			continue

		var plan: String = str((registro as Dictionary).get("plan", ""))
		if not DURACIONES_PLAN.has(plan):
			push_warning("[global_manager] Plazo desconocido en el guardado: " + item_id)
			continue

		limpios[item_id] = {
			"plan": plan,
			"extra_dias": int((registro as Dictionary).get("extra_dias", 0))
		}

	return limpios


## Reconstruye la colección de pases descartando los elementos malformados.
func _sanear_pases(crudos: Variant) -> Array:
	var limpios: Array = []
	if not (crudos is Array):
		return limpios

	for elemento: Variant in (crudos as Array):
		if not (elemento is Dictionary):
			continue

		var pase: Dictionary = elemento
		if not pase.has("id"):
			continue

		limpios.append({
			"id": str(pase["id"]),
			"origen": str(pase.get("origen", "Devolución")),
			"dias": int(pase.get("dias", DIAS_POR_PASE))
		})

	return limpios


# --- Cálculo centralizado ---------------------------------------------------

## Suma los días comprometidos y notifica el estado al sistema completo.
func _recalcular() -> void:
	var total: int = 0
	var prestamos: Dictionary = estado["prestamos"]

	for item_id: String in prestamos.keys():
		total += dias_de(prestamos[item_id])

	estado["total_dias"] = total

	EventBus.total_changed.emit(total)
	EventBus.loans_updated.emit(obtener_resumen())
	EventBus.passes_updated.emit(estado["pases"].duplicate(true))


## Días comprometidos por un préstamo: su plazo base más lo ampliado con pases.
func dias_de(registro: Dictionary) -> int:
	return int(DURACIONES_PLAN[registro["plan"]]) + int(registro["extra_dias"])


## Construye el resumen legible de los préstamos vigentes.
## Devuelve: { item_id: { titulo, autor, plan, dias } }
func obtener_resumen() -> Dictionary:
	var resumen: Dictionary = {}
	var prestamos: Dictionary = estado["prestamos"]

	for item_id: String in prestamos.keys():
		var registro: Dictionary = prestamos[item_id]
		var plan: String = str(registro["plan"])
		var libro: Dictionary = CATALOGO[item_id]
		resumen[item_id] = {
			"titulo": libro["titulo"],
			"autor": libro["autor"],
			"plan": NOMBRES_PLAN[plan],
			"dias": dias_de(registro),
			"extra_dias": int(registro["extra_dias"])
		}

	return resumen


## Reemite el estado vigente. La invoca `MainApp` al montar un panel nuevo, de
## forma que la interfaz entrante se sincronice sin consultar a este nodo.
func emitir_estado_actual() -> void:
	EventBus.total_changed.emit(int(estado["total_dias"]))
	EventBus.loans_updated.emit(obtener_resumen())
	EventBus.passes_updated.emit(estado["pases"].duplicate(true))
	EventBus.consultation_changed.emit(str(estado["ejemplar_en_consulta"]))
	EventBus.loan_state_changed.emit(str(NOMBRES_ESTADO[_estado_prestamo]))
