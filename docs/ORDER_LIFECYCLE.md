# Ciclo del pedido

Estado: `APPROVED` como parte de `TECHNICAL_MODEL_APPROVAL.md`, el 2026-11-07. La Fase 1 sigue sin autorización.

Un pedido no es una venta. Una comanda no es un consumo. Un pago no es una propina ni un vuelto. Un anticipo no es una venta liquidada.

## 1. Documentos

| Documento | Nace | No significa |
| --- | --- | --- |
| `Order` | Al abrir mostrador, mesa, domicilio o recogida | Que esté cobrado o entregado |
| Línea | En borrador | Que reserve inventario |
| `KitchenTicket` | Al enviar cantidades a la cola | Que esas cantidades ya se consumieron o se entregaron |
| `Sale` | Al liquidar una porción cubierta por pagos confirmados | Que incluya propina o que mueva inventario |
| `Payment` | Al recibir dinero | Que el billete entero sea ingreso, ni que un timeout sea un fallo |
| `CashMovement` | Cuando el pago local queda `SUCCEEDED` | Que el pedido esté cumplido |
| Anticipo | Pago contra el pedido | Venta publicada |
| Merma | Cuando alguien registra una pérdida | Efecto de cancelar o de cambiar un estado |

## 2. Cumplimiento y liquidación

El cumplimiento recorre borrador, abierto, en preparación, listo, cumplido o cancelado.

La liquidación recorre sin pago, parcialmente pagada, pagada o anulada. Un anticipo, aunque cubra el monto, deja la liquidación en parcial hasta que una venta publicada absorba ese dinero.

`PAGADA` exige ventas publicadas que cubran las líneas activas. El anticipo solo no alcanza.

## 3. Los cuatro canales

El mostrador puede confirmar e iniciar preparación en una transacción. El salón confirma por tandas, cocina después y cobra al pedir la cuenta. El domicilio reserva al confirmar, cocina, se despacha y solo entonces puede marcarse entregado. La recogida reserva al confirmar, guarda la hora prometida y se entrega en el local.

Listo en cocina no despacha ni cierra la mesa.

## 4. Mesa

Abrir una mesa libre o reservada crea la sesión y un pedido de salón. Agregar después de enviar crea líneas en borrador y, al enviarlas, otra comanda. Dividir publica varias ventas del mismo pedido. Trasladar y unir cambian la sesión y conservan las comandas. Cerrar exige pedidos cumplidos o cancelados y saldo de venta en cero. La propina pendiente de reparto no impide el cierre de la mesa.

## 5. Transacciones que deben ser únicas

| Acción | Una transacción contiene | Llave |
| --- | --- | --- |
| Confirmar líneas | Reservas de los componentes directos, con la versión de receta | La de la confirmación |
| Enviar comanda | Comanda e historial | La del envío. No incluye consumo |
| Iniciar una cantidad | Conversión de esa reserva, movimientos y costo congelado | La del inicio |
| Confirmar e iniciar en mostrador | Reserva y conversión, un solo consumo | Una llave de la acción combinada |
| Publicar venta y pagar en local | Venta sin propina, pago `SUCCEEDED`, movimientos de aplicado, propina y vuelto, llave | La del cobro |
| Aplicar anticipo | Asignación a la venta, sin nuevo ingreso | La de la aplicación |
| Devolver | Movimiento `REFUND` en el turno abierto | La de la devolución |
| Completar producción | Consumo de componentes, merma de producción, entrada de la preparación y costo | La del lote |
| Cerrar turno | Esperado, contado y diferencia por medio, más diferencia consolidada | La del cierre |

Si la transacción no se confirma, no queda ninguna de sus partes. Si se confirma y se pierde la respuesta, la misma llave devuelve el resultado.

## 6. Lo que este ciclo no decide

El modo de impuesto, el comprobante frente al contador, la política del anticipo no recogido, el reparto de la propina y el número de cajas físicas.
