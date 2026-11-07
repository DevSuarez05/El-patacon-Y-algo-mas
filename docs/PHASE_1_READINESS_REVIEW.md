# Revisión de readiness de la Fase 1

Estado del informe: emitido. Fecha: 2026-11-07.

La Fase 1 sigue `NOT AUTHORIZED`. No hay código, dependencias, migraciones ni despliegue.

## Dictamen

**GO de preparación. NO-GO de ejecución.**

El plan, después de las correcciones de esta revisión, puede usarse como base para que Daniel autorice la Fase 1. Este informe no es esa autorización. Empezar a construir ahora sería un NO-GO.

## Documentos contrastados

| Documento | Resultado |
| --- | --- |
| `PHASE_1_EXECUTION_PLAN.md` | Corregido. El orden inicial quedó como historial |
| `TECHNICAL_MODEL_APPROVAL.md` | Contrato `APPROVED`. El plan ya no lo contradice en consumo, propina ni cierre |
| `ARCHITECTURE_DECISIONS.md` | Historial conservado. La estación queda en cocina, como la ADR-019 |
| `DATABASE_SCHEMA.md` | El plan vigente respeta las claves y los libros de solo inserción |
| `TECHNICAL_ARCHITECTURE.md` | Monolito, dominios y sede se mantienen |
| `ACCEPTANCE_CRITERIA.md` | No existe. Los criterios de la Fase 1 están en la sección 8 del plan |
| `TESTING_STRATEGY.md` | Tenía invariantes vencidas. Quedó una nota de vigencia. El texto viejo no se borró |

## Hallazgos

| Id | Severidad | Hallazgo | Corrección |
| --- | --- | --- | --- |
| R-01 | CRÍTICO | 004 y 009 creaban claves hacia estación y mesa, que nacían después | Esas claves se agregan en 011 y 010 |
| R-02 | CRÍTICO | 007 creaba el movimiento de caja antes de que existiera el pago | La clave al pago se agrega en 012 |
| R-03 | ALTO | 006 podía atar el gasto a un turno que todavía no existía | La clave se agrega en 007 |
| R-04 | ALTO | `migrate resolve` se presentaba como reversión del esquema | En desarrollo se recrea la base. Un esquema mal aplicado se corrige con una migración nueva |
| R-05 | ALTO | El plan decía implementar reservas y movimientos y, a la vez, no construir el consumo | La Fase 1 deja tablas y restricciones. No abre casos de uso de cobro ni de consumo |
| R-06 | ALTO | `TESTING_STRATEGY.md` todavía descuenta inventario al enviar la comanda | Nota de vigencia. El plan no copia esas pruebas |
| R-07 | MEDIO | No había criterios de Argon2id, hash de sesión, filtro por sede ni libros sin actualización | Entraron en la sección 8 del plan |
| R-08 | MEDIO | La antigüedad de la reserva no era un criterio de aceptación | La reserva lleva fecha. No hay liberación automática |
| R-09 | MEDIO | `ACCEPTANCE_CRITERIA.md` no está en el repositorio | No se inventó otro documento. La sección 8 del plan es la lista de esta fase |
| R-10 | BAJO | El comando `cp` no es el de PowerShell | El plan muestra las dos formas |

No quedó una contradicción abierta con el modelo aprobado que impida preparar la Fase 1.

## Contraste pedido

### 1. Migraciones

El orden vigente es 001 organización, 002 identidad, 003 inventario, 004 carta, 005 recetas y producción, 006 compras, 007 caja, 008 clientes, 009 pedidos, 010 salón, 011 cocina, 012 ventas y pagos, 013 stock, 014 idempotencia y configuración fiscal vacía.

Cada paso solo apunta a tablas anteriores. `TaxConfiguration` no se siembra con tasas. `SupplierLot` y el crédito a favor no se crean como comportamiento.

### 2. Integridad

Entran en la migración dueña el check del pago, la llave única, un turno abierto por caja, la reserva activa única con fecha, y la prohibición de actualizar libros de caja, pago, merma, precio y auditoría.

### 3. Monorepositorio

Siguen `apps/api`, `apps/web` y `packages/money`. El paquete de dinero lo usa la API en esta fase. El web no calcula totales de cobro todavía.

### 4. Dominios

Identidad, carta, inventario, recetas, compras, pedidos, salón, cocina, ventas, pagos y caja siguen separados. `shared` no guarda reglas de restaurante. La estación pertenece a cocina. Catálogo solo recibe la clave cuando la estación ya existe.

### 5. Pruebas

La Fase 1 prueba dinero, conversión, idempotencia atómica, permiso, auditoría y la aplicación de 001–014. No promete consumo parcial ni arqueo de servicio. Esas pruebas esperan a los casos de uso.

### 6. Seguridad

Argon2id, sesión guardada como hash, denegación sin permiso y filtro por sede son criterios. Los siete roles se siembran como permisos. No se inventa una política de descuento ni de propina.

### 7. Idempotencia

La prueba de la Fase 1 confirma la llave y el efecto juntos, o no deja ninguno. El efectivo no usa `UNKNOWN`. Ese estado queda reservado al proveedor, que no se conecta ahora.

### 8. Inventario

No se implementa el consumo del servicio. El esquema sí distingue reserva, movimiento, merma y excepción. La excepción exige autorizador, motivo y responsable.

### 9. Auditoría financiera

La auditoría y los libros de dinero nacen de solo inserción. Un pago que no está confirmado no tiene movimiento. La propina no entra en el total de la venta. El cierre tiene una fila por medio.

### 10. Reversión

En desarrollo se elimina el volumen y se aplican otra vez las migraciones. No hay backup de producción que restaurar porque no hay producción. Perder la respuesta de un comando repite la misma llave.

## Recomendación

**GO** para considerar el plan listo.

**NO-GO** para escribir código, instalar dependencias o ejecutar migraciones.

La ejecución empieza solo con una autorización expresa de Daniel. Los asuntos `PENDING` — impuestos, comprobante, reparto de propina, anticipo no reclamado y número de cajas — siguen sin inventarse.
