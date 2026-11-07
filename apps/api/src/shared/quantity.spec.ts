import { convertQuantity, QuantityError } from './quantity';

describe('cantidades', () => {
  it('convierte gramos a kilogramos', () => {
    expect(
      convertQuantity(
        '1500',
        { code: 'g', dimension: 'MASS' },
        { code: 'kg', dimension: 'MASS' },
        '0.001',
      ),
    ).toBe('1.5');
  });

  it('rechaza masa contra volumen', () => {
    expect(() =>
      convertQuantity(
        '1',
        { code: 'kg', dimension: 'MASS' },
        { code: 'l', dimension: 'VOLUME' },
        '1',
      ),
    ).toThrow(QuantityError);
  });
});
