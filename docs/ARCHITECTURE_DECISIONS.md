# Decisiones de arquitectura

Estado del conjunto: **Propuesto**. Revisión: 2026-11-06, operación mixta.

Cada decisión queda propuesta hasta la aprobación formal. Si se rechaza, se agrega una decisión nueva. La historia de este archivo no se reescribe.

La propuesta de un primer corte solo de mostrador, hecha el mismo día, queda sustituida por la ADR-014. No fue implementada.

## ADR-001. Monolito modular

- Contexto: los módulos comparten transacciones de inventario, costo y caja. El equipo y el volumen inicial son los de un restaurante, no los de una red de servicios.
- Alternativas: microservicios por dominio; un solo módulo sin límites internos.
- Decisión: una aplicación NestJS con módulos y esquema compartido. La separación física se reconsidera solo si un dominio tiene vida operativa propia.
- Consecuencia: los cruces fuertes usan la misma transacción de PostgreSQL. Hay que cuidar que `shared` no se convierta en un cajón de reglas.

## ADR-002. Pila Next.js, NestJS, PostgreSQL, Prisma y Zod

- Contexto: el prompt propone esa pila y pide evaluarla.
- Alternativas: SPA con Vite más API; Drizzle en lugar de Prisma; class-validator en lugar de Zod.
- Decisión: aceptar la pila propuesta. Zod queda como única validación de entrada. Prisma se usa con transacciones cortas.
- Consecuencia: no se agregan Redis, colas ni un segundo framework de UI en el esqueleto.

## ADR-003. Dinero en centavos enteros

- Contexto: el peso colombiano se cobra en pesos, y la facturación electrónica usa dos decimales. El punto flotante está prohibido.
- Alternativas: pesos enteros sin decimales; `numeric(19,2)` en todas las sumas.
- Decisión: `bigint` en centavos para todo importe. La interfaz muestra dos decimales. El redondeo de impuestos tiene una sola función.
- Consecuencia: los agregados de reportes suman enteros. Hay que probar el redondeo antes de cobrar de verdad.

## ADR-004. Cantidades con decimal de precisión fija

- Contexto: los insumos se compran por caja, kilo o litro y se consumen por gramo, mililitro o unidad.
- Alternativas: guardar todo en la unidad mínima como entero; usar punto flotante.
- Decisión: cantidad como decimal fijo con unidad explícita, convertida a la unidad de control del insumo antes de mover el saldo.
- Consecuencia: el tipo dinero y el tipo cantidad permanecen separados.

## ADR-005. UUID versión 7

- Contexto: el Corte 4 necesita identificadores que nazcan fuera de una secuencia central.
- Alternativas: enteros autonuméricos; UUID versión 4.
- Decisión: UUID versión 7 generado por la aplicación en documentos de negocio.
- Consecuencia: las secuencias de factura, cuando existan, son otra cosa: salen de la resolución de numeración, no del identificador interno.

## ADR-006. Costo promedio ponderado

- Contexto: el restaurante necesita el costo del plato después de cada compra. Lotes y FIFO exigen operación de bodega que todavía no está confirmada.
- Alternativas: costo estándar manual; FIFO; último costo de compra.
- Decisión: promedio ponderado recalculado al confirmar la recepción. La venta congela el costo teórico de ese momento. Lotes y vencimientos quedan para un corte posterior.
- Consecuencia: el costo es una aproximación honesta mientras los insumos no se rastreen por lote. El reporte debe llamarlo costo teórico.

## ADR-007. Libros de solo inserción

- Contexto: el prompt prohíbe borrar historial y modificar una venta cobrada en silencio.
- Alternativas: actualizar la fila y guardar una auditoría paralela opcional.
- Decisión: movimientos de stock, movimientos de caja, precios, pagos, anulaciones y auditoría se insertan. Los saldos y el estado de la venta son proyecciones transaccionales.
- Consecuencia: las correcciones son compensaciones. Las consultas de saldo leen la proyección, no recalculan todo el libro en cada petición.

## ADR-008. Una sede en el modelo, una sede en la operación

