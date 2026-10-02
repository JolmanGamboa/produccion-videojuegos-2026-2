# Producción de Videojuegos — Sistemas Interactivos 2026-2

**Universidad Antonio Nariño** · Programa de Ingeniería de Software

## Descripción

Repositorio del proyecto integrador interactivo del semestre 2026-2. El producto
en construcción es una **Biblioteca Interactiva 2D**: un espacio navegable de
estantes temáticos donde cada libro puede abrirse para consultar su ficha
(título, autor, año y sinopsis).

Esta entrega corresponde al **Laboratorio 4: Entrega integradora del Sprint 1
(Sprint Review 1)**. El sistema alcanza su madurez arquitectónica con el
registro de préstamos desasociado de la interfaz (`GlobalManager`), un
componente de navegación reutilizable (`ButtonNav`) y una pila de historial
administrada por el orquestador.

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
├── doc/
│   └── adr/
│       ├── 0001-uso-de-event-bus.md               # ADR-001
│       ├── ADR-002-estructura-modular-y-colocalizacion.md
│       └── ADR-003-global-manager-button-nav.md
├── src/
│   ├── assets/ui/                     # Iconos y recursos de interfaz
│   ├── components/
│   │   └── navigation/                # Componentes reutilizables
│   │       ├── button_nav.tscn
│   │       └── button_nav.gd
│   ├── core/                          # Lógica global y orquestación
│   │   ├── event_bus.gd               # Autoload: canal único de señales
│   │   ├── global_manager.gd          # Autoload: registro de préstamos
│   │   ├── main_app.tscn              # Escena principal del proyecto
│   │   └── main_app.gd                # Orquestador, memoria e historial
│   └── scenes/                        # Un módulo por entorno navegable
│       ├── main/                      # Vestíbulo (escena + script)
│       ├── simulation/                # Sala de lectura (escena + script)
│       ├── loans/                     # Préstamos activos (escena + script)
│       ├── config/                    # Configuración de sala (sin script)
│       └── credits/                   # Créditos (sin script)
├── CHANGELOG.md
├── DEVLOG.md
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
`lab-4-final`). El historial de lanzamientos se consolida en `CHANGELOG.md`.

## Autor

- **Nombre:** Jolman Harley Gamboa Salamanca
- **Código estudiantil:** 12242525509
- **Programa:** Ingeniería de Software
