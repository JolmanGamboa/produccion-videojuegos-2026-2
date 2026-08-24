# Producción de Videojuegos — Sistemas Interactivos 2026-2

**Universidad Antonio Nariño** · Programa de Ingeniería de Software

## Descripción

Repositorio del proyecto integrador interactivo del semestre 2026-2. Esta entrega
corresponde al **Laboratorio 1: Configuración del entorno, arquitectura base e
interacción local**, y constituye la línea base sobre la cual evolucionará el
simulador durante el resto del curso.

El sistema implementa un menú de inicio y una pantalla de selección de simulación
construidos íntegramente con contenedores adaptativos, y una capa lógica en
GDScript 2.0 con tipado estático estricto y comunicación por señales.

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
3. Ejecutar con `F5`. La escena principal es `res://src/scenes/main.tscn`.

## Estructura del proyecto

Toda la fuente se centraliza bajo `src/` siguiendo estrictamente la convención
`snake_case`. La raíz de `res://` solo contiene archivos de configuración.

```
mi_proyecto_interactivo/ (res://)
├── src/
│   ├── assets/
│   │   ├── audio/           # Efectos de sonido y música
│   │   ├── textures/        # Recursos gráficos (.png, .svg)
│   │   └── ui/              # Iconos y recursos de interfaz
│   ├── components/          # Micro-escenas reutilizables
│   ├── scenes/              # Pantallas y flujos principales (.tscn)
│   │   ├── main.tscn
│   │   └── main_level_1.tscn
│   └── scripts/             # Controladores lógicos (.gd)
│       ├── main.gd
│       ├── main_level_1.gd
│       └── change_scene.gd
├── .gitignore
├── DEVLOG.md
├── project.godot
└── README.md
```

## Arquitectura de las escenas

Ambas pantallas heredan de un nodo raíz **Control** con anclas *Full Rect*, de
modo que la interfaz se reajusta a cualquier resolución sin coordenadas absolutas.

| Escena | Contenedor de layout | Elementos |
| --- | --- | --- |
| `main.tscn` | `MarginContainer` → `VBoxContainer` | `BtnSimular`, `BtnSalir` |
| `main_level_1.tscn` | `MarginContainer` → `VBoxContainer` → `GridContainer` (2 columnas) | `BtnIngrediente1`, `BtnIngrediente2`, `LblStatusLocal`, `BtnVolver` |

El nodo utilitario `SceneChanger` centraliza la navegación secuencial mediante
`get_tree().change_scene_to_file()`, evitando que las rutas de escena queden
dispersas por los controladores.

## Lógica de interacción local

- **Captura en caché con `@onready`:** las referencias a botones y etiquetas se
  resuelven una sola vez al entrar al árbol, evitando accesos a nodos nulos.
- **Operador `$` restringido:** se emplea únicamente en las declaraciones
  `@onready` de la cabecera, nunca dentro de métodos cíclicos.
- **Salida limpia:** `main.gd` conecta por código la señal `pressed` de
  `BtnSalir` a `get_tree().quit()`.
- **Reactividad parametrizada con `bind()`:** en `main_level_1.gd` ambos botones
  del `GridContainer` se conectan a un único callback cohesivo que recibe el
  nombre y el costo del ingrediente:

  ```gdscript
  btn_ingrediente_1.pressed.connect(_on_ingrediente_selected.bind("Harina", 1500))
  btn_ingrediente_2.pressed.connect(_on_ingrediente_selected.bind("Azúcar", 900))

  func _on_ingrediente_selected(nombre: String, costo: int) -> void:
      lbl_status_local.text = "Selección: %s (+$%d)" % [nombre, costo]
  ```

## Convenciones de control de versiones

Los commits siguen el estándar *Conventional Commits*:

| Prefijo | Uso |
| --- | --- |
| `init:` | Configuración inicial del repositorio |
| `config:` | Estructura de directorios y configuración del motor |
| `feat:` | Nueva funcionalidad o escena |
| `doc:` | Documentación (README, DEVLOG) |

Cada laboratorio se cierra con una etiqueta inmutable (`lab-1`, `lab-2`, …).

## Autor

- **Nombre:** Jolman Harley Gamboa Salamanca
- **Código estudiantil:** 12242525509
- **Programa:** Ingeniería de Software