- Contexto: hoy no hay confirmación de varias sedes, y migrar después cada tabla es costoso.
- Alternativas: agregar `branch_id` el día de la segunda sede; construir consolidados multi-sede ya.
- Decisión: toda operación lleva sede desde la primera migración. La interfaz y las semillas usan una sede. Los reportes consolidados esperan al Corte 4.
- Consecuencia: las consultas deben filtrar por sede desde el primer repositorio.

## ADR-009. Idempotencia obligatoria en comandos críticos

- Contexto: un timeout no prueba que el cobro o la recepción no hayan ocurrido. Un reintento no puede repetir el descuento.
- Alternativas: confiar en el identificador de la venta generado por el cliente, sin registro de la petición.
- Decisión: tabla de idempotencia y encabezado `Idempotency-Key` en recepción, cobro, anulación, conteo y cierre.
- Consecuencia: el cliente de caja debe persistir la llave hasta recibir la respuesta.

## ADR-010. Venta y documento fiscal separados

- Contexto: la DIAN y el proveedor tecnológico confirman la factura en otro momento que el cobro. El prompt prohíbe asumir aceptación.
- Alternativas: marcar la venta como facturada al intentar el envío.
- Decisión: agregado fiscal propio, con estados borrador, enviado, aceptado y rechazado. La venta no cambia porque la factura fue rechazada.
- Consecuencia: el Corte 3 necesita un proveedor tecnológico elegido y una resolución vigente. Eso es una dependencia externa.

## ADR-011. Offline diferido, cimientos ahora

- Contexto: operar sin internet es un objetivo explícito y también la pieza más difícil. FUDO, como referencia, se ofrece en línea.
- Alternativas: construir el POS offline en el MVP; ignorar identificadores hasta un corte posterior.
- Decisión: UUID e idempotencia en el MVP. Cola, conflictos y sincronización después, cuando el servicio en línea ya haya cerrado turnos reales.
- Consecuencia: una caída de internet en el MVP detiene la operación conectada. No se debe comunicar lo contrario al personal del restaurante.

## ADR-012. Un repositorio y dos aplicaciones

- Contexto: frontend y backend evolucionan juntos. Separar repositorios antes de tiempo frena los cambios de contrato.
- Alternativas: dos repositorios; un monorepo con muchos paquetes de dominio desde el día uno.
- Decisión: un repositorio, `apps/web` y `apps/api`. Los paquetes compartidos nacen cuando haya código común real, empezando por el dinero si ambos lados calculan.
- Consecuencia: el dominio de negocio permanece en la API. El navegador no contiene la regla de descuento de inventario.

## ADR-013. Impuesto configurable

- Contexto: el tratamiento tributario de un restaurante en Colombia depende del régimen y del concepto. Fijar una tasa en código sería un dato inventado.
- Alternativas: asumir impuesto nacional al consumo del 8 %; asumir IVA del 19 %.
- Decisión: tasa y tipo tributario son datos. El contador los define antes de cobrar al público con valor legal.
- Consecuencia: el MVP puede probar el cálculo con una tasa de ensayo claramente marcada como dato de prueba. El comprobante interno no es una factura DIAN.

## ADR-014. Operación mixta sobre un solo pedido

- Contexto: Daniel definió que El Patacón opera mostrador, salón, domicilio y recogida. Un núcleo solo de mostrador obligaría a reconstruir las ventas al llegar las mesas.
- Alternativas: cuatro módulos de venta; mostrador primero y canales nuevos después, con otro modelo.
- Decisión: un agregado `Order` con canal `COUNTER`, `DINE_IN`, `DELIVERY` o `PICKUP`. Las diferencias viven en políticas del mismo módulo.
- Consecuencia: el primer esquema, cuando se apruebe, incluye mesas, cumplimiento y comanda. El comportamiento se puede construir por partes, sin otro modelo de ventas.
- Sustituye: la recomendación de alcance “Corte 1 solo mostrador” del 2026-11-06.

## ADR-015. Pedido, comanda, venta, pago y movimiento de caja separados

- Contexto: un pedido vive antes del cobro. Una comanda vive antes de la entrega. Un anticipo vive antes de la venta.
- Alternativas: una sola entidad que sea pedido, cuenta, comanda y factura; crear la venta al abrir la mesa.
- Decisión: cinco documentos. `Order` opera. `KitchenTicket` comunica a cocina. `Sale` congela lo cobrado. `Payment` registra el dinero. `CashMovement` lo lleva al turno.
- Consecuencia: crear un pedido no publica una venta. Enviar una comanda no marca el pedido entregado ni pagado. Anular una venta no borra la comanda.

