import { Algorithm, hash, verify } from '@node-rs/argon2';

const options = {
  algorithm: Algorithm.Argon2id,
  memoryCost: 19456,
  timeCost: 2,
  parallelism: 1,
} as const;

export function hashSecret(value: string): Promise<string> {
  return hash(value, options);
}

export function verifySecret(value: string, hashed: string): Promise<boolean> {
  return verify(hashed, value, options);
}
