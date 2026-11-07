# Plan de ejecución de la Fase 1

Estado: **EN EJECUCIÓN**. Fecha inicial: 2026-11-07. Revisión de readiness: 2026-11-07. Autorización de Daniel: 2026-11-07.

La Fase 0 y el modelo técnico están `APPROVED`. Daniel autorizó este plan. El párrafo que lo declaraba `NOT AUTHORIZED` queda reemplazado por esta frase. El historial de la revisión de readiness, más abajo, no se borra.

El cimiento descrito en las secciones 1 a 12 está creado. No hay despliegue. No hay flujos de servicio, cobro ni consumo.

## Revisión de readiness

`PHASE_1_READINESS_REVIEW.md` contrastó este plan con el modelo aprobado. La propuesta inicial de 14 migraciones se conserva más abajo como historial. El orden vigente es el corregido: las claves que apuntan a tablas posteriores se agregan en la migración que crea el destino, no antes.

Cambios de esta revisión, sin borrar la propuesta inicial:

- La estación nace con cocina, no en la primera migración de catálogo.
- El pedido no exige la mesa hasta la migración de salón.
- El movimiento de caja no exige el pago hasta la migración de pagos.
- El gasto no exige el turno hasta que la caja existe.
- La Fase 1 crea restricciones e identidad. No implementa cobros ni consumos de servicio.
- La reversión de desarrollo es volver a crear la base. `migrate resolve` no deshace un esquema.
- Las pruebas no heredan la frase vieja de `TESTING_STRATEGY.md` que descontaba inventario al enviar la comanda.

Referencia obligatoria: `TECHNICAL_MODEL_APPROVAL.md`, `DATABASE_SCHEMA.md`, `PAYMENT_AND_CASH_RULES.md`, `INVENTORY_RULES.md`, `ORDER_LIFECYCLE.md` y las ADR vigentes.

## 1. Objetivos

1. Crear el monorepo con `apps/api` y `apps/web`, TypeScript estricto y sin `any`.
2. Levantar PostgreSQL de desarrollo con Docker Compose.
3. Aplicar el esquema del núcleo mixto en un orden de migraciones controlado.
4. Implementar el módulo compartido de dinero, cantidades, errores e idempotencia local, con pruebas.
5. Implementar organización, sede, identidad, sesión, roles por sede, PIN y auditoría.
6. Dejar una semilla local de organización, sede, roles, una caja y una estación. La cantidad real de cajas no se inventa: la semilla usa una caja de desarrollo marcada como tal.
7. Documentar OpenAPI vacío de negocio o con identidad, logs JSON y variables de entorno de ejemplo sin secretos.
8. Registrar en `CHANGELOG.md` los comandos de prueba realmente ejecutados.

Fuera de la Fase 1: pantallas de POS, mesas, cocina, cobros reales, DIAN, impresión, proveedores de pago, tasas fiscales definitivas y política de propinas o anticipos.

## 2. Estructura del repositorio

```text
/
  apps/
    api/                 NestJS
    web/                 Next.js
  packages/
    money/               Centavos y redondeo compartidos cuando el front lo necesite
  docs/                  Documentación ya existente
  docker-compose.yml     PostgreSQL de desarrollo
  package.json           Workspaces
  pnpm-workspace.yaml
  .env.example
  README.md
```

Dentro de `apps/api/src`, en este orden de aparición:

```text
shared/
organization/
identity/
catalog/          # tablas sí; comportamiento mínimo
inventory/        # tablas y saldo; sin POS
recipes/          # tablas y producción; sin cocina operativa
purchasing/       # tablas; sin UI de recepción
orders/           # tablas del núcleo
floor/
kitchen/
billing/
payments/
cash/
customers/
reporting/        # vacío o lectura de salud
```

La Fase 1 crea el esqueleto y las tablas. No construye el flujo completo de los cuatro canales.

## 3. Tecnologías y versiones propuestas

Versiones a fijar al instalar, cuando exista autorización. Hoy son propuestas, no instaladas.

| Pieza | Propuesta |
| --- | --- |
| Node.js | 22 LTS |
| pnpm | 9.x |
| TypeScript | 5.6+ en modo estricto |
| NestJS | 10.x |
| Prisma | 5.x o 6.x estable al momento de instalar |
| PostgreSQL | 16 |
| Zod | 3.x |
| Next.js | 15.x |
| React | 19.x si Next lo trae; si no, la versión que Next fije |
| Tailwind CSS | 3.4+ o 4.x según el starter elegido |
| Jest | suite de la API |
| Vitest | suite del web, si hay lógica de cliente |
| Docker Compose | PostgreSQL + volumen |