## ADR-016. El inventario se mueve al enviar la comanda

- Contexto: si el descuento ocurre al crear el pedido, se consumen platos que quizá no se envíen. Si ocurre al cobrar, la cocina puede preparar sin kardex y un reintento de pago puede descontar dos veces.
- Alternativas: descontar al crear la línea; descontar al publicar la venta; descontar al marcar entregado.
- Decisión: el único consumo de una receta lo inserta el envío de comanda, con su llave. El cobro no consume. Un pedido de domicilio o de recogida todavía no enviado reserva disponible. La reserva se convierte en un movimiento al enviar, o se libera al cancelar antes del envío. Cancelar después del envío escribe un reverso o una merma, una sola vez.
- Consecuencia: el consumo teórico del día puede superar el costo de las ventas cobradas. Los reportes muestran ambas cifras.
- Nota del 2026-11-07: esta ficha no se reescribe. Daniel propuso reservar al confirmar y consumir al iniciar la preparación. Esa propuesta es la ADR-032 y sigue `PROPOSED`. Hasta aprobarla, la ADR-016 no queda ni vigente ni anulada: queda en espera.

## ADR-017. Varias ventas por pedido

- Contexto: una mesa se divide por plato, por comensal o en partes iguales, y puede quedar parcialmente pagada. Un domicilio puede tener anticipo.
- Alternativas: clonar el pedido por cada cuenta; editar la misma venta hasta el cierre.
- Decisión: cada porción liquidada es una `Sale` publicada e inmutable. El residuo de centavos de una división en partes iguales queda en la última parte. El anticipo es un pago contra el pedido y luego se asigna a una venta.
- Consecuencia: la división no copia comandas. Una venta publicada no vuelve a borrador.

## ADR-018. Concurrencia de pedido y de saldo

- Contexto: dos meseros pueden adicionar la misma mesa. Dos pedidos pueden gastar el mismo insumo.
- Alternativas: último escritor gana; bloquear toda la sede al vender.
- Decisión: el pedido usa bloqueo de fila y versión. El saldo se bloquea por insumo, en orden fijo de identificador, dentro de la transacción de reserva o de envío. La llave de idempotencia cubre envío, venta, pago, anulación, recepción, conteo y cierre.
- Consecuencia: un conflicto obliga a recargar el pedido. No hay mezcla automática de ediciones.

## ADR-019. Una cola de cocina y estaciones en el modelo

- Contexto: el MVP necesita comandas, adiciones, cancelaciones y estados. El monitor por estaciones llega después.
- Alternativas: no guardar estación; construir el KDS completo en el MVP; imprimir como único canal.
- Decisión: existe `PrepStation` y cada comanda guarda estación. El producto puede sugerir una estación. La operación inicial siembra una estación y muestra una cola. La impresión queda fuera hasta conocer el equipo.
- Consecuencia: activar bar y cocina más adelante no cambia la identidad de la comanda.
- Nota del 2026-11-07: la cola digital del MVP quedó `APPROVED` en la ADR-031. La impresora sigue fuera de la construcción.

## ADR-020. Todo peso entra por un turno abierto

- Contexto: los pagos de los cuatro canales tienen que cuadrar en el arqueo. Un turno ya cerrado no puede reescribirse.
- Alternativas: pagos de domicilio fuera de caja; corregir el cierre editando sus líneas.
- Decisión: pago, anticipo, propina, gasto y devolución exigen turno abierto y escriben movimientos inmutables. La propina va en movimiento propio. Tarjeta y transferencia quedan registradas por el cajero con referencia; eso no es una aprobación del banco. Si el turno original ya está cerrado, la devolución entra al turno abierto actual y referencia el movimiento original.
- Consecuencia: sin turno abierto no se cobra. El arqueo ciego compara el esperado calculado en el servidor contra el conteo.

## Propuestas de la auditoría del 2026-11-06

Estas fichas nacen de `PHASE_0_AUDIT.md`. Estado: **Propuesto**. No sustituyen ni reescriben las ADR-001 a ADR-020. No están aprobadas.

