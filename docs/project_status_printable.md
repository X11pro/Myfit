# Myfit - Estado del proyecto

## Listo ahora

- app Flutter base multiscaffold
- dark mode fijo
- ingles por defecto
- selector `EN / ESP` en welcome
- welcome usable sin login obligatorio
- onboarding basico
- guest profile local persistido
- dashboard base
- manual food entry local en memoria
- totales basicos en dashboard:
  - calories
  - protein
- proyecto real de Supabase conectado
- migracion inicial aplicada
- esquema base + RLS ya creados
- auth OTP validado tecnicamente contra Supabase, aunque hoy quedo fuera del flujo principal

## Parcialmente listo

- autenticacion:
  - backend y pruebas tecnicas existen
  - pero la UX principal quedo desactivada temporalmente
- onboarding:
  - ya guarda perfil guest local
  - tambien tenia soporte para guardar remoto con sesion
  - pero ahora no esta siendo el camino principal
- manual food tracking:
  - UI y estado local existen
  - falta persistencia local durable
  - falta persistencia remota

## Todavia por desarrollar del producto principal

- persistencia local de comidas manuales
- persistencia remota de comidas en `meal_entries`
- busqueda nutricional real
- barcode scan
- food photo upload
- AI food estimation
- confidence score + confirmacion de porcion
- daily dashboard real con:
  - calories in
  - protein
  - sugar
  - energy balance
- daily summary calculado
- workout import
- Health Connect Android
- HealthKit iOS
- manual gym workout tracking
- work/NEAT energy estimation
- coach summary
- supplement guidance
- export/delete data flows
- package name Android real
- iOS bundle identifier real
- UX final segun Figma

## Estado estrategico real

Hoy la app ya sirve como base navegable y editable para producto, pero todavia no es el MVP funcional completo.

## Siguiente orden recomendado

1. persistir comidas manuales localmente
2. reconectar identidad/auth sin romper guest UX
3. guardar comidas remotas en `meal_entries`
4. mejorar dashboard diario real
5. nutricion lookup
6. barcode
7. foto + IA
