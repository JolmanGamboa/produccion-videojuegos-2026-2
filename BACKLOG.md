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
|  | [x] Suite de pruebas automatizadas con GdUnit4 sobre las reglas del gestor. |
|  | [x] Documentar los casos de prueba por nivel en `TEST_REPORT.md`. |
|  | [x] Corregir el total descuadrado al recargar el guardado (REG-01). |
|  | [x] Validar `plan_activo` al leerlo del disco (REG-02). |
|  | [x] Evitar identificadores de pase repetidos tras vaciar el registro (REG-03). |
|  | [ ] Aplicar las mejoras que salgan de esa evaluación. |
|  | [x] Registro global de préstamos que sobreviva al cambio de pantalla. |
|  | [x] Modelar el ciclo del ejemplar con una Máquina de Estados. |
|  | [x] Mover el catálogo de ejemplares a un recurso externo (`Resource`). |
|  | [x] Ampliar el catálogo y agruparlo en estantes temáticos. |
| **Media** | [x] Pantalla de estantes y sala auto-pobladas desde el catálogo. |
|  | [x] Comprobante de préstamo con consumo de pases antes de confirmar. |
|  | [x] Tema visual unificado aplicado a las cinco pantallas. |
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
|  | [ ] Sugerir un plazo según la extensión del ejemplar, que ya se guarda. |
|  | [x] Mostrar en la sala el estado actual del ciclo de forma permanente. |
|  | [x] Sprites animados del ejemplar dirigidos por la máquina de estados. |
|  | [x] Reloj del plazo con sus cuatro estados en la pantalla de préstamos. |
|  | [x] Calendario de sala adelantable para poder observar un vencimiento. |
|  | [x] Contorno que indique qué ejemplares se pueden abrir. |
|  | [x] Señal visual durante el registro del préstamo. |
|  | [x] Latido del reloj que acelere con la urgencia del plazo. |
|  | [ ] Avisar en el vestíbulo cuando haya préstamos vencidos. |
|  | [ ] Shader de viñeta al abrir el comprobante, para enfocar la atención. |
|  | [ ] Desaturar con shader los ejemplares prestados en el estante. |
|  | [ ] Bloquear nuevos préstamos mientras haya uno vencido sin devolver. |
|  | [x] Marcar en el estante qué ejemplares están prestados. |
|  | [x] Agregar un estado `VENCIDO` cuando el plazo se cumpla. |
|  | [x] Mostrar la fecha de vencimiento de cada préstamo, no solo los días. |
|  | [ ] Permitir elegir qué pase canjear cuando haya varios distintos. |
|  | [ ] Cubrir con pruebas la interfaz, que la suite deja deliberadamente fuera. |
|  | [ ] Ejecutar la suite en un workflow de GitHub Actions en cada push. |
| **Baja** | [ ] Recuperar los estantes temáticos y generarlos por iteración sobre datos. |
|  | [ ] Sustituir los botones planos por estanterías 2D con `Sprite2D`. |
|  | [ ] Portada propia por ejemplar en vez de la misma hoja para todos. |
|  | [ ] Retroalimentación sonora en las transiciones del ciclo. |
|  | [ ] Fuente propia incrustada, para no depender de la del motor. |
|  | [ ] Revisar la interfaz a resoluciones menores que 1152 × 648. |
|  | [ ] Migración automática del guardado al subir la versión del esquema. |
|  | [ ] Extraer la FSM a un componente reutilizable si aparece un segundo comportamiento con estados. |
|  | [ ] Un `.tres` por ejemplar en vez del catálogo único, si el equipo crece. |
|  | [ ] Medir la cobertura de la suite, hoy desconocida. |
