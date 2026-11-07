import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

export function configureApp(app: INestApplication): void {
  app.enableCors({
    origin: process.env.WEB_ORIGIN ?? 'http://localhost:3000',
  });
  const config = new DocumentBuilder()
    .setTitle('El Patacón – Y algo más')
    .setDescription(
      'Fase 1. Identidad y cimiento. No cobra al público y no confirma operaciones con un banco.',
    )
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, config));
}
