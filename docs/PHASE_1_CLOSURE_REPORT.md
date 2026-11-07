# Cierre técnico de la Fase 1

Fecha de la auditoría: 2026-11-07.

Esta revisión leyó el código, las migraciones, la configuración y el catálogo vivo de PostgreSQL. No reejecutó la suite que inserta filas. No se escribió código, no se crearon migraciones y no se modificaron datos.

## Dictamen

**APROBADA CON OBSERVACIONES.**

El cimiento pedido para la Fase 1 está en el repositorio y en la base de desarrollo. No hay un POS, no hay cobro operativo y no hay consumo de inventario. Las observaciones no impiden cerrar esta fase. Sí impiden tratar el inventario operativo como si ya estuviera listo.

El despliegue sigue no autorizado. Este dictamen no autoriza la Fase 2.

## Evidencia comprobada

| Verificación | Evidencia |
| --- | --- |
| Monorepo | `apps/api`, `apps/web`, `packages/money`, `pnpm-workspace.yaml`, `docker-compose.yml` |
| TypeScript estricto | `strict` y `noImplicitAny` en API, web y `packages/money`. El código propio no usa `any` |
| PostgreSQL y Prisma | Compose de PostgreSQL 16. `schema.prisma` válido contra el cliente Prisma 6.19.3 |
| Catorce migraciones | El historial vivo lista 001 a 014, todas terminadas, en ese orden |
| Dinero | Montos `bigint` en centavos. `sales` no tiene columna de propina. `sales_total_check` y `payments_identity_check` existen en la base |
| Identidad | `hashSecret` usa Argon2id. `sessions` solo tiene `token_hash`. El login exige un rol en la sede pedida |
| Permisos y sede | `GET /branches/:branchId/cash-drawers` exige permiso y la sede de la sesión |
| Impuestos | `tax_configurations` tiene 0 filas y no tiene columna de tasa |
| Superficie HTTP | Solo salud, login, perfil, cajas de la sede y etiquetas de medio. No hay rutas de pedido, cobro, cocina ni inventario |
| Texto de tarjeta | La etiqueta es un registro local atestiguado por el cajero |
| Reservas | `stock_reservations.created_at` existe. No hay función de liberación |
| Negativo | `stock_balances_guard` rechaza existencia negativa sin una `stock_exceptions` completa |
| Trazabilidad | Disparadores de solo inserción en auditoría, precios, movimientos de caja, mermas, pagos sin borrado y ventas sin cambio de montos |

La consulta de solo lectura también confirmó los índices `cash_shifts_one_open`, `stock_reservations_one_active` e `idempotency_records_key`. No existen las tablas `supplier_lots` ni de crédito a favor.

## Pruebas que el repositorio contiene

No se volvieron a ejecutar en esta auditoría, porque la de API escribe en la base.

| Archivo | Qué cubre |
| --- | --- |
| `packages/money/src/identity.spec.ts` | Identidad de centavos, negativos y redondeo |
| `packages/money/src/canonical.spec.ts` | Hash estable y rechazo de `UNKNOWN` en un medio local |
| `apps/api/src/shared/quantity.spec.ts` | Conversión y rechazo de masa contra volumen |
| `apps/api/src/phase1.integration.spec.ts` | Migraciones, venta sin propina, sesión, permiso, sede, auditoría, negativo, idempotencia y OpenAPI |
| `apps/web/src/lib/session-label.spec.ts` | Texto de sesión, sin mención de un banco |

`docs/CHANGELOG.md` registra una ejecución anterior en verde. Esta auditoría confirma que esas pruebas existen y que el catálogo de la base coincide con lo que afirman. No sustituye una corrida nueva.

## Reglas de negocio

| Regla | Estado en el repositorio |
| --- | --- |
| No hay POS | La única pantalla pide correo, contraseña y sede, y dice que no hay punto de venta |
| No hay cobro operativo | No hay endpoint que cree `payments` ni `cash_movements` |
| La comanda no consume | No hay servicio de cocina. El consumo no está implementado |
| El negativo exige autorización | La base exige la fila de excepción. El código de aplicación no ofrece ese camino |
| Tarjeta y transferencia | El texto público no las presenta como confirmación bancaria |
| Tasas y políticas pendientes | No hay tasas sembradas ni reparto de propina |
| Factura electrónica | No hay agregado ni endpoint |
| Despliegue | No hay flujo de publicación |

## Problemas

No hay un defecto que obligue a rehacer la Fase 1. Estas observaciones quedan abiertas.

| Id | Severidad | Hallazgo | Riesgo si se ignora |
| --- | --- | --- | --- |
| O-01 | Media | `stock_reservations` no guarda la versión de receta. `INVENTORY_RULES.md` exige esa foto | Una reserva futura no podría demostrar qué receta congeló |
| O-02 | Media | `stock_exceptions` tiene autorizador, motivo y responsable, y no tiene constancia de PIN ni un `audit_events` obligatorio | El negativo puede existir sin el rastro completo del modelo |
| O-03 | Media | La base deja `UNKNOWN` en tarjeta y transferencia. El helper de dinero lo rechaza, pero no hay un check equivalente al del efectivo | Un escritor futuro podría guardar un estado que el cajero no debe usar sin proveedor |
| O-04 | Baja | El PIN tiene tabla y la misma función Argon2id, y no tiene alta, verificación ni prueba | El objetivo de PIN quedó como estructura, no como comportamiento |
| O-05 | Baja | La identidad del pago está en la base y en pruebas unitarias. Ninguna prueba intenta insertar un pago que la viole | Una regresión del check no la vería la suite |
| O-06 | Baja | El login valida con Zod. Un identificador de sede mal formado puede terminar en un error de Prisma | Respuesta poco clara, sin fuga de una política de negocio |
| O-07 | Baja | `docs/DEVELOPMENT_ROADMAP.md` todavía dice que la Fase 1 no está autorizada | El índice viejo contradice el estado real |
| O-08 | Baja | `.env.example` y Compose incluyen la credencial local de la base. `.env` está ignorado | No es un secreto de producción. No debe copiarse a otro entorno |

## Riesgos que siguen fuera de esta fase

- La fórmula del promedio ponderado sigue marcada como propuesta en `DATABASE_SCHEMA.md`.
- Tasas, modo incluido o excluido, comprobante, reparto de propina, anticipo no reclamado y cantidad real de cajas siguen pendientes.
- Lotes y vencimientos de proveedor siguen fuera del modelo activo.
- La suite de API acumula datos de prueba en la base de desarrollo. No es una base limpia de demostración.

## Cierre

La Fase 1 puede darse por cerrada como cimiento. La siguiente fase no empieza con este documento.
