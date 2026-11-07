# Auditoría de la Fase 0

Estado del informe: **Propuesto**. Fecha: 2026-11-06.

Rol: auditoría independiente de la documentación. No hay código, migraciones, dependencias, base de datos ni despliegue. Ninguna ADR queda aprobada por este informe.

## Dictamen

La operación mixta sobre un solo pedido es una base sólida y conviene conservarla. Pedido, comanda, venta, pago y movimiento de caja están bien separados, y las pruebas conceptuales A, C, E, G, H e I tienen un resultado esperado defendible con las reglas ya escritas.

La Fase 1 no debe empezar. Hay siete hallazgos críticos de dinero, caja, recuperación y completitud del esquema. Aprobar hoy el paquete ADR-001 a ADR-020 dejaría esas contradicciones dentro del primer modelo.

## Alcance de la lectura

Se leyeron `PROJECT_MASTER.md`, `BUSINESS_REQUIREMENTS.md`, `TECHNICAL_ARCHITECTURE.md`, `DATABASE_SCHEMA.md`, `ARCHITECTURE_DECISIONS.md`, `DEVELOPMENT_ROADMAP.md` y `MODULE_STATUS.md`. Para contrastar comandos se usaron también `API_CONTRACTS.md` y la estrategia de pruebas. No se borró ninguna decisión histórica.

## Lo que la auditoría sostiene

- Un `Order` con canal `COUNTER`, `DINE_IN`, `DELIVERY` y `PICKUP`.
- La comanda como documento propio, con adiciones y cancelaciones que no borran el historial.
- La venta inmutable, publicada solo cuando la porción queda cubierta.
- El consumo de receta ligado a la comanda, no al cobro.
- La reserva de disponible para lo que aún no se envía a cocina.
- El turno de caja como único lugar por donde entra el dinero, con devolución en el turno abierto si el original ya cerró.
- Sede en cada operación, aunque la primera pantalla use una sola.
- Dinero en centavos y cantidades con unidad.

## Hallazgos