## ADR-021. La llave de idempotencia se confirma con el efecto

- Contexto: la ADR-009 deja fuera el envío de comanda y el contrato lo incluye. Un timeout seguido de una llave nueva puede cobrar dos veces.
- Alternativas: escribir la llave después de confirmar el negocio; permitir un cobro nuevo mientras el anterior está en duda.
- Decisión propuesta: el registro de la llave, el hash canónico del cuerpo y el efecto se insertan en la misma transacción. La lista queda en crear pedido, enviar comanda, cancelar lo enviado, publicar venta, registrar pago, anular, confirmar recepción, confirmar conteo y cerrar turno. El hash no incluye la hora del cliente. Mientras una llave no tenga respuesta, la pantalla solo puede repetirla o consultarla.
- Consecuencia: el escenario de timeout queda definido. Hace falta un comando de consulta por llave.
- Riesgo: una llave abandonada bloquea ese cobro hasta que alguien la resuelva.

## ADR-022. Foto de costo de la receta. `APPROVED`

- Contexto: la ADR-006 dice que la venta congela el costo. La arquitectura lo congelaba en el envío. No había versión de receta.
- Alternativas: recostear al cobrar; guardar solo el número, sin explosión.
- Decisión original propuesta: al enviar se guarda la versión de la receta, la explosión y el costo.
- Revisión formal del 2026-11-07: el momento aprobado es el consumo al iniciar la preparación, no el envío de la comanda. La venta copia esa foto. Cada guardado de receta crea una versión. El promedio de la ADR-006 se mantiene.
- Consecuencia: una compra posterior no cambia el costo de un plato ya consumido.
- Historial: el título original hablaba del envío. No se borra esa redacción; la regla vigente es la revisión.

## ADR-023. Se cobra el precio cotizado en la línea

- Contexto: el contrato recalcula el cobro contra el precio vigente de la carta. Una cuenta de mesa puede cambiar sola.
- Alternativas: usar siempre el precio del momento del pago; pedir confirmación en cada diferencia.
- Decisión propuesta: la línea guarda el precio al agregarse. La venta usa ese precio. Un cambio de carta inserta otro precio vigente y solo afecta líneas nuevas. El historial de precios vuelve a quedar escrito en el esquema. Si el precio incluye impuesto es una configuración que el propietario y el contador deben elegir; esta ficha no elige el valor.
- Consecuencia: el total rechazado por el servidor significa que la cuenta en pantalla está vieja, no que la carta cambió por debajo.
- Riesgo: un precio mal cotizado permanece hasta quitar la línea o autorizar un descuento.

## ADR-024. El arqueo cuadra por medio y el vuelto sale de caja

- Contexto: el conteo es por medio y el cierre guarda una sola diferencia. La propina figura dentro del total de la venta y también como movimiento aparte. Un billete mayor que la cuenta no tiene salida.
- Alternativas: un solo neto de efectivo; tratar la propina como otra línea de comida.
- Decisión propuesta: el total de la venta reúne alimentos, descuentos, impuestos y cargos. La propina no entra en ese total. Cada pago puede declarar propina y esa propina genera su movimiento. El efectivo recibido de más genera un movimiento de vuelto. El cierre guarda esperado, contado y diferencia por medio. El esperado de efectivo no suma tarjetas ni transferencias.
- Consecuencia: la ADR-020 queda operable. El esquema de `Sale` y de `ShiftClose` debe alinearse antes de migrar.
- Riesgo: el cajero tiene que registrar el billete recibido y el vuelto, no solo el neto.

## ADR-025. Anular, devolver y compensar inventario son efectos distintos

- Contexto: anular una venta, devolver dinero y reponer insumos pueden ocurrir por separado. El umbral de merma no tiene estado dueño.
- Alternativas: que toda anulación devuelva inventario; que toda cancelación sea merma.
- Decisión propuesta: anular una venta y devolver su dinero ocurren en la misma transacción. Esa anulación no mueve inventario. El inventario solo cambia por una comanda de cancelación. En cola, el compensatorio es un reverso. Desde “en preparación”, el compensatorio es merma, salvo que un supervisor elija reverso. Anular una venta de un pedido dividido no anula las otras ventas.
- Consecuencia: un plato ya servido puede devolverse en dinero y permanecer consumido.
- Nota del 2026-11-07: la frase que convierte en merma lo que pasa a preparación queda reemplazada por la ADR-028, que está `APPROVED`. Siguen en propuesta la anulación junto con la devolución y la separación entre anular la venta y mover el inventario.

