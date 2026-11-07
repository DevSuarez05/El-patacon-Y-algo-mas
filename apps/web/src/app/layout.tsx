import type { ReactNode } from 'react';

export const metadata = {
  title: 'El Patacón – Y algo más',
  description: 'Acceso de desarrollo. Sin punto de venta.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="es">
      <body style={{ fontFamily: 'sans-serif', margin: '2rem' }}>{children}</body>
    </html>
  );
}
