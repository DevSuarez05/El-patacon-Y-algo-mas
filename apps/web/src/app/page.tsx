'use client';

import { FormEvent, useState } from 'react';
import { sessionLabel } from '../lib/session-label';

const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001';

export default function HomePage() {
  const [message, setMessage] = useState('Ingresa con el administrador de desarrollo.');
  const [branchId, setBranchId] = useState('');

  async function onSubmit(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const response = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email: String(form.get('email') ?? ''),
        password: String(form.get('password') ?? ''),
        branchId: String(form.get('branchId') ?? ''),
      }),
    });
    setMessage(sessionLabel(response.ok));
    if (response.ok) {
      const body = (await response.json()) as { branchId: string; token: string };
      setBranchId(body.branchId);
      window.sessionStorage.setItem('patacon.token', body.token);
    }
  }

  return (
    <main>
      <h1>El Patacón – Y algo más</h1>
      <p>Acceso de la Fase 1. No hay punto de venta ni cobro al público.</p>
      <form onSubmit={onSubmit}>
        <label>
          Correo
          <input name="email" type="email" required />
        </label>
        <label>
          Contraseña
          <input name="password" type="password" required minLength={8} />
        </label>
        <label>
          Sede
          <input name="branchId" required />
        </label>
        <button type="submit">Entrar</button>
      </form>
      <p>{message}</p>
      {branchId ? <p>Sede de la sesión: {branchId}</p> : null}
    </main>
  );
}
