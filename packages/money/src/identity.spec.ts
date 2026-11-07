import {
  assertMoneyIdentity,
  MoneyIdentityError,
  roundHalfAwayFromZero,
  splitMinor,
} from './identity';

describe('identidad de dinero', () => {
  it('acepta recibido = aplicado + propina + vuelto', () => {
    const split = assertMoneyIdentity({
      tenderedMinor: 50000n,
      appliedMinor: 32000n,
      tipMinor: 3000n,
      changeMinor: 15000n,
    });
    expect(split.tenderedMinor).toBe(50000n);
  });

  it('rechaza una propina metida de más en el recibido', () => {
    expect(() =>
      assertMoneyIdentity({
        tenderedMinor: 1000n,
        appliedMinor: 1000n,
        tipMinor: 100n,
        changeMinor: 0n,
      }),
    ).toThrow(MoneyIdentityError);
  });

  it('rechaza montos negativos', () => {
    expect(() =>
      assertMoneyIdentity({
        tenderedMinor: 0n,
        appliedMinor: 0n,
        tipMinor: -1n,
        changeMinor: 1n,
      }),
    ).toThrow(MoneyIdentityError);
  });

  it('redondea half away from zero y reparte sin perder centavos', () => {
    expect(roundHalfAwayFromZero(5n, 2n)).toBe(3n);
    expect(roundHalfAwayFromZero(-5n, 2n)).toBe(-3n);
    const parts = splitMinor(100n, 3);
    expect(parts).toEqual([34n, 33n, 33n]);
    expect(parts.reduce((sum, part) => sum + part, 0n)).toBe(100n);
  });
});
