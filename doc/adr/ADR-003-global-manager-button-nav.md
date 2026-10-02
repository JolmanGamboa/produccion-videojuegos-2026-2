# ADR-003 — Registro global de préstamos y componente de navegación reutilizable

| Campo | Valor |
| --- | --- |
| **Estado** | Aceptada |
| **Fecha** | 2026-09-10 |
| **Autor** | Jolman Harley Gamboa Salamanca |
| **Contexto** | Producción de Videojuegos 2026-2 — Sprint Review 1 (Laboratorio 4) |
| **Relacionada con** | ADR-001 (Event Bus), ADR-002 (Estructura modular) |

## 1. Contexto

Al cierre del Sprint 1 el sistema navegaba de forma desacoplada, pero arrastraba
dos deudas técnicas que impedían considerarlo maduro.

**Estado atrapado en la vista.** Los datos de la simulación vivían como
variables locales del panel que los mostraba. Como `MainApp` libera cada panel
con `queue_free()` al navegar, todo lo acumulado por el usuario se perdía al
salir de la pantalla. El estado tenía la vida útil de un nodo de interfaz, que
es exactamente lo contrario de lo que un registro de biblioteca necesita: un
préstamo debe seguir existiendo aunque el lector cierre la sala de lectura.

**Navegación repetida en cada panel.** Cada pantalla implementaba su propio
botón de regreso: un script, una captura de nodo, una conexión y un callback
idénticos salvo por la ruta destino. Cinco pantallas significaban cinco copias
del mismo comportamiento.

## 2. Decisión

### 2.1 `GlobalManager` como único registro de préstamos

Se registra `res://src/core/global_manager.gd` como Autoload bajo el
identificador `GlobalManager`. Concentra el estado de la biblioteca en un
`Dictionary` y es el único punto del sistema autorizado a modificarlo:

```gdscript
var estado: Dictionary = {
	"plan_activo": "diario",
	"prestamos": {},      # id de libro → plazo
	"total_dias": 0
}
```

Los plazos y el catálogo se definen como constantes del dominio, de modo que la
regla de negocio es explícita y está en un solo archivo:

```gdscript
const DURACIONES_PLAN: Dictionary = { "diario": 1, "quincenal": 15, "mensual": 30 }
const CATALOGO: Dictionary = { "dune": {...}, "neuromante": {...}, ... }
```

El flujo es estrictamente unidireccional:

```
GUI ──intención──▶ EventBus ──▶ GlobalManager ──total_changed / loans_updated──▶ GUI
```

La interfaz **emite intenciones, no órdenes**: la sala de lectura publica
`base_selected` e `item_added` y desconoce cuántos días implica cada plazo; el
panel de préstamos publica `item_removed` y se limita a dibujar el diccionario
que recibe. Ninguna de las dos referencia a `GlobalManager` en una sola línea.

### 2.2 `ButtonNav` como componente parametrizado

Se diseña `res://src/components/navigation/button_nav.tscn`, con nodo raíz de
tipo `Button`, que expone al Inspector:

```gdscript
@export_file("*.tscn") var target_scene: String = ""
@export var discard_previous: bool = false
```

Al presionarse emite `navigation_requested(target_scene, discard_previous)`. La
consecuencia directa es que **Configuración y Créditos ya no necesitan script**:
su navegación se configura arrastrando el componente y llenando dos campos.

### 2.3 Pila de historial en `MainApp`

`MainApp` mantiene `navigation_history: Array[String]` y la administra según la
bandera recibida: `append()` cuando la pantalla entrante se apila, `pop_back()`
cuando el usuario retrocede. El estado de la pila se imprime en consola tras
cada navegación exitosa, lo que hace el flujo auditable en tiempo de ejecución.

## 3. Alternativas consideradas

| Alternativa | Motivo del rechazo |
| --- | --- |
| Que cada panel consulte `GlobalManager` directamente | Elimina la duplicación de datos, pero reintroduce una dependencia dura entre la vista y el gestor, perdiendo lo ganado con el bus. |
| Guardar el registro en `MainApp` | El orquestador ya tiene una responsabilidad (el árbol de escenas); sumarle el estado lo convertiría en un objeto-dios. |
| Persistir en disco con `ConfigFile` o `user://` | Resuelve un problema distinto —persistencia entre ejecuciones— y añade E/S innecesaria para un estado de sesión. |
| Heredar de `Button` con `class_name` en vez de una escena instanciable | Válido para la lógica, pero se pierde la configuración visual reutilizable y el flujo de trabajo declarativo desde el Inspector. |
| Que el panel de préstamos mantenga su propia lista | Duplicaría la fuente de verdad y volvería a atar el registro a la vida útil de una pantalla. |

## 4. Consecuencias

**Positivas**

- Los préstamos sobreviven a la destrucción de los paneles: el lector puede
  registrar un libro, ir a créditos y volver encontrando el registro intacto. Es
  la demostración palpable de que estado e interfaz quedaron desasociados.
- Añadir la pantalla de préstamos no exigió tocar ni el gestor ni la sala de
  lectura: bastó con suscribirse a `loans_updated`.
- Cambiar la duración de un plazo es editar una constante.
- El historial hace explícito, y verificable en consola, un flujo que antes era
  implícito.

**Negativas y mitigaciones**

- *Dos Autoloads acoplan globalmente al sistema.* Se acepta como costo
  consciente; el orden de registro (`EventBus` antes que `GlobalManager`)
  garantiza que el canal exista cuando el gestor se suscribe.
- *Un panel entrante nace sin conocer el estado.* Se mitiga con
  `GlobalManager.emitir_estado_actual()`, invocado por `MainApp` tras montar la
  escena: la GUI se sincroniza por el mismo canal reactivo, sin consultar al
  gestor.
- *La pila puede desincronizarse* si un botón de regreso se configura con
  `discard_previous = false`. Se mitiga con la traza en consola y con la
  validación de que el historial no quede vacío antes de desapilar.

## 5. Validación

- Registrar préstamos, navegar a otra pantalla y volver: el registro y el total
  de días se conservan y se repintan solos.
- `Step1Base` y `LoansPanel` no contienen ninguna referencia a `GlobalManager`
  ni operación aritmética sobre plazos.
- Configuración y Créditos no tienen archivo `.gd` asociado y aun así navegan.
- La consola imprime la pila tras cada transición, creciendo con `append()` y
  decreciendo con `pop_back()`.
