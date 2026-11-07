# Requisitos de negocio

Estado del documento: en revisión. Fecha de las decisiones de Daniel: 2026-11-07.

Estados usados tal como los pidió el propietario:

| Estado | Significado |
| --- | --- |
| `APPROVED` | Decisión cerrada por Daniel. El diseño debe cumplirla. |
| `PROPOSED` | Regla o recomendación todavía sujeta a la aprobación del modelo técnico. |
| `PENDING` | Falta el contador, una política comercial o un dato real. No se inventa. |

Fuente anterior: prompt maestro y la operación mixta del 2026-11-06. Esta revisión no borra esas decisiones. Cuando una regla de aquel texto queda reemplazada, se indica la ficha nueva.

## 0. Registro de decisiones del 2026-11-07

| # | Tema | Estado | Qué quedó cerrado | Qué no quedó cerrado |
| --- | --- | --- | --- | --- |
| 1 | Precio de carta e impuestos | `PENDING` | Nada de tasas ni de modo incluido o excluido | Arquitectura fiscal configurable, historial y desglose. La validación es del contador. Las tasas no van en el código |
| 2 | Comprobante del cliente | `PROPOSED` y `PENDING` | La emisión fiscal sigue separada del pago | Comprobante interno para el MVP, hasta que el contador lo confirme. DIAN queda preparada y fuera de esta construcción |
| 3 | Inventario insuficiente | `APPROVED` | Bloqueo por defecto. Excepción con usuario, PIN, motivo, cantidad y auditoría. Sin negativos silenciosos | El texto de la excepción autorizada |
| 4 | Reserva y consumo | `APPROVED` | Reservar al confirmar, consumir al iniciar, alertas de reserva, sin liberación automática | Sustituye el efecto de la ADR-016. Historial conservado |
| 5 | Mermas | `APPROVED` | Movimiento propio, con motivo y responsable. No nace por cambiar el estado del pedido | Tipos: ingrediente, preparación, pérdida en preparación y producto dañado. Autorización según el tipo |
| 6 | Anticipo no recogido | `PENDING` | El sistema no retiene el anticipo por su cuenta | Devolución, crédito a favor, retención solo con política previa, o resolución excepcional. Cada una con movimiento |
| 7 | Cocina | `APPROVED` la cola digital | El MVP opera con cola en pantalla | La impresora térmica queda para una fase posterior y no se desarrolla ahora |
| 8 | Cajas físicas | `PENDING` | No se inventa la cantidad | El modelo admite varias cajas, cada una con turno, usuario y sede. El número se confirma antes del primer despliegue |
| 9 | Preparaciones y subrecetas | `APPROVED` | Requisitos de diseño: receta, subreceta, producción por lote, rendimiento, merma de producción y costo | Al producir se descuentan los componentes y entra la preparación. Al vender se descuenta la preparación, no otra vez sus ingredientes |
| 10 | Alcance mixto | `APPROVED` | Un solo núcleo de pedidos. Fase 0 y modelo técnico aprobados | La Fase 1 sigue `NOT AUTHORIZED` |

Las fichas ADR-027 a ADR-036 registran estas mismas decisiones sin reescribir las ADR-001 a ADR-026.

## 1. Modelo operativo

El Patacón trabaja con cuatro canales sobre un mismo pedido:

| Canal | Quién lo abre | Qué es obligatorio | Qué no usa |
| --- | --- | --- | --- |
| `COUNTER` | Cajero | Sede, cajero, líneas | Mesa. Cliente opcional |
| `DINE_IN` | Mesero | Sede, mesa, sesión, mesero | Dirección |
| `DELIVERY` | Cajero o quien tome el pedido | Cliente, teléfono, dirección, tarifa de domicilio | Mesa |
| `PICKUP` | Cajero o quien tome el pedido | Cliente o nombre, teléfono, fecha y hora prometida | Mesa y dirección |

Catálogo, precios, variantes, modificadores, recetas, inventario, comandas, pagos, ventas, caja, reportes y auditoría son comunes. El canal es un dato del pedido, visible en operación y en reportes.

## 2. Alcance definitivo del MVP

