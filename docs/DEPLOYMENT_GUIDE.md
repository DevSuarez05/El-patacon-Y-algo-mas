# Guía de despliegue

Estado: **Propuesto**. Fecha: 2026-11-06.

No hay aplicación, imagen, servidor ni base de datos. Nada se ha desplegado. Este documento evita describir un procedimiento imaginario como si ya funcionara.

## 1. Entorno previsto para desarrollar

Cuando la Fase 1 esté aprobada y el esqueleto exista, el desarrollo local debe quedar así:

- Docker Compose levanta PostgreSQL, con volumen para no perder los datos de prueba entre reinicios.
- La API lee la cadena de conexión y el secreto de sesión desde variables de entorno.
- Existe un archivo de ejemplo sin secretos.
- El frontend apunta a la API local por variable de entorno.
- Las migraciones Prisma se ejecutan de forma explícita. La aplicación no altera el esquema por accidente al arrancar en un entorno compartido.
- Una semilla local crea organización, sede, roles y un administrador. Esa semilla no se usa en un entorno con datos reales.

Esas instrucciones se completarán con comandos reales en el momento en que esos archivos existan y se hayan ejecutado.

## 2. Entorno del restaurante

Pendiente de la pregunta de alojamiento. Hay dos opciones válidas y todavía no hay recomendación cerrada:

| Opción | Cuándo encaja | Riesgo principal |
| --- | --- | --- |
| Computador o mini servidor en el restaurante | El internet es inestable y el Corte 4 todavía no existe. La caja habla con un servidor en la red local | Alguien tiene que respaldar ese disco, reiniciar el servicio y proteger el equipo |
| Nube | El internet del local es estable y se quiere entrar desde fuera | Sin internet, el MVP se detiene. Hay costo mensual y responsabilidad de acceso |

La elección afecta el modo offline y los backups. No se elige por preferencia de la pila.

## 3. Backups

Desde el primer entorno que guarde datos reales:

- Copia de PostgreSQL al menos diaria, en otro disco u otro servicio.
- Un ensayo de restauración documentado antes de llamar al sistema listo para producción.
- Los archivos de certificado y la resolución de facturación, cuando existan, se respaldan aparte del código.

Hoy no hay copias porque no hay base.

## 4. Secretos

Contraseñas de base, secreto de sesión, PIN de semilla, llaves del proveedor tecnológico y certificados permanecen fuera de Git. El certificado de firma digital no se copia al repositorio ni a un log.

## 5. Lista de salida a producción

El sistema no se considera listo para producción por existir un despliegue. Hará falta, como mínimo:

- MVP mixto probado con los casos de `TESTING_STRATEGY.md`.
- Restauración de backup ensayada.
- Usuarios reales con sus roles, semilla de administrador desactivada o rotada.
- Tasas tributarias cargadas por indicación del contador, o emisión fiscal explícitamente apagada y comprendida por el negocio.
- Carta, insumos y recetas revisados por el restaurante.
- Un turno de prueba con datos reales controlados, y un turno siguiente ya en operación, con alguien responsable del cierre.

Hasta entonces el estado de despliegue permanece en no iniciado.

## 6. Observabilidad del primer entorno real

Logs JSON de la API, hora UTC, identificador de petición. Revisión manual al principio. El tablero de métricas y el rastreador de errores se evalúan en el Corte 4, cuando haya tráfico de servicio que observar.
