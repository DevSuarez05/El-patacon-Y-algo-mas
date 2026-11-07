# El Patacón – Y algo más

Documento maestro del proyecto. Revisión: 2026-11-07.

La plataforma es un sistema propio de gestión gastronómica para El Patacón – Y algo más. FUDO se usa como referencia funcional pública. El código, la marca y la identidad visual de FUDO quedan fuera del producto.

## Estado del proyecto

| Dimensión | Estado |
| --- | --- |
| Fase 0 | `APPROVED` |
| Modelo técnico | `APPROVED` — `TECHNICAL_MODEL_APPROVAL.md` |
| Fase 1 | `AUTHORIZED` el 2026-11-07. Cimiento en ejecución |
| Código de aplicación | Esqueleto, esquema, dinero e identidad |
| Migraciones | 001–014 aplicadas en la base de desarrollo |
| Dependencias | Instaladas con pnpm 9.15.9 |
| Despliegue | No autorizado |
| Pruebas ejecutadas | Dinero, API y web. Ver `CHANGELOG.md` |

Leyenda: Propuesto, Aprobado, En desarrollo, Implementado, Probado, Listo para producción, `NOT AUTHORIZED`, `PENDING`.

## Decisión de producto

El restaurante opera con cuatro canales sobre un solo pedido:

| Canal | Código |
| --- | --- |
| Mostrador | `COUNTER` |
| Salón | `DINE_IN` |
| Domicilio | `DELIVERY` |
| Para recoger | `PICKUP` |

Un pedido creado no es una venta cobrada. Una comanda enviada no es un consumo ni un pago.

## Contrato aprobado

El contrato técnico obligatorio es `docs/TECHNICAL_MODEL_APPROVAL.md`. Incluye pedido, mesas, comandas, inventarios, reservas y consumo, recetas y producción, compras, ventas, pagos, anticipos, propinas, caja, auditoría, idempotencia, concurrencia y preparación multi-sede.

### Siguen `PENDING`

- Tasas y modo fiscal definitivo.
- Validez del comprobante interno.
- Reparto de propinas.
- Anticipos no reclamados.
- Cantidad real de cajas físicas.

Esas políticas no se inventan. Las funciones que dependan de ellas quedan restringidas.

### Condiciones adicionales `APPROVED`

- Tarjeta o transferencia manual ≠ confirmación bancaria sin proveedor.
- Reservas con seguimiento, antigüedad y alertas. Sin liberación automática.
- Inventario negativo solo con autorización, motivo, responsable, auditoría y visibilidad en reportes.

## Documentos de control

| Documento | Rol |
| --- | --- |
| `TECHNICAL_MODEL_APPROVAL.md` | Contrato técnico `APPROVED` |
| `PHASE_1_EXECUTION_PLAN.md` | Plan de la Fase 1, autorizado y en ejecución |
| `BUSINESS_REQUIREMENTS.md` | Requisitos y estados |
| `TECHNICAL_ARCHITECTURE.md` | Arquitectura |
| `DATABASE_SCHEMA.md` | Modelo de datos |
| `ARCHITECTURE_DECISIONS.md` | ADR con historial |
| `PAYMENT_AND_CASH_RULES.md` | Pagos y caja |
| `INVENTORY_RULES.md` | Inventario |
| `ORDER_LIFECYCLE.md` | Ciclo del pedido |
| `DEVELOPMENT_ROADMAP.md` | Hoja de ruta |
| `MODULE_STATUS.md` | Estado de módulos |
| `PHASE_0_AUDIT.md` | Auditoría |
| `CHANGELOG.md` | Historial |

## Siguiente paso

La Fase 1 está autorizada y el cimiento ya está en el repositorio. Siguen fuera el punto de venta, el cobro al público, las tasas y las políticas `PENDING`. El despliegue no está autorizado.