Estado del alcance: **Propuesto**, a la espera de aprobación formal.

### Entra

**Administración.** Usuarios, siete roles, permisos por sede, auditoría, una organización y la configuración de la sede (zona `America/Bogota`, moneda `COP`, una caja inicial, una estación de preparación inicial).

**Carta e inventario.** Categorías, productos, variantes, modificadores y adicionales, ingredientes, preparaciones, unidades, conversiones, recetas, subrecetas, producción por lote, rendimiento, costo promedio, costo teórico, kardex, mermas auditables, ajustes, conteo y stock mínimo. El bloqueo sin disponible es `APPROVED`.

**Compras.** Proveedores, orden, recepción parcial, actualización de existencia y costo al confirmar, cuenta por pagar y abono. Gastos operativos que no mueven inventario.

**Pedidos.** Los cuatro canales. Cliente cuando el canal lo pide. Descuento con autorización. Estados de cumplimiento y de liquidación, separados. Historial de eventos.

**Salón.** Salas, mapa de mesas, estados libre, ocupada, esperando cuenta, reservada y en limpieza. Apertura de cuenta, mesero, comensales, traslado, unión, división y cierre.

**Comanda básica.** Envío a cocina, adición, cancelación con motivo, estados en cola, en preparación, listo, entregado a servicio y cancelado. Historial que no se borra. Cola digital única: `APPROVED` como canal del MVP. La estación existe en el modelo. La impresora no se desarrolla ahora.

**Caja.** Apertura de turno, efectivo, tarjeta, transferencia, pago mixto, propina, gasto, arqueo ciego, diferencia, anulación y devolución con rastro. El modelo admite otra caja sin cambiar las tablas; la operación inicial usa una.

**Reportes de una sede.** Ventas cobradas por canal y por producto. Recaudos por medio. Consumo teórico por comandas. Costo teórico de lo cobrado. Gastos. Diferencias de caja. Pedidos abiertos sin mezclarlos con ventas.

### No entra

Monitor por estaciones, tiempos de demora, alertas sonoras, impresión térmica, factura electrónica, nota crédito, POS electrónico, Rappi, Justo, DiDi, tienda propia, carta QR, WhatsApp, pasarela, campañas, lotes y vencimientos, combos, listas de precios, cuenta corriente de clientes, mapa de calor, reportes consolidados de varias sedes, modo offline y numeración DIAN.

Esas piezas no deben obligar a cambiar la identidad del pedido, de la comanda, de la venta ni del movimiento de caja.

## 3. Reglas operativas

### 3.1 Abrir y cerrar una cuenta de mesa

Abrir solo si la mesa está libre o reservada. En una transacción se crea la sesión de mesa, el pedido `DINE_IN` y la ocupación. La mesa pasa a ocupada. El mesero responsable queda en la sesión.

Pedir la cuenta cambia la mesa a esperando cuenta. Ese estado no cobra ni cierra.

Cerrar exige que cada pedido de la sesión esté cumplido o cancelado, y que la liquidación esté pagada o anulada con saldo en cero. La sesión se cierra. Las mesas ocupadas por esa sesión pasan a limpieza. Otro usuario las devuelve a libre. Una mesa en limpieza no recibe una cuenta nueva.

### 3.2 Agregar productos después de enviar la comanda

La línea nueva nace en borrador y no altera la comanda ya enviada. Al enviarla se crea otra comanda de tipo adición, con su propio consecutivo. El historial de la primera comanda permanece.

El inventario de esa adición no se mueve por el solo hecho de enviarla a la cola. Sigue la regla `PROPOSED` del apartado 3.7: reservar al confirmar la línea y consumir cuando la cocina inicia su preparación.

### 3.3 Dividir una cuenta

La división liquida porciones del mismo pedido. No clona el pedido ni la comanda.

Se puede dividir por líneas, por cantidad de una línea o por etiqueta de comensal. También en partes iguales: el residuo de centavos queda en la última parte para que la suma coincida con el total. Cada parte pagada genera una venta inmutable. Lo no incluido sigue abierto en el pedido.

### 3.4 Trasladar entre mesas y unir mesas