| Id | Severidad | Tema | Efecto si se construye así |
| --- | --- | --- | --- |
| C-01 | CRÍTICO | La propina aparece dentro del total de la venta y, a la vez, fuera de ese total | El cliente puede quedar cobrado dos veces, o el arqueo puede tomar la propina como venta de alimentos |
| C-02 | CRÍTICO | El conteo es por medio y el cierre guarda una sola diferencia | El efectivo físico se mezcla con tarjetas y transferencias |
| C-03 | CRÍTICO | La recuperación después de un timeout no queda cerrada | Un segundo intento con otra llave puede cobrar o descontar otra vez |
| C-04 | CRÍTICO | No está definido si el precio de carta ya incluye el impuesto | El total al público sale mal en todos los canales |
| C-05 | CRÍTICO | El promedio ponderado no tiene fórmula cuando la existencia es cero o negativa | Una compra corrige el costo con una cuenta inventada |
| C-06 | CRÍTICO | El esquema vigente no escribe compras, recetas, precios, identidad ni la tabla de idempotencia | La primera migración no tiene un modelo completo: el texto remite a una revisión que ya no está en el archivo |
| C-07 | CRÍTICO | El vuelto en efectivo no existe como movimiento | El arqueo ciego no puede cuadrar un billete mayor que la cuenta |
| A-01 | ALTO | La ADR-006 congela el costo en la venta; la arquitectura lo congela al enviar la comanda | Una mesa abierta varias horas puede costearse con un promedio distinto del que salió de cocina |
| A-02 | ALTO | No hay versión de receta ni snapshot de la explosión | El costo histórico es un número sin la fórmula que lo produjo |
| A-03 | ALTO | El contrato de API recalcula el total contra el precio vigente al cobrar | Un cambio de carta modifica una cuenta ya tomada |
| A-04 | ALTO | La reserva cubre la confirmación, no las líneas agregadas después | Una adición de recogida o domicilio puede vender de más |
| A-05 | ALTO | `VOID` está descrito como el fin de todas las ventas del pedido | Anular una sola parte de una división anularía la cuenta entera |
| A-06 | ALTO | El recaudo puede sumarse por pagos vigentes o por movimientos | Una devolución deja el reporte y el arqueo en cifras distintas |
| A-07 | ALTO | Anular, devolver dinero y mover inventario no están atados como tres efectos | Se puede devolver dinero y, además, reponer un plato ya comido, o anular la venta y dejar el dinero en caja |
| A-08 | ALTO | “Ya preparada” no tiene un estado dueño | La misma cancelación a veces devuelve el insumo y a veces lo manda a merma |
| A-09 | ALTO | No hay un orden único de bloqueos | Pedido contra saldo puede terminar en bloqueo mutuo |
| A-10 | ALTO | El pedido y `Fulfillment` tienen dos máquinas de estado | El domicilio puede figurar listo en un lado y pendiente en el otro |
| A-11 | ALTO | Un anticipo que cubre el total no es `PAID`, y el no-show no reclasifica ese dinero | El anticipo queda abierto para siempre o el reporte lo llama pago parcial |
| A-12 | ALTO | No está definido qué campos entran en el hash de la llave | Un reintento legítimo responde conflicto y la caja no puede continuar |
| M-01 | MEDIO | No hay cancelación de una parte de la cantidad enviada | Hay que cancelar la línea completa o quedarse sin regla |
| M-02 | MEDIO | Unir o trasladar una mesa con ventas ya publicadas no está escrito | La operación real de un salón lleno no tiene resultado único |
| M-03 | MEDIO | Impuesto de la tarifa de domicilio y de la propina | El contador todavía no tiene dónde configurarlo |
| M-04 | MEDIO | El precio no tiene sede | La segunda sede hereda la carta o exige otra migración |
| M-05 | MEDIO | Un envío no dice que se parte por estación | Al aparecer la barra, el código tendrá un solo ticket por envío |
| M-06 | MEDIO | Cancelar un domicilio ya despachado | La regla actual se detiene antes del despacho |
| M-07 | MEDIO | El reparto del impuesto en una división por partes iguales | El residuo de centavos del total no garantiza el residuo del impuesto |
| M-08 | MEDIO | Evento del pedido y auditoría de seguridad conviven sin frontera | Un descuento puede quedar solo en uno de los dos libros |
| M-09 | MEDIO | El diagrama exige al menos una línea y el flujo abre el pedido vacío | La cardinalidad no coincide con abrir mesa |
| M-10 | MEDIO | No se prohíbe adicionar un pedido cumplido o cancelado | Una mesa cerrada puede recibir otra comanda |
| M-11 | MEDIO | La subreceta siempre estalla hasta el insumo | Una salsa ya producida en la mañana se descuenta otra vez al vender |
| M-12 | MEDIO | La tarjeta solo la atestigua el cajero | El cuadre contra el datáfono es manual y el sistema no lo dice en el cierre |
| M-13 | MEDIO | Cerrar la mesa exige pedido cumplido | Una cuenta pagada no cierra si nadie marcó “entregado a la mesa” |
| B-01 | BAJO | ADR-005, ADR-008 y ADR-010 todavía hablan de cortes viejos | Confunde la lectura; la decisión de fondo sigue siendo usable |
| B-02 | BAJO | La flecha del diagrama de canales permite leer que el pago cierra el pedido | El texto correcto está en las reglas de cierre; el dibujo se puede leer mal |

## Reglas críticas, una por una

| Regla | Lectura de los documentos | Hueco |
| --- | --- | --- |
| Pedido y venta | El pedido opera. La venta nace al liquidar una porción cubierta | A-05 y M-13 |
| Venta y pago | La venta exige pagos que cubran su total. El anticipo es un pago contra el pedido | C-01 y A-11 |
| Pago y caja | Todo pago escribe un movimiento del turno | C-02, C-07 y A-06 |
| Comanda y consumo | Enviar consume una vez. Cobrar no consume | Se sostiene, con A-01 y A-02 |
| Reserva y consumo | Lo programado reserva. El envío convierte la reserva en movimiento | A-04 |
| Anulación y devolución | La venta no se edita. La devolución es otro movimiento | A-07 |
| Cuenta abierta y liquidada | La mesa cierra con cumplimiento y saldo en cero | M-13 |
| Anticipos | Se aplican a una venta o se devuelven si se cancela antes de vender | A-11. Falta el caso en que el dinero se queda |
| Pagos parciales | Varias ventas del mismo pedido | A-05 |
| División | Por línea, por cantidad, por comensal o en partes iguales, con residuo en la última parte | M-07 |
| Unión y traslado | Misma sede, las comandas siguen en el pedido | M-02 |
| Recepción parcial | La recepción confirmada mueve inventario y costo; la orden conserva lo pedido | C-05 y C-06. El agregado de compras no está escrito en el esquema actual |
| Costo promedio | Se recalcula al recibir. El reporte lo llama costo teórico | C-05 y A-01 |
| Mermas | Línea ya preparada, con autorización, sin devolver el insumo al disponible | A-08 |
| Concurrencia | Versión del pedido y bloqueo de saldos | A-09. El resultado del último insumo depende de una decisión aún abierta |
| Idempotencia | Misma llave y mismo cuerpo devuelven el resultado | C-03 y A-12. La ADR-009 no incluye el envío de comanda; la ADR-018 y el contrato sí |

