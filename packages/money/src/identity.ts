export class MoneyIdentityError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MoneyIdentityError';
  }
}

export interface MoneySplit {
  tenderedMinor: bigint;
  appliedMinor: bigint;
  tipMinor: bigint;
  changeMinor: bigint;
}

function asNonNegative(name: string, value: bigint): bigint {
  if (value < 0n) {
    throw new MoneyIdentityError(`${name} no puede ser negativo`);
  }
  return value;
}

/** recibido = aplicado + propina + vuelto. La propina no entra en el total de la venta. */
export function assertMoneyIdentity(split: MoneySplit): MoneySplit {
  const tenderedMinor = asNonNegative('recibido', split.tenderedMinor);
  const appliedMinor = asNonNegative('aplicado', split.appliedMinor);
  const tipMinor = asNonNegative('propina', split.tipMinor);
  const changeMinor = asNonNegative('vuelto', split.changeMinor);
  if (tenderedMinor !== appliedMinor + tipMinor + changeMinor) {
    throw new MoneyIdentityError(
      'recibido debe ser igual a aplicado + propina + vuelto',
    );
  }
  return { tenderedMinor, appliedMinor, tipMinor, changeMinor };
}

/** Redondeo half away from zero sobre un entero ya expresado en centavos. */
export function roundHalfAwayFromZero(value: bigint, divisor: bigint): bigint {
  if (divisor <= 0n) {
    throw new MoneyIdentityError('el divisor debe ser positivo');
  }
  const negative = value < 0n;
  const absolute = negative ? -value : value;
  const quotient = absolute / divisor;
  const remainder = absolute % divisor;
  const rounded = remainder * 2n >= divisor ? quotient + 1n : quotient;
  return negative ? -rounded : rounded;
}

export function splitMinor(totalMinor: bigint, parts: number): bigint[] {
  if (!Number.isInteger(parts) || parts <= 0) {
    throw new MoneyIdentityError('la cantidad de partes debe ser un entero positivo');
  }
  if (totalMinor < 0n) {
    throw new MoneyIdentityError('el total no puede ser negativo');
  }
  const divisor = BigInt(parts);
  const base = totalMinor / divisor;
  let remainder = totalMinor % divisor;
  const result: bigint[] = [];
  for (let index = 0; index < parts; index += 1) {
    const extra = remainder > 0n ? 1n : 0n;
    result.push(base + extra);
    if (remainder > 0n) {
      remainder -= 1n;
    }
  }
  return result;
}
