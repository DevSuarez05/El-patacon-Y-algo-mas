# Pagos, propina y caja

Estado: `APPROVED` como parte de `TECHNICAL_MODEL_APPROVAL.md`, el 2026-11-07.

La idempotencia local es `APPROVED`. La política de reparto de propina, los impuestos y la cantidad de cajas siguen `PENDING`. Un pago de tarjeta o transferencia atestiguado a mano no se presenta como confirmación bancaria sin integración con el proveedor.

## 1. Cinco cifras que no se mezclan

| Cifra | Dónde vive | Qué representa |
| --- | --- | --- |
| Productos | `Sale.productGrossMinor` | Suma de precios cotizados de las líneas, antes de descuento |
| Descuentos | `Sale.discountMinor` | Descuentos autorizados de esa venta |
| Impuestos | `SaleTax` y `Sale.taxMinor` | Desglose congelado. La tasa y si el precio ya los incluye siguen `PENDING` |
| Cargos | `Sale.chargeMinor` | Tarifa de domicilio u otro cargo sin receta |
| Venta del restaurante | `Sale.saleTotalMinor` | Productos − descuentos + impuestos según el modo configurado + cargos |
| Propina | `Payment.tipMinor` y movimiento `TIP` | Dinero custodiado. No es ingreso del restaurante |
| Pagado | Suma de `Payment.appliedMinor` más propinas | Lo que el cliente entregó neto de vuelto |

`Sale` no guarda propina. El comprobante la lee de los pagos. Así no hay dos sitios que sumen la misma propina.

Identidad de cada pago, en centavos:

`recibido = aplicado a la venta + propina + vuelto`

El billete recibido es `recibido`. El importe del pago de la cuenta es `aplicado`. Son campos distintos. El vuelto solo existe en efectivo y apunta al pago que lo originó.

## 2. Payment, Sale y CashMovement

Una venta publicada exige que la suma de `aplicado` de sus pagos `SUCCEEDED` cubra `saleTotalMinor`. La propina no cuenta para esa cobertura.

Cada pago `SUCCEEDED` escribe movimientos de solo inserción, en la misma transacción:

| Movimiento | Monto | Cuándo |
| --- | --- | --- |
| `TENDER` o `DEPOSIT` | `aplicado` o el anticipo | Entra el dinero de la venta o del anticipo |
| `TIP` | `tipMinor` | Solo si la propina es mayor que cero |
| `CHANGE` | `vuelto` | Solo efectivo, ligado al `paymentId` |

El esperado de caja suma movimientos. No suma otra vez el total de la venta ni la propina guardada en el pago. El ingreso del restaurante del reporte sale de `Sale.saleTotalMinor`, no de los pagos.

## 3. Propina y su reparto

Cada propina guarda monto, medio, pago de origen y estado de distribución.

Estados de distribución: `PENDING_DISTRIBUTION`, `DISTRIBUTED`, `ADJUSTED`.

Al registrarse queda `PENDING_DISTRIBUTION`. No se asigna mesero, turno ni casa. El responsable y el mecanismo de reparto quedan vacíos hasta que el propietario apruebe una política.

Un ajuste es otra fila: monto anterior, monto nuevo, motivo y autorizador. No edita la fila original. El movimiento de caja de la propina original permanece. El ajuste, si cambia el dinero físico, escribe un movimiento compensatorio autorizado. Si solo cambia el reparto futuro, no mueve la caja.

## 4. Arqueo

El cierre compara por medio y también muestra una diferencia consolidada. La consolidada es la suma de las diferencias. No convierte las tarjetas en efectivo.

Efectivo esperado del turno:

saldo inicial + cobros en efectivo + anticipos en efectivo + otros ingresos autorizados − vueltos − devoluciones en efectivo − gastos en efectivo − retiros.

Tarjetas esperadas: cobros y anticipos con tarjeta − devoluciones con tarjeta.

Transferencias esperadas: cobros y anticipos por transferencia − devoluciones por transferencia.

Otros medios siguen la misma forma.

El conteo ciego se captura por medio, sin recibir el esperado. Al cerrar, el servidor guarda por cada medio el esperado, el contado y la diferencia, y además la diferencia consolidada. Un turno cerrado no acepta movimientos nuevos.

## 5. Anticipos

El anticipo es un pago contra el pedido, con movimiento `DEPOSIT`. No publica una venta y no entra en `saleTotalMinor`.

Aplicarlo a una venta posterior solo crea la asignación. No escribe un segundo ingreso de caja.

Devolverlo escribe `REFUND` en el turno abierto y marca la asignación como devuelta.

El crédito a favor y la retención no tienen comportamiento activo. Existen como salidas posibles el día en que una política `APPROVED` las habilite. Hasta entonces el sistema no las ejecuta y no abre cuenta corriente.

No hay retención automática.

## 6. Idempotencia

`APPROVED`: la llave y el efecto financiero local se confirman en la misma transacción. Un timeout no significa que el pago falló.

La tabla tiene sede, operación, identificador de solicitud, hash del cuerpo, estado y referencia al resultado. La combinación sede + operación + identificador es única.

| Estado | Uso |
| --- | --- |
| `PENDING` | Solicitud registrada y todavía no enviada a un proveedor externo |
| `PROCESSING` | Llamada externa en curso, ya separada de la transacción local |
| `SUCCEEDED` | Efecto local confirmado. El reintento devuelve ese resultado |
| `FAILED` | Fracaso definitivo. No hubo movimiento de caja |
| `UNKNOWN` | Se llamó a un proveedor y se perdió la respuesta. No se sabe si cobró |

Tres casos:

| Caso | Qué se confirma | Qué no se hace |
| --- | --- | --- |
| A. Efectivo, o tarjeta y transferencia atestiguadas por el cajero | `SUCCEEDED` dentro de la transacción local, con sus movimientos | No queda `UNKNOWN`. Si se pierde la respuesta, se repite la misma llave |
| B. Pago electrónico de un proveedor | Primero queda `PENDING` o `PROCESSING`. Pasa a `SUCCEEDED` solo con la respuesta válida del proveedor | El atestado del cajero no sustituye al proveedor |
| C. Se pierde la conexión con el proveedor | El pago queda `UNKNOWN` y no entra al esperado ni al ingreso | No se crea otra llave ni se asume `FAILED` |

Mientras una llave esté `PENDING`, `PROCESSING` o `UNKNOWN`, la pantalla solo puede repetirla o consultarla.

La conciliación posterior de un pago externo busca esa llave en el proveedor. Solo entonces pasa a `SUCCEEDED`, y en esa transacción nacen los movimientos, o a `FAILED`, sin movimientos. En el MVP no hay proveedor conectado. Tarjeta y transferencia del MVP son el caso A. El caso B queda preparado y apagado.

## 7. Reglas de integridad

- `recibido = aplicado + propina + vuelto`.
- El vuelto es cero cuando el medio no es efectivo.
- La suma de lo aplicado y confirmado cubre el total de la venta y no incluye propina.
- No hay movimiento de caja para un pago que no esté `SUCCEEDED`.
- La misma llave y el mismo cuerpo devuelven el mismo pago. Otro cuerpo con la misma llave responde conflicto.
- El esperado de efectivo no suma movimientos de tarjeta ni de transferencia.
