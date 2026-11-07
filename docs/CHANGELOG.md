# Changelog

El formato sigue una idea simple: fecha, estado del cambio y qué quedó verdadero al cierre de ese cambio. No se anuncia una capacidad como disponible si solo está propuesta.

## 2026-11-06

Estado: **Propuesto**.

- Se abrió la Fase 0 porque el directorio de trabajo no tenía código ni documentación previa.
- Se analizó el prompt maestro como único documento de alcance.
- Se consultó la información pública de FUDO en Colombia para una comparación funcional. No se usó código, cuentas ni material protegido de ese producto.
- Se escribieron los documentos de control: maestro, requisitos, arquitectura, modelo de datos, contratos, hoja de ruta, decisiones, estado de módulos, pruebas y despliegue.
- Se propuso el Corte 1 (control de costo, inventario, compras, una caja y venta de mostrador) y las decisiones ADR-001 a ADR-013.
- No se escribió código de aplicación.
- No se ejecutaron pruebas.
- No se creó base de datos ni despliegue.

Siguiente registro de esa jornada: la operación mixta sustituye el corte solo de mostrador. Esa sustitución está en la entrada siguiente. No hubo código ni pruebas.

## 2026-11-06 — revisión de operación mixta

Estado: **Propuesto**. Pendiente de aprobación formal.

- Daniel definió que el modelo operativo es mixto: mostrador, salón, domicilio y para recoger.
- Quedó sustituida la propuesta, del mismo día, de un primer corte exclusivo de mostrador. No se había escrito código sobre ella.
- El alcance del MVP pasa a ser operativo: los cuatro canales, salón, comanda de cola única, caja y reportes de una sede.
- Se documentó un solo dominio de pedidos, con `Order`, `KitchenTicket`, `Sale`, `Payment` y `CashMovement` separados.
- Se fijaron las reglas de cuenta de mesa, adición, división, traslado, unión, pago parcial, cancelación, consumo único, domicilio no despachado, recogida programada, turno de caja y concurrencia.
- El inventario queda propuesto para moverse al enviar la comanda. El cobro no descuenta. Lo programado reserva disponible.
- Se agregaron las ADR-014 a ADR-020. Las ADR-001 a ADR-013 siguen propuestas.
- Se alinearon arquitectura, modelo, hoja de ruta, estado de módulos, contratos y estrategia de pruebas.
- Sigue sin autorización para código, migraciones, dependencias, pantallas o despliegue.
- No se ejecutaron pruebas.

Siguiente registro esperado: aprobación formal del alcance y de las ADR, o los ajustes de esa revisión.

## 2026-11-06 — auditoría de la Fase 0

Estado: **Propuesto**. No autoriza la Fase 1.

- Se auditó la documentación de la operación mixta, sin modificar el texto histórico de las ADR-001 a ADR-020.
- El dictamen quedó en `PHASE_0_AUDIT.md`: el núcleo de un solo pedido se sostiene, y siete hallazgos críticos impiden programar.
- Se agregaron las ADR-021 a ADR-026 como propuestas. Ninguna quedó aprobada.
- No se escribió código, no se crearon migraciones y no se ejecutaron pruebas. Los escenarios A a K son pruebas conceptuales.

## 2026-11-07 — decisiones operativas de Daniel

Estado: mixto. Cada ficha conserva `APPROVED`, `PROPOSED` o `PENDING`.

- Quedaron `APPROVED`: bloqueo de inventario con excepción auditada, merma como movimiento propio, preparaciones y producción por lote, cola digital, y continuar el diseño del MVP mixto.
- Quedó `PROPOSED`: reservar al confirmar y consumir al iniciar la preparación. La validación técnica la considera viable con cuatro condiciones. No reemplaza todavía el texto histórico de la ADR-016.
- Quedó `PROPOSED` el comprobante interno, con validación contable `PENDING`.
- Quedaron `PENDING`: impuestos y modo del precio, política del anticipo no recogido, y cantidad de cajas.
- Se agregaron las ADR-027 a ADR-036. Las ADR-001 a ADR-026 no se reescribieron. Recibieron notas donde una decisión nueva las condiciona.
- No se escribió código, no se crearon migraciones y no se instalaron dependencias.

## 2026-11-07 — cierre de contradicciones del modelo técnico

Estado del paquete: `PROPOSED`, salvo la idempotencia local, que quedó `APPROVED`.

- La venta deja fuera la propina. El pago separa lo recibido, lo aplicado, la propina y el vuelto. El arqueo compara cada medio y guarda una diferencia consolidada.
- La llave de un pago local se confirma en la misma transacción del efecto. Un timeout no es un fallo. `UNKNOWN` queda reservado al proveedor externo.
- El anticipo no liquida la venta ni se retiene solo. El crédito a favor sigue apagado.
- Reservar, consumir por cantidad iniciada, congelar el costo y no duplicar reservas quedó escrito con los casos de borde. Sigue pendiente de aprobación.
- La orden de producción queda separada de la compra y del lote de proveedor.
- Se agregaron las ADR-037 a ADR-042 sin borrar las anteriores.
- No se escribió código ni se crearon migraciones. La Fase 1 no está autorizada.

## 2026-11-07 — aprobación formal del modelo técnico

- Fase 0: `APPROVED`.
- Modelo técnico: `APPROVED` (`TECHNICAL_MODEL_APPROVAL.md`).
- Fase 1: `NOT AUTHORIZED`.
- Quedaron `PENDING`: impuestos, comprobante, reparto de propinas, anticipos no reclamados, cantidad de cajas.
- Condiciones adicionales `APPROVED`: tarjeta manual ≠ banco; reservas con antigüedad y alertas sin liberación automática; negativos solo con auditoría visible.
- Se agregó la ADR-043. Las ADR-032, 037, 038, 040, 041 y 042 pasaron a `APPROVED` sin borrar el historial.
- Se escribió `PHASE_1_EXECUTION_PLAN.md`. No se escribió código, no se instalaron dependencias y no se ejecutaron migraciones.

## 2026-11-07 — ejecución del cimiento de la Fase 1

Daniel autorizó la Fase 1. Se creó el monorepo, se aplicaron las migraciones 001–014 y se probaron dinero, identidad e idempotencia. No se implementaron cobros, consumo ni políticas `PENDING`. No hay despliegue.

Comandos ejecutados en esta máquina, con Node v24.19.0 y pnpm 9.15.9 por Corepack:

- `corepack pnpm install` — terminó bien.
- `docker compose up -d` — PostgreSQL 16 en marcha.
- `corepack pnpm --filter money test` — 7 pruebas en verde.
- `corepack pnpm --filter api test` — las 14 migraciones aplicadas y 7 pruebas en verde.
- `corepack pnpm --filter web test` — 1 prueba en verde.
- `nest build` en `apps/api` — terminó bien.
- `GET /health` respondió `ok`. `GET /foundation/tender-labels` respondió el texto de registro local atestiguado.

La página `http://localhost:3000` mostró el acceso sin punto de venta. El envío del formulario en el navegador no se completó: la herramienta bloqueó escribir la contraseña de desarrollo. El mismo login quedó cubierto por la prueba de la API.

## 2026-11-07 — revisión de readiness de la Fase 1

- Se contrastó el plan con el modelo aprobado. `ACCEPTANCE_CRITERIA.md` no existe.
- El orden inicial de migraciones se conservó como historial y se sustituyó por uno que no crea claves hacia tablas futuras.
- La reversión dejó de tratar `migrate resolve` como un deshacer de esquema.
- La Fase 1 sigue `NOT AUTHORIZED`. No se escribió código ni se ejecutaron migraciones.
