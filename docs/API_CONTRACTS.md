# Contratos de API

Estado: **Propuesto**. Revisión: 2026-11-06, operación mixta.

No hay API publicada. Estas convenciones obligan al núcleo mixto cuando se apruebe la implementación.

## 1. Forma general

- HTTP JSON bajo `/api`.
- Rutas técnicas en inglés y textos de interfaz en español.
- Sesión obligatoria en la operación.
- Zod en cada comando.
- Toda lectura filtra por la sede de la sesión.
- Los comandos de pedido, comanda, venta y pago exigen la versión del pedido. Si no coincide, la respuesta es conflicto y no hay escritura.

## 2. Errores

```json
{
  "error": {
    "code": "ORDER_VERSION_CONFLICT",
    "message": "El pedido cambió. Recarga antes de continuar.",
    "details": []
  }
}
```

Familias: `VALIDATION`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `IDEMPOTENCY_CONFLICT`, `PRECONDITION_FAILED`, `INTERNAL`.

Códigos de dominio previstos: `ORDER_VERSION_CONFLICT`, `TABLE_NOT_AVAILABLE`, `TICKET_ALREADY_FIRED`, `SALE_ALREADY_POSTED`, `SHIFT_NOT_OPEN`, `INSUFFICIENT_AVAILABLE`, `DELIVERY_NOT_DISPATCHED`, `ORDER_NOT_SETTLED`.

HTTP 409 cubre versión, idempotencia y conflicto de estado. HTTP 422 cubre validación. El cuerpo no incluye traza ni SQL.

## 3. Idempotencia y dinero

Encabezado `Idempotency-Key` en crear pedido, enviar comanda, cancelar lo enviado, publicar venta, registrar pago, anular venta, confirmar recepción, confirmar conteo y cerrar turno.

La misma llave y el mismo cuerpo devuelven el resultado guardado. La misma llave y otro cuerpo responden `IDEMPOTENCY_CONFLICT`.

El dinero viaja como entero en centavos y moneda `COP`. La cantidad viaja como cadena decimal y unidad. El servidor recalcula el total de la venta. Si el total que envía el cliente no coincide, el cobro se rechaza.

## 4. Comandos del MVP

| Comando | Efecto | No hace |
| --- | --- | --- |
| Abrir pedido | Crea `Order` en el canal indicado | No crea venta ni consumo |
| Abrir mesa | Crea sesión, ocupación y pedido `DINE_IN` | No cobra |
| Agregar línea | Línea `DRAFT` | No modifica una comanda ya enviada |
| Enviar comanda | Comanda nueva en la cola | No consume inventario, no marca entregado ni pagado |
| Iniciar preparación | Convierte la reserva de esa cantidad en un consumo, una sola vez. Regla `PROPOSED` | No cobra ni crea merma |
| Cancelar línea enviada | Evento y reverso o merma | No borra la comanda |
| Trasladar o unir | Cambia sesión y escribe evento | No clona comandas |
| Publicar venta | Venta `POSTED` de una porción, si el pago la cubre | No descuenta inventario |
| Registrar anticipo | Pago contra el pedido y movimiento de caja | No publica venta |
| Anular venta | `SaleVoid`, devolución de dinero | No revive líneas ni borra consumos por su cuenta |
| Despachar y entregar | Avanza `Fulfillment` | Despachar no ocurre solo porque la cocina marcó listo |
| Cerrar mesa | Exige pedidos cumplidos o cancelados y saldo en cero | No cierra con saldo abierto |
| Cerrar turno | Guarda esperado, contado y diferencia | No muestra el esperado en el conteo |

Enviar comanda, publicar venta y registrar su pago pueden ir en una sola acción de mostrador. Siguen siendo tres efectos, con llaves, dentro de una transacción. Si el consumo queda aplicado y el pago no, la transacción completa se revierte.

## 5. Fuera de este contrato

Sockets de cocina, impresión, webhooks de pasarela, eventos DIAN y sincronización offline. Se escriben en el corte que los implemente.
