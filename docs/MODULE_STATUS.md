# Estado de módulos

Revisión: 2026-11-07.

| Dimensión | Estado |
| --- | --- |
| Fase 0 | `APPROVED` |
| Modelo técnico | `APPROVED` |
| Fase 1 | `AUTHORIZED`. Cimiento implementado y probado |
| Código | Monorepo, migraciones 001–014, dinero, identidad y login |

| Módulo | Alcance | Estado del diseño | Notas |
| --- | --- | --- | --- |
| Organización, sede, caja y estación | MVP | `APPROVED` | Cantidad real de cajas `PENDING` |
| Identidad, roles, PIN y auditoría | MVP | `APPROVED` | |
| Carta y precios | MVP | `APPROVED` | Impuesto del precio `PENDING` |
| Inventario, reserva y kardex | MVP | `APPROVED` | Alertas de reserva. Sin liberación automática |
| Recetas, preparaciones y producción | MVP | `APPROVED` | |
| Compras, obligaciones y gastos | MVP | `APPROVED` | |
| Pedidos de los cuatro canales | MVP | `APPROVED` | Un solo módulo |
| Clientes y direcciones | MVP | `APPROVED` | Sin cuenta corriente |
| Salón | MVP | `APPROVED` | |
| Comanda de cola única | MVP | `APPROVED` | Impresora fuera |
| Ventas y anulaciones | MVP | `APPROVED` | Sin propina en el total |
| Pagos, anticipos y propinas | MVP | `APPROVED` el dinero. Reparto y no-show `PENDING` | Tarjeta local ≠ banco |
| Caja y arqueo | MVP | `APPROVED` | Por medio |
| Reportes de una sede | MVP | `APPROVED` el diseño | |
| Impresión, KDS avanzado, DIAN, apps, offline | Posterior | Fuera | |

## Frente actual

El cimiento de la Fase 1 está en el repositorio. Los flujos de pedido, cocina, cobro y consumo no se han construido. Las políticas `PENDING` siguen sin inventarse.
