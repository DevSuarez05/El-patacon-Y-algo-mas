# Estrategia de pruebas

Estado: **Propuesto**, con nota de vigencia del 2026-11-07.

No hay suite ni resultados. Nada está probado.

Nota de vigencia: las viñetas que dicen que enviar la comanda descuenta inventario, o que el envío convierte la reserva, quedaron superadas por `INVENTORY_RULES.md`. Se conservan como historial de la revisión del 2026-11-06. No se usan como criterios de la Fase 1.

## 1. Invariantes del núcleo mixto

- Crear un pedido en cualquiera de los cuatro canales no inserta venta, pago ni movimiento de consumo.
- Enviar una comanda descuenta la explosión de receta y modificadores una sola vez.
- Repetir esa llave no descuenta otra vez.
- Publicar la venta no inserta consumo.
- Una adición descuenta solo las líneas nuevas.
- Una reserva de recogida baja el disponible y no la existencia. El envío convierte esa reserva en un movimiento.
- Cancelar antes del envío libera la reserva. Cancelar después escribe un reverso o una merma, con autorización cuando ya se preparó.
- Dos envíos concurrentes del mismo insumo conservan ambos movimientos o uno falla de forma íntegra.
- Dos ediciones concurrentes del mismo pedido: una aplica y la otra recibe conflicto de versión.
- Dividir una mesa crea varias ventas y ninguna comanda duplicada. La suma de las partes iguales cuadra al centavo.
- Trasladar y unir conservan el identificador del pedido y de las comandas.
- Un domicilio en estado listo no queda entregado.
- No se puede completar un domicilio sin haberlo despachado.
- No se cierra una mesa con saldo o con líneas activas sin liquidar.
- No se registra un pago sin turno abierto.
- Una devolución con el turno original cerrado escribe en el turno abierto y guarda la referencia.
- El conteo ciego no recibe el efectivo esperado.
- Una venta anulada sale de las ventas vigentes y permanece en el historial.
- El reporte de ventas por canal usa ventas publicadas. El reporte de consumo usa el kardex.

## 2. Niveles

| Nivel | Herramienta | Inicio | Cobertura |
| --- | --- | --- | --- |
| Dominio | Jest | Fase 1 | Dinero, redondeo de la división, explosión, estados |
| Integración con PostgreSQL | Jest | MVP | Comanda, reserva, venta, caja, concurrencia |
| API | Supertest | Con cada comando | Zod, versión, permisos, idempotencia |
| Interfaz | Playwright | Cuando exista el flujo | Abrir mesa, enviar, dividir, cobrar, cerrar turno |
| Servicio de ensayo | Guion con datos de prueba | Antes de un servicio real | Los cuatro canales en un mismo día de prueba |

Las pruebas de comanda, venta y caja usan PostgreSQL real. Un doble consumo que solo existe por una restricción ausente no aparece con la base simulada.

## 3. Datos y definición de probado

Los fixtures se reconocen como prueba. No representan la carta ni los proveedores reales.

Un módulo pasa a **Probado** cuando sus invariantes se ejecutaron, el comando quedó anotado en `CHANGELOG.md` y los casos de reintento, permiso denegado y conflicto de versión están cubiertos si el módulo mueve dinero o stock. Compilar no cuenta como prueba.

## 4. Fuera del MVP

Impresoras, DIAN, pasarela, varias pantallas de cocina y corte de internet. Esas pruebas se escriben con su módulo.
