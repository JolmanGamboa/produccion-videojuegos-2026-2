# BACKLOG — Biblioteca Interactiva 2D

Lista priorizada de funcionalidades del proyecto integrador. Se actualiza al
finalizar cada laboratorio.

| Prioridad | Tarea |
| --- | --- |
| **Alta** | [x] Navegación desacoplada entre pantallas mediante Event Bus. |
|  | [x] Persistir el estado entre sesiones con `FileAccess` y `JSON`. |
|  | [x] Mecánica de recompensa: obtener y canjear pases de lectura. |
|  | [ ] Publicar la versión Web en itch.io y registrar la URL secreta. |
|  | [x] Registro global de préstamos que sobreviva al cambio de pantalla. |
|  | [x] Modelar el ciclo del ejemplar con una Máquina de Estados. |
|  | [ ] Mover el catálogo de ejemplares a un recurso externo (`.json` o `Resource`). |
| **Media** | [x] Tema visual unificado aplicado a las cinco pantallas. |
|  | [x] Componente de navegación reutilizable (`ButtonNav`). |
|  | [x] Pantalla de préstamos activos con devolución por ejemplar. |
|  | [x] Animar el registro del préstamo y el veredicto con `Tween`. |
|  | [ ] Mostrar en la sala el estado actual del ciclo de forma permanente. |
|  | [x] Marcar en el estante qué ejemplares están prestados. |
|  | [ ] Agregar un estado `VENCIDO` cuando el plazo se cumpla. |
|  | [ ] Mostrar la fecha de vencimiento de cada préstamo, no solo los días. |
|  | [ ] Permitir elegir qué pase canjear cuando haya varios distintos. |
| **Baja** | [ ] Recuperar los estantes temáticos y generarlos por iteración sobre datos. |
|  | [ ] Sustituir los botones planos por estanterías 2D con `Sprite2D`. |
|  | [ ] Retroalimentación sonora en las transiciones del ciclo. |
|  | [ ] Migración automática del guardado al subir la versión del esquema. |
|  | [ ] Extraer la FSM a un componente reutilizable si aparece un segundo comportamiento con estados. |
