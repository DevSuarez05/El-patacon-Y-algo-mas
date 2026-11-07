export type Dimension = 'MASS' | 'VOLUME' | 'COUNT';

export class QuantityError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'QuantityError';
  }
}

export interface UnitRef {
  code: string;
  dimension: Dimension;
}

const SCALE = 1_000_000n;

function parseScaled(value: string): bigint {
  if (!/^\d+(\.\d{1,6})?$/.test(value)) {
    throw new QuantityError('la cantidad debe ser un decimal positivo de hasta 6 decimales');
  }
  const [whole, fraction = ''] = value.split('.');
  const padded = (fraction + '000000').slice(0, 6);
  return BigInt(whole) * SCALE + BigInt(padded);
}

function formatScaled(value: bigint): string {
  const whole = value / SCALE;
  const fraction = (value % SCALE).toString().padStart(6, '0').replace(/0+$/, '');
  return fraction.length === 0 ? whole.toString() : `${whole.toString()}.${fraction}`;
}

export function convertQuantity(
  quantity: string,
  from: UnitRef,
  to: UnitRef,
  factor: string,
): string {
  if (from.dimension !== to.dimension) {
    throw new QuantityError(
      `no se convierte ${from.dimension} a ${to.dimension}`,
    );
  }
  const scaled = parseScaled(quantity);
  const factorScaled = parseScaled(factor);
  return formatScaled((scaled * factorScaled) / SCALE);
}
