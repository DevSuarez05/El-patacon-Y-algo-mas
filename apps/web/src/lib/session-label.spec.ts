import { describe, expect, it } from 'vitest';
import { sessionLabel } from './session-label';

describe('sesión', () => {
  it('describe el resultado sin hablar de un banco', () => {
    expect(sessionLabel(true)).toBe('Sesión iniciada en esta sede.');
    expect(sessionLabel(false)).not.toMatch(/banco/i);
  });
});