Trasladar un pedido, dentro de la misma sede: si la mesa destino tiene sesión abierta, el pedido pasa a esa sesión; si está libre, se abre sesión allí. Si la mesa origen queda sin pedidos, pasa a limpieza. Queda un evento con origen y destino. Las comandas siguen apuntando al mismo pedido.

Unir mesas elige una sesión principal. Los pedidos y las mesas secundarias quedan en esa sesión. La sesión secundaria se cierra con motivo de unión. Las comandas no se reescriben. Al cerrar la principal, todas las mesas unidas pasan a limpieza.

### 3.5 Pagos parciales

Se publica una venta solo por las líneas y cantidades elegidas, en la misma transacción que cubre su total. El resto del pedido sigue abierto y su liquidación queda parcialmente pagada.

Un anticipo de domicilio o de recogida es un pago contra el pedido, todavía sin venta. Al cobrar, el anticipo se aplica a la venta. Si el pedido se cancela antes de la venta, el anticipo se devuelve con un movimiento de caja. No se edita el pago original.

### 3.6 Pedidos cancelados

Estado de la merma: `APPROVED` por la ADR-028. El texto del 2026-11-06, que convertía en merma toda línea ya preparada, queda reemplazado en ese punto.

Cancelar una línea en borrador registra el evento. No reserva ni consume.

Cancelar una línea confirmada que todavía no entró en preparación libera la reserva. No crea una merma.

Cancelar después de iniciada la preparación no fabrica una merma por el cambio de estado. El consumo ya registrado permanece. Si hay una pérdida real, una persona autorizada registra la merma como movimiento aparte, con motivo y responsable. Si la preparación puede reincorporarse, el reintegro también es un movimiento explícito, no un efecto oculto de la cancelación.

Un pedido cancelado no se reabre. Si hay pagos, la devolución es un movimiento financiero. El anticipo no se retiene solo. La política de ese dinero sigue `PENDING`.

### 3.7 Inventario, una sola vez

Estado: `APPROVED` el 2026-11-07. La ADR-016 permanece en el historial. La regla vigente es la de abajo.

Daniel pidió esta secuencia, para los cuatro canales:

1. El borrador no reserva.
2. La línea confirmada reserva sus componentes directos. En domicilio y recogida programados, la reserva ocurre al confirmar.
3. Enviar la comanda registra el envío a cocina y no consume los ingredientes por ese solo hecho.
4. Cuando la cocina inicia la preparación de una línea, esa cantidad se consume una sola vez.
5. Cancelar antes de la preparación libera la reserva.
6. Cancelar después de iniciar la preparación conserva el consumo ya hecho. La merma, si existe, sigue la regla `APPROVED` del apartado 3.6.

Cobrar no consume. Repetir la misma confirmación, el mismo inicio de preparación o la misma liberación no mueve el inventario dos veces.

La validación técnica de esta propuesta, y los puntos que todavía deben cerrarse antes de aprobarla, están en `TECHNICAL_ARCHITECTURE.md`.

El bloqueo sin disponible es independiente y ya está `APPROVED`: si la reserva o el consumo no alcanzan, la operación se detiene, salvo la excepción autorizada.

### 3.8 Domicilio todavía no despachado

Mientras la entrega no esté despachada se puede corregir la dirección, adicionar con una comanda nueva y cancelar según la regla de inventario. No se puede marcar entregado. Despachar es un hecho distinto de “listo en cocina”. Entregado es otro hecho distinto de despachado.

### 3.9 Recogida programada

El pedido guarda la fecha y hora prometidas desde la confirmación. Puede esperar sin comanda. El envío a cocina es una acción del equipo. El MVP no incluye un temporizador automático.

Si el cliente no llega, un usuario autorizado marca no presentado. El anticipo no se retiene automáticamente. Su resolución está `PENDING`: devolución, crédito a favor del cliente, retención solo cuando ya exista una política aplicable, o resolución excepcional documentada. Cualquiera de esas salidas escribe el movimiento financiero correspondiente. Ninguna se elige por defecto.

### 3.10 Pagos y turnos