## Pruebas conceptuales

Ninguna se ejecutó contra un sistema. El resultado es el que los documentos permiten defender, más el punto donde el resultado todavía no es único.

### A. La mesa agrega productos después de la primera comanda

Resultado esperado: la primera comanda no cambia. Las líneas nuevas quedan en borrador. Al enviarlas nace una comanda `ADDITION` con el consecutivo siguiente. El inventario se mueve solo por esas líneas. El pedido sigue abierto.

Transacción del envío de la adición: bloqueo del pedido, bloqueo de saldos, inserción de comanda y de sus líneas, movimientos de consumo, costo congelado en las líneas nuevas, evento, avance de versión, registro de idempotencia. Una sola transacción.

Hueco: M-10 si el pedido ya estaba cumplido. A-04 si el canal era domicilio o recogida y la adición debía reservarse antes del envío.

### B. El cliente divide la cuenta y paga con dos medios

Resultado esperado, lectura de la frase: dos porciones del mismo pedido. La porción de Ana se publica como venta cubierta en efectivo. La de Luis se publica como venta cubierta con tarjeta. Las comandas siguen siendo las originales. El residuo de una división en partes iguales queda en la última venta. Cada pago escribe su movimiento en el turno abierto. La propina, si existe, es otro movimiento.

Transacción de cada porción: bloqueo del pedido, comprobación de cantidades aún no liquidadas, inserción de venta y de sus impuestos, inserción del pago, asignación, movimiento de caja, proyección de `settlement_status`, evento, idempotencia.

El pago mixto de una sola porción es otro caso ya previsto: varios pagos de una misma venta, en la misma transacción.

Huecos: C-01, C-07 si el efectivo recibido es mayor que la porción, M-07 en el impuesto, A-05 si luego se anula solo una de las dos ventas.

### C. Dos usuarios modifican el mismo pedido a la vez

Resultado esperado: una transacción obtiene la fila y la versión. La otra espera o encuentra otra versión. La que llega tarde responde conflicto y no fusiona cambios. El usuario recarga.

Transacciones: `SELECT` del pedido para actualización, comparación de versión, escrituras, incremento de versión.

Hueco: A-09 si una de las dos transacciones también toca saldos y el orden de bloqueo no es el mismo. A-12 no aplica mientras ambas operaciones sean distintas de verdad.

### D. Dos pedidos consumen a la vez el último disponible

Resultado esperado, todavía bifurcado porque el propietario no eligió la política:

- Si el producto detiene el envío: la primera transacción consume. La segunda no escribe ningún movimiento de esa comanda y responde disponible insuficiente.
- Si el producto permite negativo: ambas consumen, en serie gracias al bloqueo, y el disponible queda negativo con kardex.

Transacción de cada envío: bloqueo del pedido, bloqueo de los insumos en orden de identificador, comprobación del disponible, comanda, movimientos o fallo íntegro, idempotencia.

Este caso no tiene un único resultado hasta cerrar la pregunta de stock. La arquitectura sí tiene dónde guardar las dos políticas.

### E. Se envía una comanda y después se cancela un producto

Resultado esperado: la comanda original permanece. Nace una comanda `CANCEL` con motivo. Si la línea sigue en cola, el insumo vuelve con un movimiento de reverso y el efecto pasa a `REVERSED`. Si ya se considera preparada, hace falta autorización, el movimiento es merma y el efecto pasa a `WASTED`. Las otras líneas del pedido siguen. El pedido no se cancela entero.

Transacción: bloqueo del pedido y de los saldos, comanda de cancelación, un movimiento compensatorio, actualización de la línea, evento, auditoría del autorizador cuando hay merma, idempotencia.

Hueco: A-08 define mal el umbral. Propuesta de trabajo, no aprobada: en cola se revierte; desde “en preparación” es merma, salvo que un supervisor elija reverso.

### F. Se cobra, hay timeout y el cajero intenta de nuevo

Resultado esperado si la llave y el cuerpo se conservan: el segundo intento no crea otra venta, otro pago ni otro consumo. Devuelve el resultado ya confirmado si la primera transacción alcanzó a confirmarse. Si no alcanzó, la aplica una sola vez.

Transacción única del mostrador, según el contrato: comanda, venta y pago se confirman juntas o no queda ninguna. El registro de idempotencia viaja en esa misma transacción. Esto último está implícito y no escrito: es C-03.

