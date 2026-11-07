# Hoja de ruta

Estado del documento: vigente. Revisión: 2026-11-07.

Hay un solo MVP mixto. El contrato técnico es `TECHNICAL_MODEL_APPROVAL.md` (`APPROVED`).

| Fase | Estado |
| --- | --- |
| Fase 0 | `APPROVED` |
| Modelo técnico | `APPROVED` |
| Fase 1 | `NOT AUTHORIZED` — plan en `PHASE_1_EXECUTION_PLAN.md` |

## Fase 0. Descubrimiento

Estado: `APPROVED` el 2026-11-07.

La primera redacción recomendó un mostrador inicial. Daniel indicó operación mixta. El modelo técnico resolvió las contradicciones y fue aprobado como contrato. La Fase 1 no queda autorizada por ese acto.

## Fase 1. Cimientos y esquema completo del núcleo

Estado: `NOT AUTHORIZED`. Depende de una autorización expresa de Daniel.

Incluye, cuando se autorice:

- `apps/web` y `apps/api`, TypeScript estricto.
- PostgreSQL de desarrollo.
- La primera migración con el modelo de `DATABASE_SCHEMA.md`: pedido, cuatro canales, mesa, comanda, estación, venta, pago, caja, reserva de stock y sede.
- Dinero, cantidades, errores e idempotencia, con pruebas.
- Sesión, permisos por sede y auditoría.
- Semilla local de organización, sede, roles, una caja y una estación.

La migración trae las tablas del salón y del domicilio aunque las pantallas de esos canales lleguen unos pasos más adelante. Así el núcleo no se reconstruye.

Criterio de salida: la aplicación de desarrollo levanta, la migración aplica sobre una base vacía y las pruebas de dinero e idempotencia quedan registradas con el comando realmente ejecutado.

## MVP. Construcción del comportamiento

Cada paso usa el mismo pedido.

1. Carta, insumos, kardex, recetas y compras.
2. Pedido `COUNTER`, envío a la cola única, consumo de receta y cobro en una acción coordinada.
3. Turno, pagos mixtos, propina, gasto, arqueo ciego, anulación y devolución.
4. Adición y cancelación de comanda, con reverso o merma.
5. Mesas, sesión, traslado, unión, espera de cuenta, división y cierre.
6. Cliente, `PICKUP` con hora y reserva, `DELIVERY` con dirección, tarifa, despacho y entrega.
7. Anticipos y pagos parciales sobre el mismo pedido.
8. Reportes de una sede: ventas por canal y producto, recaudos, consumo por comandas, costo de lo cobrado, gastos y diferencias.

Criterio de salida del MVP:

- Los cuatro canales crean un `Order` y ninguno escribe una venta paralela.
- Enviar la misma comanda dos veces produce un solo consumo.
- Cobrar no agrega otro consumo.
- Una mesa puede quedar servida y sin pagar, y el reporte no la cuenta como venta.
- Una división deja varias ventas y un solo historial de cocina.
- Un traslado y una unión conservan las comandas.
- Un domicilio listo en cocina no figura entregado.
- Una recogida confirmada reduce el disponible antes de enviarse a cocina.
- Dos escrituras concurrentes del mismo pedido producen un conflicto, no una mezcla.
- Dos envíos concurrentes del mismo insumo no pierden el movimiento.
- El cierre ciego guarda esperado, contado y diferencia.
- Una devolución con el turno original cerrado cae en el turno abierto y referencia el origen.
- Esas pruebas se ejecutaron contra PostgreSQL y el resultado quedó en `CHANGELOG.md`.

Cumplir esa lista deja el MVP **Probado** en desarrollo. **Listo para producción** exige, además, backup restaurado, datos reales revisados por el restaurante, usuarios reales y la decisión tributaria del contador.

## Después del MVP

En este orden, cada uno con su propia aprobación:

1. Impresión de comanda y precuenta, cuando se conozca la impresora.
2. Monitor por estaciones, usando la estación que la comanda ya guarda.
3. Segunda caja operando al mismo tiempo y reportes de varias sedes.
4. Facturación electrónica, sobre ventas ya inmutables.
5. Conectores de domicilio y pasarela.
6. Offline: cola, conflictos y la diferencia entre efectivo guardado y pago electrónico confirmado por un tercero.

## Orden que se mantiene

- La pantalla de un canal nuevo no crea otro agregado de venta.
- La factura electrónica espera a la venta inmutable.
- El KDS de varias pantallas espera a la comanda con historial.
- La sincronización offline espera a la idempotencia probada en línea.
- La segunda sede operativa espera a que la primera cierre turnos reales. El dato de sede ya está desde la Fase 1.

## Nota de auditoría del 2026-11-06

`PHASE_0_AUDIT.md` condiciona la salida de esta fase. Aprobar las ADR-001 a ADR-020 no abre la Fase 1 mientras sigan abiertos los hallazgos críticos de ese informe. Esta nota no borra el criterio anterior.

## Nota del 2026-11-07 — aprobación del modelo

El modelo técnico quedó `APPROVED`. La Fase 1 permanece `NOT AUTHORIZED`. El plan de ejecución está escrito. Los asuntos `PENDING` (impuestos, comprobante, propinas, anticipos no reclamados, número de cajas) no se inventan.