Todo pago, anticipo, propina, gasto, devolución e ingreso manual exige un turno abierto y escribe un movimiento de ese turno. La propina viaja en movimiento propio, separada de la venta de alimentos.

La tarjeta y la transferencia del MVP las atestigua el cajero, con referencia externa. Eso no es una autorización de un banco ni de una pasarela. El efectivo queda confirmado al registrarse en el turno.

Si el turno del cobro original ya está cerrado, la devolución entra al turno abierto actual y referencia el movimiento original. Un turno cerrado no recibe líneas nuevas ni se reescribe.

### 3.11 Dos usuarios, un pedido

Cada pedido tiene versión. La transacción bloquea la fila del pedido. La escritura exige la versión que leyó el usuario. Si otro guardó antes, la operación responde conflicto y no fusiona cambios a ciegas. El cliente debe recargar.

### 3.12 Pedidos concurrentes y stock

Al reservar o consumir, la transacción bloquea los saldos en un orden fijo de identificador. El disponible se comprueba bajo ese bloqueo.

Regla `APPROVED`: si no hay disponible suficiente, la operación completa no se aplica. No queda una reserva ni un consumo a medias, y no aparece un negativo silencioso.

La excepción `APPROVED` permite continuar solo con usuario autorizado, PIN, motivo obligatorio, cantidad autorizada y auditoría. El faltante que esa excepción produzca queda visible en el kardex. Es el único camino hacia una existencia por debajo de cero.

## 4. Matriz de referencia FUDO

Fuente de la columna FUDO: páginas públicas consultadas el 2026-11-06. Estado de la implementación propuesta: **Propuesto**, salvo lo marcado como fuera de alcance.

| Funcionalidad de referencia | Implementación propuesta en El Patacón | Corte | Dependencias | Estado |
| --- | --- | --- | --- | --- |
| Venta de mostrador | Pedido `COUNTER` sobre el núcleo común | MVP | Carta, caja, pedido | Propuesto |
| Venta en mesa | Pedido `DINE_IN` ligado a una sesión de mesa | MVP | Pedido, salón | Propuesto |
| Pedido para llevar inmediato | Se atiende como `COUNTER` o `PICKUP` sin espera. El canal se elige al abrir | MVP | Pedido | Propuesto |
| Domicilio propio | Pedido `DELIVERY` con dirección, tarifa y estados de entrega | MVP | Cliente, pedido, comanda | Propuesto |
| Para recoger programado | Pedido `PICKUP` con hora prometida y reserva de stock | MVP | Cliente, inventario | Propuesto |
| Apps Rappi, Justo, DiDi | Mismo pedido, canal externo futuro. Sin conector | Posterior | Pedido estable y contrato con el tercero | Fuera del MVP |
| Tienda, QR, WhatsApp, Mercado Pago | No se construyen | Posterior | Canal y pasarela | Fuera del MVP |
| Categorías, favoritos, modificadores, variantes | Carta única para los cuatro canales | MVP | Identidad | Propuesto |
| Combos y listas de precios | Fuera del esquema del MVP | Posterior | Carta | Fuera del MVP |
| Recetas, costo y margen | Receta, subreceta, preparación con inventario propio y producción por lote. El plato descuenta la preparación | MVP | Inventario, carta | `APPROVED` |
| Stock, kardex, conteo, merma, mínimo | Libro de movimientos por sede | MVP | Unidades | Propuesto |
| Lotes y vencimiento | Reservado, sin tablas definitivas | Posterior | Kardex | Fuera del MVP |
| Gasto que actualiza stock | La recepción de compra actualiza stock y costo. El gasto operativo no | MVP | Inventario, caja si sale del turno | Propuesto |
| Recepción parcial | Cantidad pedida y cantidad recibida, sin reescribir la orden | MVP | Compras | Propuesto |
| Cuenta por pagar | Obligación al confirmar la recepción, abonos inmutables | MVP | Recepción | Propuesto |
| Clientes y cuenta corriente | Cliente y direcciones. El crédito a favor solo existe como salida posible de un anticipo | MVP el cliente. El crédito espera la política | Pedido | `PENDING` la política del anticipo |
| Arqueo y arqueo ciego | Una caja operativa. El esperado se calcula al cerrar | MVP | Turno | Propuesto |
| Varias cajas y turnos | Varias cajas en el modelo. Una en la operación inicial | MVP el modelo. Posterior la operación simultánea | Caja | Propuesto |
| Pagos mixtos, propina, descuento | Venta inmutable, propina separada, descuento con autorización | MVP | Caja, pedido | Propuesto |
| Cierre parcial de una cuenta | Varias ventas sobre un pedido | MVP | Venta | Propuesto |
| Usuarios, roles, PIN | Siete roles y PIN para descuento, anulación, merma y ajuste | MVP | Identidad | Propuesto |
| Mesas, plano, mesero, traslado | Sesión, ocupación, traslado y unión | MVP | Pedido | Propuesto |
| Varias cuentas por mesa | División del mismo pedido en varias ventas | MVP | Venta | Propuesto |
| Mapa de calor | Reporte posterior | Posterior | Historial de sesiones | Fuera del MVP |
| Impresión de comanda y precuenta | Cola digital en pantalla. Impresora en una fase posterior | MVP la cola. Posterior la impresora | Comanda | `APPROVED` la cola. Impresora fuera de esta construcción |
| Monitor de cocina avanzado | Comanda con estación. Pantalla de una cola. Sin estaciones en vivo | MVP la cola. Posterior el KDS | Comanda | Propuesto / fuera |
| Factura electrónica y nota crédito | Documento fiscal distinto de la venta, con aceptación explícita | Posterior | Venta inmutable, proveedor, resolución | Fuera del MVP |
| Reportes de venta, producto, pago, stock y gasto | Reportes de una sede, separando pedido, venta y consumo | MVP | Libros del MVP | Propuesto |
| Estado de resultados y Excel | Posterior, con más historia | Posterior | Reportes | Fuera del MVP |
| Multi-sede | `branch_id` en la operación. Pantallas de una sede | MVP el dato. Posterior el consolidado | Organización | Propuesto |
| Operar sin internet | UUID e idempotencia en el MVP. Cola y conflictos después | Posterior | Núcleo probado en línea | Fuera del MVP |