## ADR-026. Reserva, bloqueos, cumplimiento y anticipo

- Contexto: la reserva no dice qué pasa con una línea agregada después. Dos máquinas de estado pueden divergir. Un anticipo total no es una venta. El orden de bloqueos no es global.
- Alternativas: reservar solo la primera confirmación; llamar `PAID` a todo anticipo que cubra el total; bloquear la sede entera.
- Decisión propuesta: en domicilio y recogida, toda línea no enviada reserva disponible, también si se agrega después. Mostrador y salón consumen al enviar, sin reserva previa. Toda transacción que toque pedido y saldo bloquea primero el pedido y después los saldos, en orden de insumo. El pedido y `Fulfillment` se actualizan en la misma transacción. `PAID` exige ventas publicadas que cubran las líneas activas. Un anticipo, aunque cubra el monto, sigue siendo anticipo hasta asignarse a una venta. Conservar el anticipo de un no-show exige un tipo de movimiento que esta ficha no elige: lo elige la política del propietario.
- Consecuencia: los escenarios D, J y K tienen un lugar en el modelo. El no-show deja de poder quedar abierto en silencio solo cuando exista ese movimiento.
- Riesgo: una reserva larga de una recogida reduce el disponible del salón.
- Nota del 2026-11-07: el tramo que hacía consumir al mostrador y al salón en el envío queda en espera por la ADR-032. El bloqueo sin disponible quedó `APPROVED` en la ADR-027. La política de retener el anticipo sigue `PENDING` en la ADR-035.

## Decisiones de Daniel del 2026-11-07

No reescriben las fichas anteriores. El estado va en el título.

## ADR-027. Bloqueo de inventario insuficiente. `APPROVED`

- Contexto: Daniel cerró la pregunta del stock negativo el 2026-11-07.
- Decisión: por defecto, reservar o consumir falla entero si el disponible no alcanza. La excepción exige usuario autorizado, PIN, motivo obligatorio, cantidad autorizada y auditoría. Sin ese registro no hay existencia negativa.
- Justificación: un faltante silencioso esconde pérdidas.
- Riesgo: una excepción mal autorizada deja el kardex en negativo a propósito. Debe verse en el reporte.
- Alternativa rechazada por el propietario: permitir negativo como comportamiento normal.
- Impacto: el escenario de dos pedidos sobre el último disponible tiene un solo resultado, salvo excepción.

## ADR-028. La merma es un movimiento propio. `APPROVED`

- Contexto: Daniel rechazó que cambiar el estado del pedido cree una merma.
- Decisión: la merma registra desperdicio de ingrediente, desperdicio de preparación, pérdida durante la preparación o producto dañado. Lleva motivo, responsable y autorización según el tipo. No nace de una cancelación ni de pasar a “en preparación”.
- Justificación: la pérdida se registra cuando alguien la identifica.
- Riesgo: si nadie registra la merma, el consumo queda y la pérdida física no tiene nombre. El reporte debe mostrar consumo sin merma asociada.
- Alternativa no aceptada: convertir en merma toda cancelación después de iniciar cocina.
- Impacto: sustituye el umbral automático de la ADR-025. No sustituye la separación entre anular la venta y mover inventario.

## ADR-029. Preparaciones con inventario y producción por lote. `APPROVED`

- Contexto: hogao, salsas, guacamole, ají y carne preparada se elaboran antes de vender el plato.
- Decisión: la preparación es un ítem con receta, rendimiento, merma de producción y costo. Publicar un lote descuenta sus componentes y entra la preparación. El plato descuenta la preparación, no otra vez los ingredientes originales.
- Justificación: estallar siempre hasta el crudo contaría dos veces la misma salsa.
- Riesgo: sin un lote previo, el plato se bloquea. La cocina tiene que producir antes de vender.
- Alternativa no aceptada: estallar la subreceta hasta el ingrediente en cada venta.
- Impacto: el lote de producción no es vencimiento de proveedor. Ese otro lote sigue fuera.

