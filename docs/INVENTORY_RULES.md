# Reglas de inventario

Estado: `APPROVED` como parte de `TECHNICAL_MODEL_APPROVAL.md`, el 2026-11-07. La liberación automática de reservas no está aprobada. El bloqueo sin disponible, la merma independiente y la producción siguen `APPROVED`.

## 1. Secuencia

El borrador no reserva.

La línea confirmada reserva sus componentes directos. Domicilio y recogida programados reservan en ese mismo momento, no en otro.

Enviar la línea a cocina registra la comanda y no consume.

Iniciar la preparación de una cantidad de esa línea consume solo esa cantidad y cierra la reserva correspondiente. El costo de los componentes queda congelado en el movimiento de consumo. La venta copia ese costo. No lo recalcula.

Cancelar antes de iniciar libera la reserva.

Cancelar después de iniciar conserva el consumo. No crea merma.

La merma es un movimiento posterior, cuando alguien identifica una pérdida real, con motivo, responsable y autorización según el tipo.

Cobrar no mueve inventario.

## 2. Unidad de la operación

La cantidad que se reserva, se consume, se libera o se cancela es la de la línea, no la del pedido ni la de la comanda entera.

Si la cocina inicia dos unidades de una línea de cinco, se consumen dos. Las otras tres siguen reservadas.

Si la comanda tiene cuatro platos y se inicia uno, los otros tres no se consumen.

En mostrador, confirmar e iniciar en la misma acción es una transacción. Contiene la reserva y su conversión. El consumo resultante es uno. La llave de esa acción impide repetirlo.

## 3. Disponible y autorización

Disponible = existencia − reservado.

No se crea una segunda reserva activa del mismo componente para la misma porción de línea.

No se consume más que lo reservado para esa porción, ni más que la existencia, salvo la excepción ya `APPROVED`: usuario, PIN, motivo, cantidad autorizada y auditoría. Sin ese registro la transacción entera no escribe nada y la existencia no queda negativa.

## 4. Casos de borde

| Caso | Resultado |
| --- | --- |
| Se inicia solo una parte de la comanda | Consumo y foto de costo solo de las cantidades iniciadas. El resto sigue reservado |
| Se preparan algunas unidades de la línea | La reserva se parte. La cantidad iniciada pasa a consumida. El sobrante sigue activo |
| La receta cambia después de reservar | La reserva guarda la versión de la receta y los componentes de ese momento. El cambio afecta las líneas nuevas, no la reserva ya hecha. El consumo usa esa foto |
| Cambia un modificador antes de preparar | En la misma transacción se libera la reserva anterior y se crea la nueva. Si no hay disponible, no queda a medias |
| Cambia un modificador que ya se consumió | No se admite otro consumo. Hay que cancelar, reintegrar o registrar merma de forma explícita |
| Se cancela parte de una línea aún no iniciada | Se libera solo esa cantidad |
| Se cancela parte ya iniciada | El consumo de esa parte permanece. La merma no aparece sola |
| La reserva no entra a cocina | Sigue bajando el disponible. Tiene seguimiento, antigüedad y alerta. No se libera sola. Solo se cancela o se inicia con una acción o una política futura aprobada |

## 5. Producción y lotes

Son documentos distintos.

| Documento | Qué es | Estado en este modelo |
| --- | --- | --- |
| Recepción de compra | Entra materia prima o preparación comprada, con su costo | Incluida. No es un lote de producción |
| Lote de proveedor y vencimiento | Trazabilidad de compra por lote | Fuera. Se incorpora después, sin mezclarlo con la producción |
| Orden de producción | Elabora hogao, salsa, guacamole, ají, carne u otra preparación | `APPROVED` como requisito |
| Existencia de la preparación | Saldo propio, por sede | `APPROVED` |
| Vencimiento de materia prima | Control por fecha | Fuera hasta una decisión nueva |

La orden de producción sigue ocho pasos:

1. Nace en borrador y no reserva.
2. Al confirmarse, valida el disponible de sus componentes directos.
3. Reserva esos componentes. Si confirmar y completar ocurren juntos, la reserva y el consumo van en una transacción.
4. Al completarse, consume los componentes una sola vez y congela su costo.
5. Registra el rendimiento real: la cantidad buena que entra al inventario de la preparación.
6. Registra la merma de producción como movimiento propio, no como merma de un pedido.
7. El costo real del lote es el costo consumido dividido entre la cantidad buena. Ese costo actualiza el promedio de la preparación.
8. Las líneas del lote conservan qué componente se usó, de qué versión de receta y con qué costo.

Completar el lote no es una compra. La venta posterior del plato descuenta la preparación, no los ingredientes ya usados en el lote.

## 6. Idempotencia de inventario

Confirmar la reserva, iniciar la preparación, liberar, publicar una recepción y completar una producción tienen llave propia. La llave se guarda en la misma transacción que el movimiento. Repetirla no reserva ni consume otra vez.
