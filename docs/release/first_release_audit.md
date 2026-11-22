# Auditoría previa a la primera publicación

## Duplicados corregidos

- **Home:** se retiraron las tarjetas antiguas sin uso y la línea de proteína que repetía el mismo valor del resumen. El botón principal inicia la sesión; la tarjeta de entrenamiento abre una sesión existente.
- **Navegación:** la pestaña inferior es el acceso común a Progress. Se conservaron los accesos contextuales que cumplen otra función, como editar una sesión desde Home o abrir los gráficos detallados.
- **Progress:** un solo botón de exportación CSV. Home y Progress abren el mismo formulario de peso, con validación de valores finitos y positivos y una entrada por fecha. Los gráficos detallados se conservan: permiten seleccionar métricas y series que no ofrece el resumen.
- **Nutrición:** el escaneo se inicia desde **Barcode** de registro rápido, no desde un segundo icono dentro de la búsqueda del diario. Daily Meals conserva un único panel seleccionado; diario y galería usan el mismo detalle de comida. La confirmación de foto y el formulario manual usan un único guardado protegido contra doble pulsación.
- **Guardado:** una comida nueva y su foto remota reusan identificadores estables al reintentar en el mismo formulario. No se deduplican comidas distintas por nombre o contenido. Los controles de sesiones, series y rutina semanal siguen preservando registros intencionales.

## Verificación local

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: 44 pruebas, incluidos el doble toque en Guardar comida, los reintentos y las rutas en inglés y español.
- `flutter test --no-pub tool/stitch/*test.dart`: 6 recorridos de interfaz con datos de prueba.
- `git diff --check` y validación del `Info.plist` de iOS correctos.

## iPhone físico

Build **Release 0.1.0 (1)** construida en una copia temporal de la Mac mini. `devicectl` confirmó la actualización y la apertura de **Fitness App** en el iPhone 16 físico. Se actualizó sobre la app existente, sin desinstalar ni limpiar sus datos. La apertura es la comprobación realizada en el iPhone; los recorridos de UI se ejecutaron con datos de prueba.

## Galaxy S23+

La misma revisión se compiló como APK de prueba ARM64 y se firmó en la PC con el certificado que ya usaba la app instalada. `adb install -r` y el arranque en frío de Myfit por USB se completaron correctamente, sin desinstalar ni limpiar los datos. La APK de prueba no es una build de distribución de Google Play.

## Antes de publicar

Una build de desarrollo en configuración Release instalada en un iPhone no sustituye una validación de App Store/TestFlight. Quedan por comprobar con una cuenta de QA: OTP, cierre y reapertura con datos remotos, sincronización de rutinas, cámara/lector de códigos, análisis real de fotos y exportación/borrado de cuenta. Tampoco se verificó la reconciliación de borradores de invitado con una cuenta que ya tiene datos ni la recuperación de escrituras remotas parciales con varios dispositivos. No se borraron ni se probaron escrituras sobre registros reales del usuario.

Cerrar además la política pública de privacidad, el canal de soporte de datos y la configuración y firma de distribución. El identificador iOS de esta build sigue siendo `com.example.fitnessApp`; se conservó para actualizar la instalación existente.