## ADR-030. Continuar el diseño del MVP mixto. `APPROVED`

- Contexto: Daniel aprobó seguir el diseño, con los pendientes a la vista.
- Decisión: se mantiene un solo pedido para mostrador, salón, domicilio y recogida, con inventario, compras, recetas, comandas, caja, pagos y reportes.
- Justificación: evitar módulos de venta independientes.
- Riesgo: tomar esta ficha como autorización para programar.
- Alternativa no aceptada: volver a un mostrador inicial.
- Impacto: no autoriza código, migraciones ni dependencias. El modelo técnico se aprueba en un paso posterior.

## ADR-031. Cola digital en el MVP. `APPROVED`

- Contexto: Daniel eligió la pantalla como canal inicial de cocina.
- Decisión: el MVP usa una cola digital. La impresora térmica puede entrar en una fase posterior y no se desarrolla ahora.
- Justificación: la integración de impresión no es indispensable para la primera operación.
- Riesgo: un servicio real puede echar de menos el papel. Eso no cambia la ficha hasta una decisión nueva.
- Alternativa dejada para después: impresora como canal único.
- Impacto: confirma la cola de la ADR-019 y mantiene la impresora fuera de la construcción.

## ADR-032. Reservar al confirmar y consumir al iniciar preparación. `APPROVED`

- Contexto: Daniel pidió ajustar la ADR-016 y dejó la regla en validación técnica.
- Decisión propuesta: el borrador no reserva. La línea confirmada reserva sus componentes directos. Enviar la comanda no consume. Iniciar la preparación de una cantidad convierte esa reserva en un solo consumo. Cancelar antes libera la reserva. Cancelar después no crea merma. Cobrar no consume. Mostrador y salón usan los mismos momentos.
- Validación técnica: es viable si el consumo es por cantidad de línea, si confirmar e iniciar en la misma acción es una sola transacción, si la foto de costo se toma en el consumo, y si una reserva sin cocina sigue vigente hasta cancelar. Esos cuatro puntos deben aceptarse al aprobar el modelo. Sin ellos, la regla no se implementa.
- Riesgo: reservas largas de pedidos programados reducen el disponible del salón.
- Alternativa que permanece en el historial: consumir al enviar la comanda, ADR-016.
- Nota del 2026-11-07: los casos de borde quedaron en la ADR-041. El modelo técnico los aprobó. Las reservas no se liberan solas; llevan antigüedad y alerta.

## ADR-033. Arquitectura fiscal configurable. `PENDING`

- Contexto: Daniel quiere precios con impuesto incluido, precios antes de impuesto, configuraciones distintas, historial y desglose. El contador todavía no valida la configuración.
- Decisión: no hay decisión aprobada. Las tasas no se escriben en el código. El esquema deja modo, vigencia y desglose listos para cuando exista la validación.
- Riesgo: cobrar al público antes de esa validación.
- Alternativa rechazada: fijar 8 % o 19 % en el código.
- Impacto: el comprobante interno de la ADR-034 tampoco puede darse por suficiente.

## ADR-034. Comprobante interno. `PROPOSED`

- Contexto: Daniel propone un comprobante interno para el MVP si el contador lo confirma.
- Decisión propuesta: el MVP puede emitir un comprobante interno. La factura electrónica permanece separada del pago y fuera de esta construcción.
- Estado contable: `PENDING`.
- Riesgo: usar el comprobante interno como si ya fuera documento fiscal.
- Alternativa: no emitir nada hasta la DIAN. No fue la propuesta elegida.
- Impacto: la ADR-010 se mantiene.

## ADR-035. Resolución del anticipo no recogido. `PENDING`

- Contexto: Daniel prohibió retener el anticipo de forma automática.
- Decisión: no hay política comercial aprobada. Las salidas posibles son devolución, crédito a favor, retención cuando ya exista una política aplicable, y resolución excepcional documentada. Cada salida escribe un movimiento. Ninguna es el valor por defecto.
- Riesgo: modelar el crédito a favor como una cuenta corriente completa. No lo es.
- Alternativa no aceptada: retención automática.
- Impacto: el caso del cliente que no recoge queda sin movimiento de dinero hasta que alguien lo resuelva.

## ADR-036. Cantidad de cajas físicas. `PENDING`