## 5. Reportes y lenguaje de cifras

| Cifra | Origen | Qué no debe incluir |
| --- | --- | --- |
| Venta cobrada | Ventas publicadas, menos anulaciones | Pedidos abiertos |
| Recaudo | Pagos del turno, por medio | Propina mezclada con alimentos |
| Propina | Movimientos de propina | Venta de alimentos |
| Consumo teórico | Movimientos de consumo al iniciar la preparación, si se aprueba la regla propuesta | Un segundo descuento al cobrar o al reenviar la comanda |
| Costo de lo cobrado | Costo congelado en las ventas publicadas | Pedidos enviados a cocina y aún no cobrados |
| Gasto | Gastos operativos y salidas de caja | Compras de insumo, que son inventario |
| Diferencia de caja | Esperado del turno contra conteo ciego | Un ajuste silencioso del efectivo |

El consumo por comandas puede ser mayor que el costo de lo cobrado cuando hay cuentas abiertas, mermas o cancelaciones ya preparadas. El reporte muestra las dos cifras.

## 6. Preguntas que siguen abiertas

Cerradas el 2026-11-07, y por eso salen de esta lista: el bloqueo sin stock, la cola digital, las preparaciones con inventario propio y la continuación del diseño mixto.

Siguen sin cerrar la construcción:

1. `PENDING`. El contador debe validar si el precio de carta incluye el impuesto, qué tasas aplican y si el comprobante interno sirve para la operación.
2. `PENDING`. Política del anticipo no recogido.
3. `PENDING`. Política de distribución de propinas.
4. `PENDING`. Cuántas cajas físicas hay. El número no se inventa.
5. Autorización expresa de la Fase 1. El plan está en `PHASE_1_EXECUTION_PLAN.md`.

Siguen abiertas, sin bloquear el dibujo del modelo: tope de descuento, si el cajero ve costos, lista real de insumos y diez recetas del restaurante, medios de pago efectivos y el lugar donde correrá el servidor.