Si el cajero o la pantalla generan una llave nueva porque “parece que falló”, el diseño actual cobra dos veces. Ese camino hay que prohibirlo: mientras una llave esté sin respuesta, la única acción es repetirla o consultarla.

### G. Se cancela un domicilio cuando la cocina ya empezó

Resultado esperado: no se marca entregado. El cumplimiento pasa a cancelado. Cada línea aplica la regla de E. Si había anticipo y todavía no hay venta, el anticipo se devuelve con un movimiento nuevo; el pago original no se edita. Si ya había venta, la anulación de esa venta y la devolución van juntas. La tarifa de domicilio sigue el dinero: se devuelve si se había cobrado. El pedido cancelado no se reabre.

Transacción: pedido, saldos, comanda de cancelación, movimientos de inventario, devolución de dinero si existe, `Fulfillment` cancelado, eventos.

Huecos: A-08, A-07, A-10 y M-06. El caso pedido ocurre antes del despacho y sí está cubierto en la regla 3.8, con el umbral de merma todavía flojo.

### H. Se recibe una compra parcial

Resultado esperado, reconstruido desde las reglas que sobrevivieron y no desde tablas visibles: la orden guarda lo pedido. La recepción confirmada registra solo lo llegado y su costo real. En la misma transacción se insertan movimientos de compra, se actualiza el saldo, se recalcula el promedio y nace la obligación por el valor recibido, no por el pedido entero. Una segunda recepción usa otra llave. Repetir la primera llave no duplica stock ni deuda. La diferencia pedida contra recibida queda visible.

Huecos: C-05 y C-06. Sin la fórmula del promedio y sin el agregado escrito, dos implementaciones pueden confirmar “la misma” recepción de formas distintas.

### I. Se devuelve dinero después de cerrar el turno original

Resultado esperado: el turno cerrado no recibe líneas ni cambia su esperado guardado. La devolución se escribe en el turno abierto actual, con referencia al movimiento original. Si el medio es efectivo, baja el efectivo esperado del turno nuevo. Si el medio es tarjeta o transferencia, baja el esperado de ese medio y no el efectivo del cajón.

Transacción: comprobación de turno abierto, movimiento `REFUND`, estado del pago original, `SaleVoid` si se anula la venta, auditoría, idempotencia.

Huecos: C-02, porque un cierre de una sola cifra no puede expresar ese separado por medio, y A-07, porque la devolución no debe decidir sola el inventario.

### J. Anticipo para recoger y el cliente no reclama

Resultado esperado con lo escrito hoy: un autorizado marca `NO_SHOW`. Si no hubo comanda, se libera la reserva. Si ya se había enviado, el inventario sigue la regla de cancelación. El anticipo no se devuelve solo ni se convierte solo en ingreso. Queda pendiente de un movimiento autorizado.

Ese resultado es incompleto para operar. Falta el movimiento que cierra el anticipo cuando el negocio decide conservarlo, y falta no llamar `PAID` a un pedido que solo tiene anticipo. Es A-11. La política de quedarse el dinero, devolverlo o decidir caso a caso pertenece al propietario.

Transacción del no-show, sin tocar el dinero: pedido, reserva o merma, `Fulfillment`, evento y auditoría. Transacción posterior, solo si el propietario ya eligió: devolución o reclasificación del anticipo, en el turno abierto.

### K. Se pierde la conexión mientras se registra un pago

Resultado esperado: el cajero no sabe si el servidor confirmó. La pantalla conserva la llave. Al volver la red, repite el mismo comando con esa llave. Si había quedado confirmado, recibe el mismo pago y no escribe otro movimiento. Si no había quedado confirmado, lo escribe una vez.

Eso solo es verdad si el pago, el movimiento de caja y el registro de la llave se confirman en la misma transacción, y si la pantalla no crea otra llave. Hoy la intención existe y la regla exacta no. Es C-03 y A-12.

Un pago guardado en el navegador no es un pago confirmado. En el MVP la tarjeta tampoco queda confirmada por un banco: queda atestiguada por el cajero cuando la transacción del servidor sí se confirmó.

## Revisión de crecimiento

