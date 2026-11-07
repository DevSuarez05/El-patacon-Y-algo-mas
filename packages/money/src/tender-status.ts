export type TenderMethod = 'CASH' | 'CARD' | 'TRANSFER';

export type PaymentStatus =
  | 'PENDING'
  | 'PROCESSING'
  | 'SUCCEEDED'
  | 'FAILED'
  | 'UNKNOWN';

export class LocalTenderStatusError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LocalTenderStatusError';
  }
}

/**
 * El efectivo del MVP no usa UNKNOWN.
 * Tarjeta y transferencia sin proveedor tampoco: el cajero las atestigua en local.
 * UNKNOWN queda reservado a un proveedor externo, que esta fase no conecta.
 */
export function assertLocalTenderStatus(
  method: TenderMethod,
  status: PaymentStatus,
): void {
  if (status === 'UNKNOWN') {
    throw new LocalTenderStatusError(
      `${method} local no puede quedar UNKNOWN. Ese estado es solo de un proveedor externo.`,
    );
  }
}

export const LOCAL_CARD_TRANSFER_LABEL =
  'Registro local atestiguado por el cajero.';
