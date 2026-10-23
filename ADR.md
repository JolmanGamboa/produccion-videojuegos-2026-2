# Registros de Decisión Arquitectónica (ADR)

Índice de las decisiones técnicas del proyecto **Biblioteca Interactiva 2D**.
Los registros anteriores se conservan íntegros; cada laboratorio agrega uno nuevo.

| ADR | Decisión | Laboratorio | Documento |
| --- | --- | --- | --- |
| 001 | Navegación desacoplada mediante un Event Bus global | Lab 2 | [doc/adr/0001-uso-de-event-bus.md](doc/adr/0001-uso-de-event-bus.md) |
| 002 | Estructura modular por dominio y co-localización física | Lab 3 | [doc/adr/ADR-002-estructura-modular-y-colocalizacion.md](doc/adr/ADR-002-estructura-modular-y-colocalizacion.md) |
| 003 | Registro global de préstamos y componente `ButtonNav` | Lab 4 | [doc/adr/ADR-003-global-manager-button-nav.md](doc/adr/ADR-003-global-manager-button-nav.md) |
| 004 | Máquina de estados finita para el ciclo del ejemplar | Lab 6 | [doc/adr/ADR-004-fsm-ciclo-ejemplar.md](doc/adr/ADR-004-fsm-ciclo-ejemplar.md) |
| 005 | Persistencia del estado en disco con FileAccess y JSON | Lab 7 | [doc/adr/ADR-005-persistencia-filesystem-json.md](doc/adr/ADR-005-persistencia-filesystem-json.md) |
| 006 | Catálogo en recursos e interfaz generada a partir de los datos | Lab 9 | [ADR-006.md](ADR-006.md) |

---

Este archivo es solo el índice. Cada decisión se redacta completa en su propio
documento, y el más reciente vive en la raíz por pedido del enunciado del
laboratorio correspondiente.