- Contexto: Daniel prohibió inventar el número.
- Decisión: no hay cantidad. El modelo admite varias cajas, cada una con turno, usuario y sede. El número se confirma antes del primer despliegue.
- Riesgo: sembrar dos cajas, o una sola, como si fuera el dato del restaurante.
- Alternativa no aceptada: asumir una caja porque el MVP inicial hablaba de una.
- Impacto: la operación simultánea de varias cajas sigue sin estar en la primera pantalla. La tabla no queda cerrada a una fila.

## Cierre de contradicciones del 2026-11-07

Estas fichas no borran las anteriores. El modelo completo está en `TECHNICAL_MODEL_APPROVAL.md`. Sigue pendiente de aprobación del propietario, salvo la idempotencia local, que Daniel marcó como obligatoria.

## ADR-037. La propina no es ingreso del restaurante. `APPROVED`

Estado desde el 2026-11-07: `APPROVED` por la aprobación de `TECHNICAL_MODEL_APPROVAL.md`. El texto histórico de la ficha se conserva.

- Contexto: el total de la venta y el movimiento de propina podían sumar dos veces el mismo dinero.
- Decisión propuesta: la venta guarda productos, descuentos, impuestos y cargos. La propina vive en el pago y en un movimiento `TIP`. Lo recibido se parte en aplicado, propina y vuelto. El vuelto apunta al pago.
- Consecuencia: el ingreso del reporte sale de la venta. El arqueo suma movimientos, no vuelve a sumar la venta.
- Alternativa no usada: guardar la propina también dentro del total de la venta.
- Impacto: sustituye, si se aprueba el modelo, la frase de propina incluida en los totales de `Sale`. La ADR-020 se mantiene. El reparto de la propina sigue `PENDING` y no se asume.

## ADR-038. Arqueo por medio y diferencia consolidada. `APPROVED`

Estado desde el 2026-11-07: `APPROVED` por la aprobación de `TECHNICAL_MODEL_APPROVAL.md`.

- Contexto: el conteo era por medio y el cierre guardaba una sola diferencia. El billete recibido se confundía con el neto.
- Decisión propuesta: cada medio tiene esperado, contado y diferencia. La diferencia consolidada es la suma. El efectivo esperado parte del saldo inicial y suma cobros e ingresos, y resta vueltos, devoluciones, gastos y retiros. El vuelto es un movimiento del pago que lo generó.
- Consecuencia: las tarjetas no entran al efectivo esperado.
- Alternativa no usada: un neto único de caja.
- Impacto: si se aprueba, cierra el hallazgo C-02 y C-07. La cantidad de cajas sigue `PENDING`.

## ADR-039. Idempotencia atómica del efecto local. `APPROVED`

- Contexto: Daniel declaró obligatoria esta decisión. Un timeout no es un pago fallido.
- Decisión: la llave, el hash y el efecto financiero local se confirman en la misma transacción. La llave es única por sede y operación. El efectivo y el medio atestiguado por el cajero terminan en `SUCCEEDED`. Un proveedor externo puede quedar `PENDING`, `PROCESSING`, `SUCCEEDED`, `FAILED` o `UNKNOWN`. `UNKNOWN` no entra al arqueo ni se reintenta con otra llave. Se concilia con el proveedor.
- Consecuencia: el MVP no conecta un proveedor. Tarjeta y transferencia atestiguadas son el caso local.
- Alternativa rechazada: tratar el timeout como fallo o crear una llave nueva.
- Impacto: precisa la ADR-021, que sigue en el historial. El estado `UNKNOWN` no se usa para el efectivo.

## ADR-040. Anticipo separado de la venta liquidada. `APPROVED`

Estado desde el 2026-11-07: `APPROVED` el mecanismo. La política del anticipo no reclamado sigue `PENDING` en la ADR-035.

- Contexto: un anticipo que cubre el monto podía leerse como venta pagada.
- Decisión propuesta: el anticipo es un depósito contra el pedido. Aplicarlo asigna el dinero ya recibido y no crea otro ingreso. Devolverlo escribe un reverso. El crédito a favor y la retención no se ejecutan hasta una política `APPROVED`. No hay cuenta corriente ni retención automática.
- Consecuencia: el pedido no pasa a pagado solo por el anticipo.
- Alternativa no usada: convertir el anticipo en venta al recibirlo.
- Impacto: mantiene la ADR-035 en `PENDING` para la política. El mecanismo de depósito y aplicación queda listo para el modelo.