| Tema | Situación | Hallazgo |
| --- | --- | --- |
| Multi-sede | `branch_id` en la operación y consultas por la sede de la sesión | La dirección es correcta. M-04: el precio no está partido por sede |
| Varias cajas | Varias cajas en el modelo, una en la operación, un turno abierto por caja | Correcto como preparación. C-02 y C-07 impiden cuadrar siquiera una caja |
| Estaciones | La comanda guarda estación y el producto puede sugerirla. La pantalla es una cola | Correcto. M-05 pide partir el envío por estación desde el primer comportamiento |
| Medios y efectivo físico | El movimiento tiene medio. El conteo es por medio | C-02 y C-07. La tarjeta no es efectivo y el cierre actual no lo garantiza |
| Historial de precios | El texto antiguo hablaba de precio por vigencia. La línea guarda el precio cotizado | C-06 y A-03. La tabla de vigencia no está en el esquema vigente |
| Versionado de recetas | No existe | A-02 |
| Costo histórico | Número congelado en la línea y copiado a la venta | A-01 y A-02. La congelación está pedida; la explicación del número, no |
| Impuestos | Tasa en datos, puntos básicos, congelados en la venta | C-04 y M-03. Falta saber si el precio ya los incluye |
| Auditoría inmutable | Acciones sensibles con PIN y libros de solo inserción | M-08. La intención es correcta y la frontera entre libros no |
| Conciliación de pagos | El esperado sale de los movimientos. La tarjeta la atestigua el cajero | M-12. No hay conciliación bancaria en el MVP, y el cierre debe decirlo |
| Recuperación | Reintento con la misma llave | C-03 y A-12. Es la pieza que el escenario K necesita por escrito |

## Revisión de las ADR-001 a ADR-020

Todas siguen en estado **Propuesto**. La recomendación no las aprueba.

### ADR-001. Monolito modular

- Decisión: una aplicación NestJS y un esquema compartido.
- Justificación: venta, inventario y caja deben confirmarse juntos.
- Riesgos: `shared` se llena de reglas de restaurante.
- Alternativas: microservicios, o un módulo único sin límites.
- Impacto: los cruces del MVP siguen siendo una transacción.
- Recomendación: mantenerla.

### ADR-002. Pila Next.js, NestJS, PostgreSQL, Prisma y Zod

- Decisión: aceptar esa pila y validar entradas solo con Zod.
- Justificación: encaja con el monolito y con los contratos.
- Riesgos: transacciones Prisma demasiado largas en un cobro de mostrador que también envía comanda.
- Alternativas: Vite, Drizzle, class-validator.
- Impacto: no agrega Redis ni un segundo framework.
- Recomendación: mantenerla. El cobro de mostrador debe seguir siendo una transacción corta.

### ADR-003. Dinero en centavos enteros

- Decisión: `bigint` en centavos y una sola función de redondeo.
- Justificación: el punto flotante está prohibido y la factura futura usa dos decimales.
- Riesgos: C-04 y M-07 si el redondeo del impuesto no tiene dueño.
- Alternativas: pesos enteros, o `numeric(19,2)`.
- Impacto: todos los totales y el arqueo.
- Recomendación: mantenerla y no cobrar al público hasta definir el redondeo y el impuesto incluido.

### ADR-004. Cantidades con decimal de precisión fija

- Decisión: cantidad con unidad, convertida a la unidad de control antes del saldo.
- Justificación: la compra y la receta no usan la misma unidad.
- Riesgos: convertir mal antes del promedio altera C-05.
- Alternativas: entero en unidad mínima, o punto flotante.
- Impacto: kardex y recetas.
- Recomendación: mantenerla.

### ADR-005. UUID versión 7

- Decisión: identificadores de negocio generados por la aplicación.
- Justificación: sirven después para sincronizar.
- Riesgos: bajo. El texto todavía dice “Corte 4”.
- Alternativas: enteros o UUID versión 4.
- Impacto: toda tabla operativa. La numeración DIAN queda aparte.
- Recomendación: mantenerla. B-01 es solo de redacción.

### ADR-006. Costo promedio ponderado

- Decisión: el promedio cambia al confirmar la recepción y la venta congela el costo.
- Justificación: el plato necesita un costo sin lotes.
- Riesgos: C-05 y A-01. “La venta congela” choca con congelar al enviar.
- Alternativas: costo estándar, FIFO o último costo.
- Impacto: margen teórico y reportes.
- Recomendación: mantener el promedio. Aclarar el momento de la foto con la ADR-022, sin reescribir esta ficha.

### ADR-007. Libros de solo inserción

- Decisión: stock, caja, precios, pagos, anulaciones y auditoría se insertan.
- Justificación: el pasado no se reescribe.
- Riesgos: A-06 si un reporte lee estados y otro lee movimientos.
- Alternativas: actualizar la fila y auditar al lado.
- Impacto: toda corrección es un movimiento nuevo.
- Recomendación: mantenerla.

### ADR-008. Una sede en el modelo, una sede en la operación

