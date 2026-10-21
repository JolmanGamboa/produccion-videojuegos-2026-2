# BACKLOG — Biblioteca Interactiva 2D

Lista priorizada de funcionalidades del proyecto integrador. Se actualiza al
finalizar cada laboratorio. La prioridad **Alta** marca lo que falta para cerrar
la **Versión Beta**.

| Prioridad | Tarea |
| --- | --- |
| **Alta** | [x] Navegación desacoplada entre pantallas mediante Event Bus. |
|  | [x] Persistir el estado entre sesiones con `FileAccess` y `JSON`. |
|  | [x] Mecánica de recompensa: obtener y canjear pases de lectura. |
|  | [x] Publicar la versión Web en itch.io. |
|  | [ ] Reexportar a Web: lo publicado es anterior al Laboratorio 7 y no persiste. |
|  | [ ] Registrar la URL secreta en el `DEVLOG.md`. |
|  | [ ] Realizar la evaluación de usabilidad y volcarla en `USER_FEEDBACK.md`. |
|  | [ ] Aplicar las mejoras que salgan de esa evaluación. |
|  | [x] Registro global de préstamos que sobreviva al cambio de pantalla. |
|  | [x] Modelar el ciclo del ejemplar con una Máquina de Estados. |
|  | [ ] Mover el catálogo de ejemplares a un recurso externo (`.json` o `Resource`). |
| **Media** | [x] Tema visual unificado aplicado a las cinco pantallas. |
|  | [x] Centralizar el tema en `ui_theme.tres` y asignarlo a cada raíz. |
|  | [x] Contraste de todos los textos por encima de 4.5:1 (WCAG AA). |
|  | [x] Navegación completa por teclado con `focus_neighbor`. |
|  | [x] Confirmación visual al registrar un préstamo. |
|  | [x] Iconografía de apoyo en las acciones recurrentes. |
|  | [x] Fondo decorativo en el vestíbulo. |
|  | [x] Componente de navegación reutilizable (`ButtonNav`). |
|  | [x] Pantalla de préstamos activos con devolución por ejemplar. |
|  | [x] Animar el registro del préstamo y el veredicto con `Tween`. |
|  | [ ] Explicar los pases de lectura antes de que aparezca el primero. |
|  | [ ] Mostrar en la sala el estado actual del ciclo de forma permanente. |
|  | [x] Marcar en el estante qué ejemplares están prestados. |
|  | [ ] Agregar un estado `VENCIDO` cuando el plazo se cumpla. |
|  | [ ] Mostrar la fecha de vencimiento de cada préstamo, no solo los días. |
|  | [ ] Permitir elegir qué pase canjear cuando haya varios distintos. |
| **Baja** | [ ] Recuperar los estantes temáticos y generarlos por iteración sobre datos. |
|  | [ ] Sustituir los botones planos por estanterías 2D con `Sprite2D`. |
|  | [ ] Retroalimentación sonora en las transiciones del ciclo. |
|  | [ ] Fuente propia incrustada, para no depender de la del motor. |
|  | [ ] Revisar la interfaz a resoluciones menores que 1152 × 648. |
|  | [ ] Migración automática del guardado al subir la versión del esquema. |
|  | [ ] Extraer la FSM a un componente reutilizable si aparece un segundo comportamiento con estados. |