## ADR-041. Reserva, consumo por cantidad y foto de costo. `APPROVED`

Estado desde el 2026-11-07: `APPROVED` por la aprobación de `TECHNICAL_MODEL_APPROVAL.md`. Sustituye el efecto operativo de la ADR-016. El texto de la ADR-016 permanece en el historial.

- Contexto: la ADR-032 ya era viable si el consumo era por línea. Faltaba escribir los casos de borde.
- Decisión propuesta: se adopta la secuencia de `INVENTORY_RULES.md`. El consumo es la cantidad iniciada, no el pedido. La reserva guarda la versión de receta. Un cambio de receta no la reescribe. Un modificador ya consumido no descuenta otra vez. La reserva sin cocina permanece hasta cancelar o iniciar. Confirmar e iniciar en mostrador es una transacción.
- Consecuencia: si este modelo se aprueba, la ADR-041 sustituye el efecto de la ADR-016. El texto de la ADR-016 no se borra.
- Alternativa que permanece en el historial: consumir al enviar la comanda.
- Impacto: la foto de costo de la ADR-022 se toma en el consumo, no en el envío. Sigue `PROPOSED` hasta la aprobación del modelo.

## ADR-042. Compra, producción y lote de proveedor. `APPROVED`

Estado desde el 2026-11-07: `APPROVED` por la aprobación de `TECHNICAL_MODEL_APPROVAL.md`. Los vencimientos de materia prima siguen fuera.

- Contexto: el lote de producción podía confundirse con la compra o con el vencimiento.
- Decisión propuesta: la recepción de compra entra existencias y costo. La orden de producción reserva, consume, registra rendimiento real, merma de producción, existencia de la preparación, costo real y trazabilidad. El lote de proveedor y el vencimiento de materia prima quedan fuera del comportamiento activo.
- Consecuencia: vender el plato después de producir no vuelve a descontar los ingredientes del lote.
- Alternativa no usada: estallar la preparación hasta el crudo en cada venta.
- Impacto: precisa la ADR-029, que sigue `APPROVED` como requisito. No adelanta los vencimientos.

## ADR-043. Aprobación formal del modelo técnico. `APPROVED`

- Contexto: el 2026-11-07 Daniel aprobó `TECHNICAL_MODEL_APPROVAL.md` como contrato de construcción del MVP mixto y declaró la Fase 0 aprobada. No autorizó la Fase 1.
- Decisión: el modelo técnico es referencia obligatoria. Quedan `APPROVED` las reglas de propina, arqueo, idempotencia, anticipo como mecanismo, reserva y consumo, y separación compra/producción. Quedan `PENDING` impuestos, comprobante, reparto de propinas, anticipos no reclamados y cantidad de cajas. Tres condiciones adicionales son obligatorias: (A) tarjeta o transferencia manual no se presenta como confirmación bancaria sin proveedor; (B) reservas con seguimiento, antigüedad y alertas, sin liberación automática; (C) inventario negativo solo con autorización, motivo, responsable, auditoría y visibilidad en reportes.
- Consecuencia: cualquier cambio posterior exige ADR nueva o revisión formal. El historial de ADR no se borra. La Fase 1 exige otra autorización expresa.
- Impacto: `PHASE_1_EXECUTION_PLAN.md` puede prepararse. No puede ejecutarse sin esa autorización.

## Decisiones todavía no tomadas

Cerradas el 2026-11-07: stock negativo silencioso, merma automática por estado, preparaciones con inventario, cola digital, modelo técnico, propina fuera de la venta, arqueo por medio, idempotencia local, reserva y consumo, separación compra/producción.

Siguen abiertas:

- Validación contable de impuestos, modo de precio y comprobante interno.
- Política comercial del anticipo no recogido.
- Política de distribución de propinas.
- Cantidad real de cajas.
- Autorización expresa de la Fase 1.
- Idioma de las rutas HTTP.
- Proveedor tecnológico de factura electrónica.
- Lugar de ejecución.
- Si el cajero ve costos.
- Pasarela de pagos.
- Tope de descuento.