- Decisión: toda operación lleva sede desde la primera migración.
- Justificación: evitar una migración masiva el día de la segunda sede.
- Riesgos: M-04 en precios. El texto todavía dice “Corte 4”.
- Alternativas: agregar la sede después, o construir consolidados ya.
- Impacto: consultas y permisos.
- Recomendación: mantenerla.

### ADR-009. Idempotencia obligatoria en comandos críticos

- Decisión: tabla y encabezado en recepción, cobro, anulación, conteo y cierre.
- Justificación: un timeout no prueba que la operación no haya quedado.
- Riesgos: C-03. La lista no incluye enviar comanda ni registrar pago como comando propio. La ADR-018 y el contrato sí.
- Alternativas: fiarse solo del identificador que inventa el cliente.
- Impacto: caja, compras y cocina.
- Recomendación: mantener la intención. No usarla como lista cerrada. La completa la ADR-021.

### ADR-010. Venta y documento fiscal separados

- Decisión: la factura tiene su propio estado y un rechazo no toca la venta.
- Justificación: la DIAN confirma en otro momento.
- Riesgos: bajo en el MVP, porque la factura está fuera. El texto dice “Corte 3”.
- Alternativas: marcar la venta como facturada al enviarla.
- Impacto: el futuro fiscal cuelga de la venta inmutable.
- Recomendación: mantenerla.

### ADR-011. Offline diferido, cimientos ahora

- Decisión: UUID e idempotencia ahora; cola y conflictos después de turnos reales.
- Justificación: sincronizar es el riesgo más grande y el local todavía no operó en línea.
- Riesgos: una caída de internet detiene el MVP. Hay que decirlo al personal.
- Alternativas: POS offline desde el primer día, o ignorar los identificadores.
- Impacto: el escenario K se resuelve en línea, no dentro del navegador.
- Recomendación: mantenerla.

### ADR-012. Un repositorio y dos aplicaciones

- Decisión: `apps/web` y `apps/api`. El dominio vive en la API.
- Justificación: el contrato cambia junto.
- Riesgos: bajo.
- Alternativas: dos repositorios, o muchos paquetes vacíos.
- Impacto: el navegador no descuenta inventario.
- Recomendación: mantenerla.

### ADR-013. Impuesto configurable

- Decisión: la tasa es un dato. El comprobante interno no es factura DIAN.
- Justificación: el régimen lo define el contador.
- Riesgos: C-04. Configurable no alcanza si no se sabe si el precio ya incluye el tributo.
- Alternativas: fijar 8 % o 19 % en el código.
- Impacto: todos los totales al público.
- Recomendación: mantenerla y bloquear el cobro real hasta la respuesta del contador.

### ADR-014. Operación mixta sobre un solo pedido

- Decisión: un pedido y cuatro políticas de canal.
- Justificación: el propietario definió la operación mixta y un mostrador inicial habría que reconstruirlo.
- Riesgos: implementar salón o domicilio al lado del pedido.
- Alternativas: cuatro módulos, o mostrador primero con otro modelo.
- Impacto: el primer esquema incluye mesas, comanda y cumplimiento.
- Recomendación: mantenerla. Es la decisión de producto correcta.

### ADR-015. Pedido, comanda, venta, pago y movimiento de caja separados

- Decisión: cinco documentos.
- Justificación: cada uno responde una pregunta distinta.
- Riesgos: C-01, A-07 y A-10 en las fronteras.
- Alternativas: una sola entidad, o crear la venta al abrir la mesa.
- Impacto: todo el MVP.
- Recomendación: mantenerla.

### ADR-016. El inventario se mueve al enviar la comanda

- Decisión: la comanda consume una vez. El cobro no consume. Lo no enviado reserva. La cancelación compensa una vez.
- Justificación: es el momento en que la cocina compromete insumos.
- Riesgos: A-04, A-08, M-11 y la pregunta abierta de stock negativo.
- Alternativas: consumir al crear la línea, al cobrar o al entregar.
- Impacto: kardex, reportes y cancelaciones.
- Recomendación: mantenerla, sujeta a que el propietario la confirme y a cerrar A-04 y A-08.

### ADR-017. Varias ventas por pedido

- Decisión: cada porción pagada es una venta inmutable. El anticipo se asigna después.
- Justificación: la división y el pago parcial no deben clonar la cocina.
- Riesgos: A-05, A-11, C-01 y M-07.
- Alternativas: clonar el pedido, o editar una sola venta hasta el cierre.
- Impacto: salón, anticipos y reportes de venta.
- Recomendación: mantenerla.

### ADR-018. Concurrencia de pedido y de saldo