No se agregan Redis, colas, WebSockets, S3 ni pasarelas en la Fase 1.

## 4. Módulos iniciales

| Módulo | Qué se hace en la Fase 1 | Qué no se hace |
| --- | --- | --- |
| `shared` | Dinero, cantidades, errores tipados, UUID v7, idempotencia | Reglas de restaurante |
| `organization` | Organización, sede y cajas registradas | Multi-sede operativa y el número real de cajas |
| `identity` | Usuario, roles, permisos, sesión, PIN, auditoría | Recuperación de contraseña completa si no cabe |
| `catalog` | Tablas de categorías, productos, precios, modificadores | Combos ni listas de precios |
| `inventory` | Tablas, antigüedad de reserva, checks y excepción. Sin servicio de consumo | Liberación automática y flujos de cocina |
| `recipes` | Tablas de versión, líneas y producción | Completar lotes desde la UI |
| `purchasing` | Proveedores, órdenes, recepciones, obligaciones | Abonos de UI |
| `orders`, `floor`, `kitchen`, `billing`, `payments`, `cash`, `customers` | Tablas y restricciones del núcleo. La estación pertenece a `kitchen` | Flujos de servicio, cobro y consumo |
| `web` | App mínima, login si la API de sesión existe | POS |

Restricciones que el código deberá respetar desde el día uno:

- Impuestos: tablas y modo configurables. Sin tasas inventadas. Cobro al público bloqueado hasta la validación contable.
- Propina: se guarda el dinero. El reparto queda `PENDING_DISTRIBUTION` sin responsable.
- Anticipo: depósito y aplicación. Sin retención automática ni crédito a favor activo.
- Tarjeta y transferencia: `SUCCEEDED` local atestiguado. Nunca se presenta como confirmación bancaria.
- Reservas: antigüedad y alerta. Sin liberación automática.
- Negativos: solo con `StockException` auditada.

## 5. Modelo de datos que se implementa primero

Orden conceptual, alineado con las dependencias:

1. Organización y sede.
2. Identidad, roles, permisos, sesión, PIN, auditoría.
3. Unidades, conversiones, ítems de inventario, saldos.
4. Carta, precios, modificadores.
5. Recetas versionadas y producción.
6. Compras, recepciones, obligaciones, gastos.
7. Cajas, turnos, movimientos, cierre por medio.
8. Clientes y direcciones.
9. Pedidos, líneas, eventos, cumplimiento.
10. Mesas, sesiones, ocupaciones.
11. Comandas y estaciones.
12. Ventas, impuestos de venta, pagos, asignaciones, propina, vuelto.
13. Reservas, movimientos de stock, excepciones, merma.
14. Idempotencia.

Las tablas de impuestos existen. Los valores fiscales definitivos no.

## 6. Orden de migraciones vigente

No se ejecutan hasta la autorización. Cada paso solo referencia tablas ya creadas. Las claves hacia tablas posteriores se agregan en el paso que crea esas tablas.

| # | Migración | Depende de | Contenido |
| --- | --- | --- | --- |
| 001 | `init_organization` | — | Organization, Branch |
| 002 | `init_identity` | 001 | User, Role, Permission, UserRole, Session, AuthorizationPin, AuditEvent |
| 003 | `init_inventory_units` | 001 | Unit, UnitConversion, InventoryItem, StockBalance |
| 004 | `init_catalog` | 001, 003 | Category, Product, Variant, ModifierGroup, Modifier, Price. Sin estación |
| 005 | `init_recipes_production` | 003, 004 | RecipeVersion, RecipeLine, ProductionOrder, ProductionBatch y líneas |
| 006 | `init_purchasing` | 001, 002, 003 | Proveedor, orden, recepción, obligación, abono, gasto. El gasto todavía no apunta al turno |
| 007 | `init_cash` | 001, 002 | Caja, turno, movimiento, conteo, cierre y cierre por medio. El movimiento todavía no apunta al pago. Aquí se agrega la clave del gasto hacia el turno |
| 008 | `init_customers` | 001 | Customer, CustomerAddress |
| 009 | `init_orders` | 001, 002, 004, 008 | Pedido, líneas, cargos, eventos y cumplimiento. Sin clave de mesa |
| 010 | `init_floor` | 001, 002, 009 | Sala, mesa, sesión, ocupación y eventos. Agrega `order.table_session_id` |
| 011 | `init_kitchen` | 001, 004, 009 | PrepStation, comanda, líneas y eventos. Agrega `product.default_station_id` |
| 012 | `init_billing_payments` | 002, 007, 009 | Venta, impuestos, anulación, pago, asignación, propina y ajuste. Agrega `cash_movement.payment_id` |
| 013 | `init_stock_flows` | 002, 003, 005, 006, 009, 011, 012 | Reserva con fecha, movimiento, merma y excepción |
| 014 | `init_idempotency_tax_config` | 001, 002 | IdempotencyRecord y TaxConfiguration sin tasas |

