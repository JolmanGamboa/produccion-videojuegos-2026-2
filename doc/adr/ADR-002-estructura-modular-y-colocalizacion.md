# ADR-002 — Estructura modular por dominio y co-localización física

| Campo | Valor |
| --- | --- |
| **Estado** | Aceptada |
| **Fecha** | 2026-09-06 |
| **Autor** | Jolman Harley Gamboa Salamanca |
| **Contexto** | Producción de Videojuegos 2026-2 — Corte 1, Sprint 1 |
| **Relacionada con** | ADR-001 (Event Bus), ADR-003 (GlobalManager y ButtonNav) |

## 1. Contexto

Tras desacoplar la navegación con el Event Bus, el proyecto quedó con una
organización heredada en la que el criterio de agrupación era el **tipo de
archivo** (`scenes/` por un lado, `scripts/` por otro). Ese criterio genera tres
fricciones medibles conforme el sistema crece:

1. **Distancia de edición.** Modificar una pantalla obligaba a navegar entre dos
   subárboles distintos para tocar dos archivos que siempre cambian juntos.
2. **Ambigüedad de pertenencia.** Con varios paneles, `scripts/` se convierte en
   un depósito plano donde no se distingue qué controlador sirve a qué vista.
3. **Borrado incompleto.** Eliminar una pantalla dejaba con frecuencia su script
   huérfano, acumulando deuda técnica silenciosa.

## 2. Decisión

Se adopta la **agrupación por dominio funcional con co-localización física**:
cada escena de interfaz reside en el mismo directorio que su script controlador,
y los directorios se nombran por lo que el módulo *hace*, no por lo que
*contiene*.

```
src/
├── core/                    Lógica transversal y orquestación
├── components/navigation/   Componentes de interfaz reutilizables
└── scenes/
    ├── main/                Vestíbulo
    ├── simulation/          Sala de lectura
    ├── loans/               Préstamos activos
    ├── config/              Configuración de sala
    └── credits/             Créditos
```

Reglas derivadas:

- Un archivo solo vive en `core/` si lo consume más de un módulo.
- Los componentes reutilizables se agrupan por familia bajo `components/`, no
  por la pantalla que los usa primero.
- `snake_case` en minúsculas para todo directorio, escena, script y recurso.
- Queda prohibido conservar carpetas vacías o scripts sin escena asociada.

## 3. Alternativas consideradas

| Alternativa | Motivo del rechazo |
| --- | --- |
| Agrupación por tipo (`scenes/`, `scripts/`, `assets/`) | Es la estructura de partida; separa artefactos que siempre se editan juntos y degrada con el número de pantallas. |
| Un único directorio plano por escena en la raíz de `src/` | Elimina la jerarquía, pero mezcla en el mismo nivel lo transversal con lo específico de una pantalla. |
| Estructura por capas (`view/`, `controller/`, `model/`) | Coherente en aplicaciones de negocio, pero riñe con el modelo de escenas de Godot, donde vista y controlador forman una unidad indivisible. |

## 4. Consecuencias

**Positivas**

- Alta cohesión física: todo lo necesario para entender una pantalla cabe en una
  sola carpeta.
- Eliminar un módulo es borrar un directorio, sin residuos.
- El árbol de archivos documenta la arquitectura sin necesidad de un diagrama.
- Agregar la pantalla de préstamos costó una carpeta nueva y ninguna
  modificación en las existentes.

**Negativas y mitigaciones**

- *Duplicación potencial:* módulos distintos pueden resolver lo mismo por
  separado. Se mitiga con `components/`, donde vive lo genuinamente compartido
  (ver ADR-003).
- *Rutas más largas:* el acceso a nodos y recursos gana profundidad. Se mitiga
  centralizando las rutas de escena como constantes en el Event Bus.

## 5. Validación

- Ningún script reside fuera del directorio de su escena, salvo `core/` y
  `components/`.
- El proyecto no contiene carpetas vacías ni código huérfano.
- Renombrar un módulo afecta únicamente a las constantes del bus.