- Decisión: versión y bloqueo de fila en el pedido; saldos en orden de insumo; llaves en los comandos críticos.
- Justificación: dos meseros y dos pedidos no pueden perder una escritura.
- Riesgos: A-09. Esta ficha sí incluye el envío de comanda, a diferencia de la ADR-009.
- Alternativas: el último escritor gana, o bloquear toda la sede.
- Impacto: escenarios C y D.
- Recomendación: mantenerla y precisar el orden global de bloqueos en la ADR-026.

### ADR-019. Una cola de cocina y estaciones en el modelo

- Decisión: la estación existe; la operación muestra una cola; la impresora queda fuera.
- Justificación: el MVP necesita historial sin construir el monitor completo.
- Riesgos: M-05 y la pregunta del propietario sobre la impresora del primer día.
- Alternativas: no guardar estación, construir el KDS ya, o imprimir como único canal.
- Impacto: comandas presentes y monitor futuro.
- Recomendación: mantenerla.

### ADR-020. Todo peso entra por un turno abierto

- Decisión: pago, anticipo, propina, gasto y devolución exigen turno abierto. La propina va aparte. La devolución de un turno cerrado cae en el turno actual.
- Justificación: el arqueo tiene que explicar cada peso y un cierre no se reescribe.
- Riesgos: C-01, C-02, C-07 y A-11. La ficha es la correcta; el esquema de la venta y del cierre no la cumplen todavía.
- Alternativas: pagos de domicilio fuera de caja, o editar el cierre.
- Impacto: caja de los cuatro canales.
- Recomendación: mantenerla y alinear esquema y cierre con la ADR-024.

## Propuestas nacidas de la auditoría

Siguen en estado **Propuesto**. No modifican el texto de las ADR-001 a ADR-020. Están copiadas en `ARCHITECTURE_DECISIONS.md`.

| Propuesta | Cierra | Decisión propuesta |
| --- | --- | --- |
| ADR-021 | C-03, A-12 | La llave, el hash canónico y el efecto se confirman en la misma transacción. La lista incluye envío, pago y los comandos ya dichos. Con una llave sin resolver no se crea otra |
| ADR-022 | A-01, A-02 | La foto de costo y de explosión se toma al enviar. La venta copia esa foto. Cada guardado de receta deja una versión |
| ADR-023 | A-03, parte de C-06 | Se cobra el precio cotizado en la línea. Un precio nuevo de carta afecta las líneas nuevas. El historial de precios vuelve al esquema |
| ADR-024 | C-01, C-02, C-07 | El total de la venta no incluye propina. El cierre guarda esperado, contado y diferencia por medio. El vuelto es una salida de efectivo |
| ADR-025 | A-07, A-08 | Anular la venta, devolver dinero y compensar inventario son efectos distintos. Anulación y devolución van juntas. El inventario no se devuelve solo porque se anuló la venta |
| ADR-026 | A-04, A-05, A-09, A-10, A-11 | Se reserva toda línea no enviada de domicilio y recogida. Primero se bloquea el pedido y después los saldos. `PAID` exige ventas publicadas. El anticipo que cubre el total sigue siendo anticipo hasta aplicarse |

C-04, C-05, C-06, M-11 y la política de no-show no quedan cerradas con una ficha técnica. C-05 puede cerrarse con la fórmula propuesta abajo si el propietario acepta el stock negativo como caso aparte. C-06 es trabajo de documentación anterior a cualquier migración: reescribir en `DATABASE_SCHEMA.md` los agregados ausentes, sin SQL.

Fórmula propuesta para el promedio, todavía no aprobada. Cantidades en unidad de control y costos en centavos, con la misma función de redondeo del proyecto:

- Si la existencia es mayor que cero: promedio nuevo = (existencia × promedio anterior + cantidad recibida × costo unitario recibido) / (existencia + cantidad recibida).
- Si la existencia es cero o negativa: el promedio nuevo es el costo unitario recibido. La existencia negativa no fabrica un costo histórico.

## Decisiones que necesita el propietario

Estas no las puede cerrar el arquitecto:

1. ¿El precio de la carta es lo que el cliente paga, o es la base antes de impuesto? Lo responde junto con el contador. Bloquea C-04.
2. ¿Qué documento recibe el cliente el primer día y qué tasas aplican? El comprobante interno sigue siendo posible.
3. ¿Sin disponible se detiene el envío o se permite saldo negativo? Cambia el escenario D.
4. ¿Se confirma que el inventario se descuenta al enviar la comanda y que domicilio y recogida reservan antes?
5. ¿Desde qué momento una cancelación es merma: al pasar a “en preparación”, al marcar “listo”, o lo elige un supervisor en cada caso?
6. Si el cliente de recogida no llega, ¿el anticipo se devuelve, se queda en el negocio o se decide caso a caso?
7. ¿La cocina del primer servicio puede trabajar con una cola en pantalla, o la impresora es indispensable?
8. ¿Cuántas cajas físicas hay el primer día?
9. ¿Hay salsas u otras subrecetas que ya existan en inventario antes de vender el plato? Cambia M-11.
10. ¿Se aprueba el alcance mixto del MVP con los hallazgos críticos como condición, o se ajusta el alcance?