Restricciones que entran en la migración dueña, no en una fase posterior:

- Dinero en centavos. `recibido = aplicado + propina + vuelto`.
- Una llave única por sede y operación.
- Como máximo un turno abierto por caja.
- Reserva activa única por porción de línea y componente, con `created_at`.
- Libros de caja, pago, merma, auditoría y precio sin actualización de negocio.
- `TaxConfiguration` existe y no se siembra con una tasa.

### Historial: orden propuesto antes de la revisión

Esa lista se sustituye por la tabla vigente. No se ejecuta.

| # | Nombre original | Problema |
| --- | --- | --- |
| 001–003 | organization, identity, inventory | Sin cambio de fondo |
| 004 | catalog con estación implícita | La estación todavía no existía |
| 005–006 | recipes, purchasing | El gasto no podía apuntar a un turno futuro |
| 007 | cash | El movimiento no podía apuntar a un pago futuro |
| 008 | customers | Sin cambio |
| 009 | orders con mesa | La sesión de mesa nacía en 010 |
| 010 | floor | Correcto después de corregir 009 |
| 011 | kitchen | Debe agregar la estación al producto |
| 012 | billing | Debe agregar el pago al movimiento de caja |
| 013–014 | stock, idempotency | Sin cambio de fondo si 011 y 012 ya existen |

## 7. Estrategia de pruebas

`docs/ACCEPTANCE_CRITERIA.md` no existe. Los criterios de esta fase son los de la sección 8.

`TESTING_STRATEGY.md` conserva invariantes del 2026-11-06 que descontaban inventario al enviar la comanda. Esas frases son historial. La Fase 1 no las implementa ni las copia. La regla vigente está en `INVENTORY_RULES.md`: la comanda no consume; consume el inicio de preparación.

En la Fase 1 se prueba el cimiento, no el servicio:

| Nivel | Qué |
| --- | --- |
| Unitarias | Centavos, redondeo y `recibido = aplicado + propina + vuelto` |
| Unitarias | Conversión de unidades y rechazo de masa contra volumen |
| Unitarias | Hash de idempotencia. Efectivo no usa `UNKNOWN`. El proveedor sí puede |
| Integración | La llave y un efecto de prueba se confirman o se revierten juntos |
| Integración | Misma llave y mismo cuerpo devuelve el resultado. Otro cuerpo responde conflicto |
| Integración | Sesión con hash, denegación sin permiso, auditoría de solo inserción |
| Integración | Aplicar 001–014 sobre una base vacía |
| Contrato | Salud de la API y login. El texto de tarjeta no dice confirmación bancaria |

No se afirman resultados sin ejecutar el comando. El resultado se anota en `CHANGELOG.md`.

Queda para cuando existan los casos de uso: consumo parcial, reserva concurrente, arqueo ciego, anulación y Playwright.

## 8. Criterios de aceptación

La Fase 1 se considera cumplida solo si:

1. `pnpm install` y el Compose de PostgreSQL quedan documentados y funcionan en la máquina de desarrollo.
2. Las migraciones 001–014 aplican sobre una base vacía.
3. TypeScript estricto compila en `api` y `web` sin `any`.
4. Las pruebas de dinero e idempotencia se ejecutaron y el comando quedó registrado.
5. Existe un administrador de semilla local, una sede, una caja de desarrollo y una estación.
6. La contraseña usa Argon2id. La sesión guarda solo el hash del token. Un usuario sin permiso recibe denegación. La consulta operativa de prueba filtra por sede.
7. El `.env.example` no contiene secretos.
8. OpenAPI o Swagger de la API responde.
9. No hay tasas fiscales inventadas ni UI que cobre al público.
10. El texto de tarjeta o transferencia no afirma confirmación bancaria.
11. La reserva tiene fecha de creación. No existe un proceso que la libere por tiempo.
12. `StockException` exige autorizador, motivo y responsable. No hay escritura de saldo negativo sin esa fila. Los libros financieros y la auditoría no tienen actualización de negocio.
13. Ningún archivo del historial de ADR fue borrado.
14. La Fase 1 sigue marcada como autorizada solo si Daniel lo dijo de forma expresa. Este plan no lo sustituye.

