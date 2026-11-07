import { canonicalHash } from './canonical';
import { assertLocalTenderStatus, LocalTenderStatusError } from './tender-status';

describe('idempotencia y estado local', () => {
  it('el mismo cuerpo produce el mismo hash aunque cambie el orden de las claves', () => {
    const left = canonicalHash({ appliedMinor: 10, method: 'CASH' });
    const right = canonicalHash({ method: 'CASH', appliedMinor: 10 });
    expect(left).toBe(right);
  });

  it('un cuerpo distinto produce otro hash', () => {
    expect(canonicalHash({ appliedMinor: 10 })).not.toBe(
      canonicalHash({ appliedMinor: 11 }),
    );
  });

  it('el efectivo no acepta UNKNOWN', () => {
    expect(() => assertLocalTenderStatus('CASH', 'UNKNOWN')).toThrow(
      LocalTenderStatusError,
    );
    expect(() => assertLocalTenderStatus('CARD', 'UNKNOWN')).toThrow(
      LocalTenderStatusError,
    );
    expect(() => assertLocalTenderStatus('CASH', 'SUCCEEDED')).not.toThrow();
  });
});
