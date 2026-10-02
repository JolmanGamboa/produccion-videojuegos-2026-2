# BACKLOG — Biblioteca Interactiva 2D

Lista priorizada de funcionalidades del proyecto integrador. Se actualiza al
finalizar cada laboratorio.

| Prioridad | Tarea |
| --- | --- |
| **Alta** | [x] Navegación desacoplada entre pantallas mediante Event Bus. |
|  | [x] Registro global de préstamos que sobreviva al cambio de pantalla. |
|  | [x] Modelar el ciclo del ejemplar con una Máquina de Estados. |
|  | [ ] Mover el catálogo de ejemplares a un recurso externo (`.json` o `Resource`). |
| **Media** | [x] Componente de navegación reutilizable (`ButtonNav`). |
|  | [x] Pantalla de préstamos activos con devolución por ejemplar. |
|  | [x] Animar el registro del préstamo y el veredicto con `Tween`. |
|  | [ ] Mostrar en la sala el estado actual del ciclo de forma permanente. |
|  | [ ] Marcar en el estante qué ejemplares están prestados. |
|  | [ ] Agregar un estado `VENCIDO` cuando el plazo se cumpla. |
| **Baja** | [ ] Recuperar los estantes temáticos y generarlos por iteración sobre datos. |
|  | [ ] Sustituir los botones planos por estanterías 2D con `Sprite2D`. |
|  | [ ] Retroalimentación sonora en las transiciones del ciclo. |
|  | [ ] Extraer la FSM a un componente reutilizable si aparece un segundo comportamiento con estados. |
