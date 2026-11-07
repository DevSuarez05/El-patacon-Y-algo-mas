# Propuesta de Fase 2

Estado: **propuesta**. Fecha: 2026-11-07.

No autoriza implementación, migraciones ni despliegue. La Fase 1 queda cerrada con observaciones en `PHASE_1_CLOSURE_REPORT.md`. Esas observaciones se resuelven antes de escribir inventario, no dentro de un cobro ni de un POS.

## Objetivo

Poder cargar la carta, las unidades, los insumos, las recetas y las compras de una sede, con existencias consistentes, sin abrir todavía el servicio al cliente.

El pedido, la comanda, el cobro y el consumo al iniciar preparación quedan para una fase posterior. Las tablas ya existen. Esta fase no las opera.

## Alcance

Una sola sede de la sesión. Cada escritura lleva `branch_id`, permiso, auditoría cuando mueve stock o costo, y llave de idempotencia cuando el efecto no puede repetirse.

| Entrega | Entra | No entra |
| --- | --- | --- |
| 2.1 Unidades | Alta de unidades y conversiones dentro de la misma dimensión | Conversión de masa a volumen |
| 2.2 Carta | Categorías, productos, variantes, modificadores y precios de solo inserción | Combos, listas de precios e impuesto del precio |
| 2.3 Insumos | Ítems `INGREDIENT`, `PREPARATION` y `RESALE`, con saldo inicial en cero | Existencia negativa y conteo físico inventado |
| 2.4 Recetas | Versiones, líneas directas, preparaciones y la prohibición de que una preparación se contenga a sí misma | Completar un lote de producción |
| 2.5 Compras | Proveedor, orden, recepción parcial, obligación por lo recibido y costo | Abonos de caja y lotes de proveedor |
| 2.6 Ajustes | Merma y ajuste como movimientos propios, con motivo, responsable, autorizador, PIN y auditoría | Merma automática al cancelar |

La 2.5 solo empieza si se aprueba la fórmula de costo que hoy sigue propuesta. La 2.6 solo empieza si se cierra la observación del PIN y de la auditoría en la excepción.

## Orden y dependencias

```text
2.1 Unidades
  -> 2.2 Carta
  -> 2.3 Insumos
       -> 2.4 Recetas
       -> 2.5 Compras, que actualizan saldo y costo
            -> 2.6 Merma y ajuste
```

La carta no necesita insumos. La receta sí. La compra recibe un insumo que ya tiene unidad de control. La producción queda después de las recetas y antes del servicio, en una entrega propia, porque completar un lote consume componentes y entra preparación. No se mezcla con la recepción.

Antes de guardar la primera reserva, una migración nueva debe poder recordar la versión de receta en `stock_reservations`. Esta fase no crea reservas de pedido. La columna se propone ahora para no escribir después la primera reserva sin esa foto. No se escribe esa migración hasta una autorización distinta.

## Modelo que ya existe y el que falta usar

Las tablas de unidades, carta, insumos, recetas, compras, movimientos, mermas y excepciones ya están en las migraciones 003 a 013. La Fase 2 no las rehace.

Relaciones que el comportamiento debe respetar:

- La unidad y el ítem pertenecen a la sede.
- La conversión solo une unidades de la misma dimensión. El factor es positivo.
- El precio nuevo inserta otra fila. No edita la anterior.
- La receta apunta a un producto o a una preparación, no a los dos.
- La línea de receta apunta a un componente directo. Si el plato lleva hogao, apunta al hogao.
- La recepción confirma una vez por llave y crea la obligación por lo recibido.
- La orden de producción no apunta a una recepción.
- El movimiento de stock es de solo inserción. El saldo se actualiza en la misma transacción, con las filas de saldo bloqueadas por identificador de ítem.
- La merma no nace de un cambio de estado.

## Concurrencia y atomicidad

- Confirmar una recepción y sus líneas, el saldo, el costo y la obligación ocurren en una transacción. La llave ya es única por sede.
- Repetir la misma llave y el mismo cuerpo devuelve el resultado. Otro cuerpo responde conflicto.
- Dos recepciones del mismo ítem se serializan al bloquear el saldo.
- Si el disponible no alcanza para un ajuste de salida, no se escribe nada, salvo la excepción auditada.
- Un turno de caja no participa en estas entregas. El gasto de caja sigue fuera.

## Riesgos

| Riesgo | Control |
| --- | --- |
| Aplicar el promedio ponderado sin fórmula aprobada | La entrega 2.5 no empieza |
| Dejar negativa la existencia al recibir con saldo en cero | La fórmula y el camino de excepción se prueban antes |
| Olvidar la foto de receta | No se escribe una reserva de pedido en esta fase |
| Interpretar el precio como impuesto incluido | El precio guarda centavos. El modo fiscal sigue vacío |
| Convertir la recepción en un lote con vencimiento | Ese documento sigue fuera |

## Pruebas de aceptación

1. Una conversión de kilogramos a gramos conserva la cantidad. Una de kilogramos a litros se rechaza.
2. Cambiar un precio inserta otra fila. La anterior no se actualiza.
3. Una receta de preparación no puede incluir esa misma preparación.
4. La misma llave de recepción no entra la mercancía dos veces.
5. Una recepción parcial aumenta solo la cantidad recibida y la obligación por ese valor.
6. Dos recepciones concurrentes del mismo ítem no pierden unidades ni dejan el costo a medias.
7. Una merma sin motivo, responsable o autorizador no se inserta.
8. Un ajuste que dejaría saldo negativo falla si no existe la excepción con PIN verificado y auditoría.
9. Ninguna prueba crea una venta, un pago, una comanda ni un consumo de pedido.
10. La consulta sigue filtrando por la sede de la sesión.

## Decisiones que requieren aprobación

| Decisión | Estado actual |
| --- | --- |
| Adoptar esta Fase 2 y su orden | Pendiente de Daniel |
| Fórmula del promedio ponderado cuando la existencia es positiva, cero o negativa | Sigue propuesta en el esquema |
| Agregar, en una migración posterior, la versión de receta a la reserva y la constancia de PIN a la excepción | Hace falta para no contradecir el modelo. No está autorizada |
| Si el precio de carta incluye el impuesto | Pendiente del contador. La carta puede guardarse sin resolverlo |
| Si completar lotes de producción entra en esta fase o en la siguiente | Esta propuesta lo deja fuera de 2.1–2.6 |
| Existencia inicial distinta de cero | Solo mediante ajuste autorizado. Un conteo de apertura no se inventa |
| Lotes y vencimientos de proveedor | Siguen fuera |

## Excluido

- Pantallas de mostrador, salón, domicilio y recogida.
- Envío de comanda, inicio de preparación y consumo del pedido.
- Cobros, propinas, vueltos, arqueo y anticipos.
- Factura electrónica, impresoras y pasarela.
- Liberación automática de reservas.
- Crédito a favor y retención de anticipos.
- Segunda sede operativa y despliegue.

## Recomendación

La propuesta puede revisarse. **No es un GO para construir.** La implementación espera una autorización expresa y, antes de la entrega de compras, la fórmula de costo.
