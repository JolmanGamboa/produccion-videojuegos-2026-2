# Producción de Videojuegos — Sistemas Interactivos 2026-2

**Universidad Antonio Nariño** · Programa de Ingeniería de Software

## Descripción

Repositorio del proyecto integrador interactivo del semestre 2026-2. El producto
en construcción es una **Biblioteca Interactiva 2D**: un espacio navegable de
estantes temáticos donde cada libro puede abrirse para consultar su ficha
(título, autor, año y sinopsis).

Esta entrega corresponde al **Laboratorio 9: Interfaz dinámica y representación
de datos mediante Resources (Sprint 3)**. El catálogo vive en recursos editables
desde el Inspector y las pantallas que lo listan se construyen solas a partir de
él. El proyecto funciona como una experiencia
integrada de extremo a extremo: el lector consulta un ejemplar, lo saca en
préstamo con un plazo, lo devuelve para ganar un **pase de lectura** y canjea
ese pase para ampliar el plazo de otro préstamo. Todo ello **sobrevive a cerrar
y reabrir la aplicación**, porque el estado se guarda en disco.

## Requisitos

| Componente | Versión / configuración |
| --- | --- |
| Godot Engine | 4.x Standard, 64 bits (sin .NET/C#) |
| Renderizador | `Compatibility` (OpenGL 3.x / WebGL 2) |
| Lenguaje | GDScript 2.0 con tipado estático |
| Control de versiones | Git + GitHub |

## Ejecución del proyecto

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/JolmanGamboa/produccion-videojuegos-2026-2.git
   ```
2. Abrir Godot 4.x, pulsar **Import** y seleccionar el archivo `project.godot`.
3. Ejecutar con `F5`. La escena principal es `res://src/core/main_app.tscn`.

> Los singletons `EventBus` y `GlobalManager` están declarados en
> `project.godot` bajo la sección `[autoload]`, en ese orden. Pueden verificarse
> en **Proyecto → Configuración del proyecto → Globales (Autoload)**.

## Estructura del proyecto

Toda la fuente se centraliza bajo `src/` siguiendo estrictamente la convención
`snake_case`. Se aplica **co-localización**: cada escena de interfaz vive en la
misma carpeta física que su script controlador.

```
Biblioteca Interactiva 2D/ (res://)
├── addons/
│   └── gdUnit4/                       # Framework de pruebas (versionado)
├── doc/
│   ├── adr/                           # ADR-001 a ADR-005
│   ├── diagrams/                      # Diagramas en SVG, PNG y PDF
│   └── web-export.md                  # Ajustes del preset Web
├── src/
│   ├── assets/ui/                     # Tema, fondo e iconos de interfaz
│   ├── components/
│   │   └── navigation/                # Componentes reutilizables
│   │       ├── button_nav.tscn
│   │       └── button_nav.gd
│   ├── core/                          # Lógica global y orquestación
│   │   ├── event_bus.gd               # Autoload: canal único de señales
│   │   ├── global_manager.gd          # Autoload: registro de préstamos
│   │   ├── main_app.tscn              # Escena principal del proyecto
│   │   └── main_app.gd                # Orquestador, memoria e historial
│   ├── data/                          # El catálogo como recursos
│   │   ├── libro_data.gd              # Un ejemplar
│   │   ├── categoria_data.gd          # Un estante
│   │   ├── catalogo_biblioteca.gd     # La colección y sus consultas
│   │   └── catalogo.tres              # 4 estantes · 17 ejemplares
│   └── scenes/                        # Un módulo por entorno navegable
│       ├── main/                      # Vestíbulo (escena + script)
│       ├── categories/                # Estantes temáticos (escena + script)
│       ├── simulation/                # Sala de lectura (escena + script)
│       ├── receipt/                   # Comprobante (escena + script)
│       ├── loans/                     # Préstamos activos (escena + script)
│       ├── config/                    # Configuración de sala (sin script)
│       └── credits/                   # Créditos (sin script)
├── tests/                             # Suite GdUnit4 (30 casos)
│   ├── test_global_manager.gd         # Unitaria: reglas del gestor
│   ├── test_catalogo_biblioteca.gd    # Unitaria: consultas del catálogo
│   ├── test_flujo_prestamo.gd         # Integración y sistema
│   └── test_persistencia.gd           # Regresión
├── tools/
│   └── build_catalogo.gd              # Herramienta de autor del catálogo
├── ADR.md                             # Índice de decisiones
├── ADR-006.md
├── BACKLOG.md
├── CHANGELOG.md
├── DEVLOG.md
├── TEST_REPORT.md                     # Reporte de pruebas
├── USER_FEEDBACK.md
├── registro_depuracion.md             # Sesión de depuración
├── project.godot
└── README.md
```

## Arquitectura del sistema

```
        intención                      señal de estado            reacción
GUI  ──────────────▶  EventBus  ──────────────▶  GlobalManager  ─────────┐
                          │                    (único cerebro)           │
                          ▼                          total_changed       │
                       MainApp                       loans_updated       ▼
              instantiate() · queue_free()                              GUI
                   navigation_history
```

| Entorno | Escena | Función |
| --- | --- | --- |
| Vestíbulo | `main/menu_panel.tscn` | Navega con instancias de `ButtonNav`; cierra la app con `get_tree().quit()` |
| Sala de lectura | `simulation/step_1_base.tscn` | Consulta fichas de libros y registra préstamos con uno de los tres plazos |
| Préstamos activos | `loans/loans_panel.tscn` | Lista los ejemplares prestados con su plazo y permite devolverlos |
| Configuración de sala | `config/config_panel.tscn` | Parámetros del entorno; sin script controlador |
| Créditos | `credits/credits_panel.tscn` | Datos del autor; sin script controlador |

### Señales del canal global

```gdscript
signal navigation_requested(target_scene: String, discard_previous: bool)
signal base_selected(base_name: String)
signal item_added(item_id: String)
signal item_removed(item_id: String)
signal total_changed(new_total: int)
signal loans_updated(loans: Dictionary)
```

### Registro de préstamos

`GlobalManager` es el único punto del sistema que decide. La interfaz publica
intenciones y desconoce los plazos:

```gdscript
const DURACIONES_PLAN: Dictionary = { "diario": 1, "quincenal": 15, "mensual": 30 }

var estado: Dictionary = {
    "plan_activo": "diario",
    "prestamos": {},      # id de libro → plazo
    "total_dias": 0
}
```

El registro sobrevive a la destrucción de los paneles: al salir de la sala de
lectura y regresar, los préstamos siguen vigentes.

### Ciclo del ejemplar (máquina de estados)

El recorrido de un libro se gobierna con una FSM alojada en `GlobalManager`.
Toda transición pasa por `_cambiar_estado()`, que la valida contra la tabla
`TRANSICIONES`:

```
en_estante ──item_opened──▶ en_consulta ──elige plazo──▶ registrando ──┬── disponible ──▶ prestado ──▶ en_estante
     ▲                           │                                     └── ya prestado ──▶ en_consulta
     └───────item_closed─────────┘
```

Mientras el ciclo está en `registrando`, el estante y las devoluciones quedan
bloqueados y la interfaz anima el sello del préstamo con `Tween`. Diagrama
completo en [`doc/diagrams/fsm-ciclo-prestamo.png`](doc/diagrams/fsm-ciclo-prestamo.png)
y justificación en [`ADR.md`](ADR.md).

### Catálogo en recursos

Los ejemplares y los estantes son recursos de `src/data/`, no constantes dentro
del código:

| Clase | Qué modela |
| --- | --- |
| `LibroData` | Un ejemplar: id, título, autor, año, categoría, páginas, sinopsis |
| `CategoriaData` | Un estante: id, nombre, descripción, icono, color |
| `CatalogoBiblioteca` | La colección completa y sus consultas |

`catalogo.tres` reúne **4 estantes y 17 ejemplares** y lo carga `GlobalManager`
con `preload()`. La pantalla de estantes y la sala de lectura se construyen
recorriéndolo: añadir un ejemplar no obliga a tocar ninguna escena. Detalle en
[`ADR-006.md`](ADR-006.md) y diagrama en
[`doc/diagrams/catalogo-ui-dinamica.png`](doc/diagrams/catalogo-ui-dinamica.png).

### Persistencia del estado

El estado completo —plan activo, registro de préstamos y colección de pases— se
guarda en `user://save_data.json` con `FileAccess` y `JSON`:

```gdscript
const SAVE_PATH: String = "user://save_data.json"

func guardar_datos() -> void:      # tras cada cambio del registro
func cargar_datos() -> void:       # en _ready(), antes del primer cálculo
```

Lo leído no se asigna tal cual: la carga comprueba un campo `version` y
reconstruye cada préstamo y cada pase contra el catálogo y la tabla de plazos,
descartando lo que no valide. El total de días queda fuera del archivo a
propósito, porque es un valor derivado y se recalcula al cargar.

`user://` resuelve a la carpeta de datos del usuario en escritorio y a IndexedDB
en la versión Web, de modo que el mismo código persiste en ambos destinos.
Justificación completa en [`ADR.md`](ADR.md) y flujo en
[`doc/diagrams/persistencia-estado.png`](doc/diagrams/persistencia-estado.png).

### Pases de lectura

| Acción | Efecto |
| --- | --- |
| Devolver un ejemplar | Entrega un pase de lectura, guardado en disco |
| Canjear un pase | Amplía 7 días el plazo de un préstamo vigente y consume el pase |

Un pase consumido no reaparece al reabrir el proyecto: el canje reescribe el
archivo de guardado.

### Refinamiento visual

Las cinco pantallas heredan `src/assets/ui/ui_theme.tres`, registrado
como tema por defecto del proyecto (`gui/theme/custom`). El recurso define los
cuatro estados del botón, el panel de superficie, los colores de texto y las
variaciones tipográficas `TituloPantalla`, `SubtituloPantalla`,
`EtiquetaSeccion`, `TituloFicha` y `TotalDestacado`.

### Versión Web

Los ajustes del preset Web, la prueba en navegador y la publicación en itch.io
están documentados en [`doc/web-export.md`](doc/web-export.md).

### Componente reutilizable

`ButtonNav` encapsula la intención de navegación y se configura desde el
Inspector, lo que permite que Configuración y Créditos no tengan script:

```gdscript
@export_file("*.tscn") var target_scene: String = ""
@export var discard_previous: bool = false
```

### Historial y gestión de memoria

`MainApp` apila con `append()` la pantalla entrante, o desapila con `pop_back()`
cuando `discard_previous` es `true`, e imprime el estado de la pila en consola
tras cada navegación. Antes de instanciar, libera la escena previa:

```gdscript
if current_scene:
    current_scene.queue_free()
    current_scene = null
```

## Pruebas automatizadas

El proyecto trae una suite de **GdUnit4 6.2.3** en `res://tests/` con treinta
casos repartidos por nivel: unitarias sobre las reglas del gestor y las
consultas del catálogo, de integración por el `EventBus`, de sistema con
escritura y relectura del guardado, y de regresión de los defectos corregidos.

El plugin está versionado en `addons/gdUnit4` y habilitado en `project.godot`,
así que basta clonar y abrir: el dock de GdUnit aparece en el panel izquierdo y
las pruebas se lanzan con botón derecho sobre `res://tests` → *Run Tests*.

Desde la línea de comandos:

```bash
export GODOT_BIN=/ruta/a/godot          # set GODOT_BIN=... en Windows
./addons/gdUnit4/runtest.sh -a res://tests
```

El diseño de los casos, los tres niveles documentados y los defectos que la
suite encontró están en [`TEST_REPORT.md`](TEST_REPORT.md). La sesión de
depuración con puntos de ruptura está en
[`registro_depuracion.md`](registro_depuracion.md).

## Convenciones de control de versiones

Los commits siguen el estándar *Conventional Commits*:

| Prefijo | Uso |
| --- | --- |
| `init:` | Configuración inicial del repositorio |
| `config:` | Estructura de directorios y configuración del motor |
| `feat:` | Nueva funcionalidad o escena |
| `refactor:` | Reorganización sin cambio de comportamiento |
| `doc:` | Documentación (README, DEVLOG, ADR) |

Cada laboratorio se cierra con una etiqueta inmutable (`lab-1`, `lab-2-v1.0`,
`lab-4-final`, `lab-6-final`). El historial de lanzamientos se consolida en
`CHANGELOG.md`.

## Autor

- **Nombre:** Jolman Harley Gamboa Salamanca
- **Código estudiantil:** 12242525509
- **Programa:** Ingeniería de Software
