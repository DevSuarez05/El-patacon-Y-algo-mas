# El Patacón – Y algo más

Fase 1 autorizada: monorepo, PostgreSQL, migraciones 001–014, dinero, identidad y una semilla de desarrollo. No hay punto de venta, cobro al público ni tasas fiscales.

## Requisitos

- Node.js 22 o superior. Esta máquina usó la versión instalada, que puede ser posterior a la 22.
- pnpm 9 mediante Corepack: `corepack pnpm`
- Docker, con el daemon en ejecución

## Arranque local

```powershell
Copy-Item .env.example .env
# Define SEED_ADMIN_PASSWORD en .env. No la dejes vacía. No es un secreto de producción.
corepack pnpm install
docker compose up -d
corepack pnpm --filter money build
corepack pnpm --filter api prisma:deploy
corepack pnpm --filter api prisma:seed
corepack pnpm --filter api start:dev
corepack pnpm --filter web dev
```

La API queda en `http://localhost:3001` y la documentación en `http://localhost:3001/docs`. El web queda en `http://localhost:3000`.

## Pruebas

```powershell
corepack pnpm --filter money test
corepack pnpm --filter money build
corepack pnpm --filter api test
corepack pnpm --filter web test
```

## Reversión de desarrollo

No hay datos reales. Para volver a una base vacía se elimina el volumen y se aplican otra vez las migraciones:

```powershell
docker compose down -v
docker compose up -d
corepack pnpm --filter api prisma:deploy
corepack pnpm --filter api prisma:seed
```

`prisma migrate resolve` no deshace tablas. Una migración ya aplicada se corrige con una migración nueva.
