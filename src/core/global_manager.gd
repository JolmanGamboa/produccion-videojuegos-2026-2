extends Node

## ============================================================================
## GlobalManager — Registro global de préstamos (Autoload)
## ============================================================================
## Registrado como Autoload bajo el identificador exacto `GlobalManager`.
##
## Es el único cerebro del sistema: ninguna interfaz calcula plazos ni guarda
## qué libros están prestados. El registro vive aquí y sobrevive a la
## destrucción de los paneles, de modo que el lector puede salir de la sala,
## visitar los créditos y volver encontrando sus préstamos intactos.
##
## Flujo: la GUI emite intenciones en el `EventBus` → este nodo las escucha,
## actualiza el diccionario de estado, recalcula los días comprometidos y
## propaga el resultado con `total_changed` y `loans_updated`.
## ----------------------------------------------------------------------------

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

# --- Estado global de la biblioteca -----------------------------------------

## Colección única de datos lógicos. `prestamos` mapea id de libro → plazo.
var estado: Dictionary = {
	"plan_activo": PLAN_POR_DEFECTO,
	"prestamos": {},
	"total_dias": 0
}


func _ready() -> void:
	# Suscripción a las intenciones publicadas por la interfaz.
	EventBus.base_selected.connect(_on_base_selected)
	EventBus.item_added.connect(_on_item_added)
	EventBus.item_removed.connect(_on_item_removed)

	_recalcular()
	print("[global_manager] Registro de préstamos inicializado.")


# --- Suscriptores de intenciones de la GUI ----------------------------------

## Fija el plazo con el que se registrarán los siguientes préstamos.
func _on_base_selected(base_name: String) -> void:
	if not DURACIONES_PLAN.has(base_name):
		push_warning("[global_manager] Plazo desconocido: " + base_name)
		return

	estado["plan_activo"] = base_name
	print("[global_manager] Plazo activo -> %s (%d días)" % [base_name, int(DURACIONES_PLAN[base_name])])


## Registra un ejemplar en préstamo con el plazo vigente. Si el libro ya estaba
## prestado, el nuevo plazo reemplaza al anterior.
func _on_item_added(item_id: String) -> void:
	if not CATALOGO.has(item_id):
		push_warning("[global_manager] Ejemplar fuera de catálogo: " + item_id)
		return

	var prestamos: Dictionary = estado["prestamos"]
	prestamos[item_id] = estado["plan_activo"]

	print("[global_manager] Préstamo registrado: %s (%s)" % [item_id, str(estado["plan_activo"])])
	_recalcular()


## Devuelve un ejemplar y lo retira del registro.
func _on_item_removed(item_id: String) -> void:
	var prestamos: Dictionary = estado["prestamos"]
	if not prestamos.has(item_id):
		return

	prestamos.erase(item_id)
	print("[global_manager] Ejemplar devuelto: " + item_id)
	_recalcular()


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
