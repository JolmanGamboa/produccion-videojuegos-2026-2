# Producción de Videojuegos — Sistemas Interactivos 2026-2

**Universidad Antonio Nariño** · Programa de Ingeniería de Software

## Descripción

Repositorio del proyecto integrador interactivo del semestre 2026-2. El producto
en construcción es una **Biblioteca Interactiva 2D**: un espacio navegable de
estantes temáticos donde cada libro puede abrirse para consultar su ficha
(título, autor, año y sinopsis).

Esta entrega corresponde al **Laboratorio 2: Escenas, nodos y navegación
desacoplada (Event Bus)**. Sobre la línea base del Laboratorio 1 se realizó una
refactorización arquitectónica que sustituye la navegación por rutas absolutas
por un canal global de eventos, y reorganiza el árbol de archivos en módulos
co-localizados.

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

> El singleton `EventBus` está declarado en `project.godot` bajo la sección
> `[autoload]`. Puede verificarse en **Proyecto → Configuración del proyecto →
> Globales (Autoload)**.

## Estructura del proyecto

Toda la fuente se centraliza bajo `src/` siguiendo estrictamente la convención
`snake_case`. Se aplica **co-localización**: cada escena de interfaz vive en la
misma carpeta física que su script controlador.

```
Laboratorio 2/ (res://)
├── doc/
│   └── adr/
│       └── 0001-uso-de-event-bus.md   # Registro de decisión arquitectónica
├── src/
│   ├── assets/
│   │   └── ui/                        # Iconos y recursos de interfaz
│   ├── core/                          # Lógica global y orquestación
│   │   ├── event_bus.gd               # Autoload: Singleton + Observer
│   │   ├── main_app.tscn              # Escena principal del proyecto
│   │   └── main_app.gd                # Orquestador y gestor de memoria
│   └── scenes/                        # Un módulo por entorno navegable
│       ├── menu/
│       │   ├── menu_panel.tscn
│       │   └── menu_panel.gd
│       ├── step_1/
│       │   ├── step_1_base.tscn
│       │   └── step_1_base.gd
│       ├── config/
│       │   ├── config_panel.tscn
│       │   └── config_panel.gd
│       └── credits/
│           ├── credits_panel.tscn
│           └── credits_panel.gd
├── .gitignore
├── DEVLOG.md
├── project.godot
└── README.md
```

## Arquitectura de navegación

```
menu_panel ─┐
step_1_base ─┼─ emit ─▶  EventBus (Autoload)  ─ signal ─▶  MainApp ─▶ árbol visual
config_panel ─┤          navigation_requested                 instantiate()
credits_panel ┘          parameter_changed                     queue_free()
```

| Entorno | Escena | Función |
| --- | --- | --- |
| Vestíbulo | `menu_panel.tscn` | Navegación a los demás módulos y salida limpia con `get_tree().quit()` |
| Sala de lectura | `step_1_base.tscn` | Estante activo con tres libros; al abrir uno despliega su ficha |
| Configuración | `config_panel.tscn` | Cambia el estante temático y el tamaño de las sinopsis |
| Créditos | `credits_panel.tscn` | Datos del autor y del proyecto integrador |

Ningún panel conoce la ruta de otro panel: todos publican intenciones en el bus
y `MainApp` decide. Las rutas viven como constantes en `event_bus.gd`.

### Señales del bus global

```gdscript
signal navigation_requested(target_scene_path: String)
signal parameter_changed(param_name: String, value: Variant)
```

### Gestión de memoria

`MainApp` libera explícitamente el panel anterior antes de montar el siguiente,
evitando fugas de memoria:

```gdscript
if current_scene:
    current_scene.queue_free()
    current_scene = null
```

La suscripción a `navigation_requested` usa `CONNECT_DEFERRED` para que el panel
emisor termine de procesar su evento antes de ser destruido.

## Convenciones de control de versiones

Los commits siguen el estándar *Conventional Commits*:

| Prefijo | Uso |
| --- | --- |
| `init:` | Configuración inicial del repositorio |
| `config:` | Estructura de directorios y configuración del motor |
| `feat:` | Nueva funcionalidad o escena |
| `refactor:` | Reorganización sin cambio de comportamiento |
| `doc:` | Documentación (README, DEVLOG, ADR) |

Cada laboratorio se cierra con una etiqueta inmutable (`lab-1`, `lab-2-v1.0`, …).

## Autor

- **Nombre:** Jolman Harley Gamboa Salamanca
- **Código estudiantil:** 12242525509
- **Programa:** Ingeniería de Software