## 9. Riesgos técnicos

| Riesgo | Mitigación |
| --- | --- |
| El esquema es grande y la primera migración falla | Partir en 001–014 y revertir por pasos |
| Prisma y transacciones largas | La Fase 1 no implementa el cobro completo; las pruebas de idempotencia son cortas |
| Sembrar dos cajas “porque sí” | Una sola caja de desarrollo, etiquetada. El número real queda `PENDING` |
| Filtrar mal por sede | Toda consulta operativa incluye `branch_id` desde el primer repositorio |
| Confundir `UNKNOWN` con efectivo | El efectivo del MVP no usa `UNKNOWN` |
| Adelantar tasas o propinas | Feature flags y campos vacíos; sin valores de negocio inventados |
| Liberar reservas por timeout de proceso | Prohibido. Solo alerta y seguimiento |

## 10. Archivos que se crearán

Cuando exista autorización, y no antes:

- `package.json`, `pnpm-workspace.yaml`, `.gitignore`, `.env.example`, `README.md`
- `docker-compose.yml`
- `apps/api/package.json`, `tsconfig.json`, `nest-cli.json`, `prisma/schema.prisma`, migraciones, `src/main.ts`, módulos listados
- `apps/web/package.json`, `tsconfig.json`, `next.config.ts`, `src/app/...`
- `packages/money/package.json`, `src/index.ts`
- Actualización de `docs/CHANGELOG.md` y `docs/MODULE_STATUS.md` con el resultado real

No se crean esos archivos en este entregable.

## 11. Comandos de instalación y ejecución

Comandos previstos en el plan. La ejecución real y sus resultados están en `CHANGELOG.md`. En PowerShell se usó `corepack pnpm` y `Copy-Item`.

```bash
# Cuando exista autorización
corepack enable
pnpm install
docker compose up -d
cp .env.example .env
# En PowerShell: Copy-Item .env.example .env
pnpm --filter api prisma migrate deploy
pnpm --filter api prisma db seed
pnpm --filter api test
pnpm --filter api start:dev
pnpm --filter web dev
```

Los nombres exactos de scripts se fijarán al crear el `package.json`. Hasta entonces este bloque es una intención.

## 12. Plan de reversión y recuperación

En desarrollo no hay datos reales. La recuperación es repetible.

| Fallo | Acción |
| --- | --- |
| La migración N falla a la mitad | No se ejecuta N+1. Se corrige N. Si Prisma dejó el historial inconsistente, `migrate resolve` solo arregla ese registro. No deshace tablas |
| Hay que volver a una base limpia | Se elimina el volumen de desarrollo y se aplican otra vez 001–014. Eso es válido porque la semilla es de prueba |
| Un cambio de esquema ya aplicado está mal | Se crea una migración posterior que corrige. No se reescribe una migración ya aplicada |
| La semilla es incorrecta | Se vacía la base de desarrollo y se vuelve a sembrar. No se toca un entorno con datos reales: no existe |
| Fallan dinero o idempotencia | La Fase 1 no se declara cumplida. Se corrige y se vuelven a ejecutar las pruebas |
| La respuesta de un comando no llega | Se repite la misma llave. No se crea otra. El efectivo no pasa a `UNKNOWN` |
| Se escribió código sin autorización | Se detiene el trabajo. Se revierten los archivos. Se anota en `CHANGELOG.md` |

No hay despliegue que revertir. No hay copia de producción que restaurar.

## 13. Condición de arranque

Este plan se ejecuta solo después de una frase expresa de Daniel que autorice la Fase 1.

Hasta entonces:

| Ítem | Estado |
| --- | --- |
| Fase 0 | `APPROVED` |
| Modelo técnico | `APPROVED` |
| Fase 1 | `AUTHORIZED` y en ejecución |
| Código | Cimiento creado |
| Migraciones | 001–014 aplicadas en desarrollo |
| Despliegue | No autorizado |