También siguen abiertas, sin ser las primeras: tope de descuento, si el cajero ve costos, medios de pago reales, insumos y diez recetas del restaurante, y dónde correrá el servidor.

## Puerta de la Fase 1

No está autorizada.

Para abrirla hace falta, en este orden:

1. Respuesta del propietario a las diez preguntas anteriores.
2. Aceptación o rechazo expreso de las ADR-021 a ADR-026.
3. Completar `DATABASE_SCHEMA.md` con compras, recetas versionadas, precios, identidad, idempotencia, cierre por medio y vuelto. Eso sigue siendo documentación. No es una migración.
4. Recorrer de nuevo los escenarios A a K contra ese texto y dejarlos con un solo resultado esperado.
5. Aprobación formal del paquete. Hasta entonces las ADR-001 a ADR-026 permanecen propuestas.

El criterio de salida que hoy está en `DEVELOPMENT_ROADMAP.md` pide aprobar las ADR-001 a ADR-020. Ese criterio queda condicionado por este informe.

## Addenda del 2026-11-07

Daniel respondió las diez preguntas. Esta addenda no reescribe los hallazgos de arriba.

| Hallazgo | Efecto de la respuesta |
| --- | --- |
| Escenario D, stock insuficiente | `APPROVED`. El segundo pedido no consume, salvo excepción autorizada y auditada |
| A-08 y el umbral de merma | `APPROVED`. La merma no nace del cambio de estado |
| M-11, subreceta estallada al vender | `APPROVED`. La preparación tiene inventario y el plato la descuenta a ella |
| C-04, impuesto incluido | Sigue `PENDING` del contador |
| Escenario J, anticipo | Sigue `PENDING`. Quedó prohibida la retención automática |
| ADR-016, consumo al enviar | Pasa a espera. La alternativa está `PROPOSED` en la ADR-032 |
| C-01, C-02, C-03 y C-07 | Siguen abiertos. No vinieron en estas diez respuestas |

La Fase 1 continúa sin autorización. El paso siguiente es aprobar el modelo técnico.

## Addenda del cierre de contradicciones

El mismo 2026-11-07 el modelo candidato resolvió, todavía en estado `PROPOSED`, los hallazgos que la addenda anterior dejaba abiertos:

| Hallazgo | Resolución candidata | Estado |
| --- | --- | --- |
| C-01 Propina dentro y fuera del total | La venta no guarda propina. El pago la separa y el movimiento `TIP` es el único que entra a caja | `PROPOSED` en ADR-037. El reparto sigue `PENDING` |
| C-02 Una sola diferencia de cierre | Esperado, contado y diferencia por medio, más diferencia consolidada | `PROPOSED` en ADR-038 |
| C-07 Vuelto | El billete recibido, lo aplicado, la propina y el vuelto son campos distintos. El vuelto apunta al pago | `PROPOSED` en ADR-037 y ADR-038 |
| C-03 Timeout del cobro | La llave local se confirma con el efecto. Un timeout no es un fallo. `UNKNOWN` queda para el proveedor externo | `APPROVED` en ADR-039 |
| C-05 Promedio con existencia no positiva | Sigue la fórmula propuesta en el esquema. La existencia negativa solo nace de la excepción auditada | `PROPOSED` la fórmula. `APPROVED` el bloqueo |
| ADR-016 frente a ADR-032 | Los casos de borde quedaron en la ADR-041 | `PROPOSED` hasta aprobar el modelo |

C-04, la política del anticipo y la cantidad de cajas no se cierran con este candidato. La puerta de la Fase 1 de más arriba queda sustituida, para el paso inmediato, por la aprobación de `TECHNICAL_MODEL_APPROVAL.md` y por una autorización expresa de construcción. El historial de aquella puerta no se borra.

## Addenda de aprobación formal

El 2026-11-07 Daniel aprobó el modelo técnico y la Fase 0. La Fase 1 permanece `NOT AUTHORIZED`. El plan está en `PHASE_1_EXECUTION_PLAN.md`. Los hallazgos C-01, C-02, C-03 y C-07 quedan cerrados en el contrato aprobado. C-04 sigue `PENDING` del contador.
