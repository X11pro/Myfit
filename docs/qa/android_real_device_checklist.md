# Android Real Device QA Checklist

Estado de la ejecucion: todas las verificaciones fueron aprobadas en `SM S916B` con Android 16 y una build debug configurada contra Supabase.

## Auth

- [x] pedir OTP
- [x] verificar codigo
- [x] cerrar y reabrir app
- [x] confirmar sesion persistente
- [x] sign out

## Meals

- [x] meal manual sin foto
- [x] meal manual con foto
- [x] gallery con foto
- [x] editar meal: peso e ingredientes, con recálculo y reanálisis IA
- [x] borrar meal individual

## Barcode

- [x] scan real con preview de cámara y autocompletado
- [x] lookup manual
- [x] no match
- [x] sin internet

## AI photo

- [x] foto real
- [x] `Analyze with AI`
- [x] error de backend controlado

## Workout

- [x] guardar workout
- [x] editar/borrar
- [x] timers
- [x] sonido/vibracion REST

## Persistencia

- [x] verificar sync remoto de meals, photos, weight y workouts
- [x] reinstalar y comprobar rehidratacion

## Datos de cuenta

- [x] exportar datos remotos
- [x] borrar datos remotos y confirmar que no rehidratan
