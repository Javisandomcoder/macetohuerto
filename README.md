# Macetohuerto

Macetohuerto es una aplicacion movil desarrollada en Flutter para gestionar de forma sencilla el cuidado de plantas y pequenos huertos urbanos.

## Caracteristicas principales
- Registro de plantas con nombre, especie, ubicacion, fecha de plantacion y notas.
- Vista en lista y detalle para cada planta.
- Bitacora basica de notas por planta.
- Persistencia local usando SharedPreferences.
- Recordatorios locales de riego con notificaciones programadas.

## Hoja de ruta proxima
- Recordatorios adicionales (abonado, trasplantes).
- Anadir fotos a la ficha de cada planta.
- Graficas de evolucion y cuidados.
- Integracion con sensores (ESP32 via MQTT) para humedad, temperatura y luz.

## Instalacion de la APK
1. Visita la seccion de **Releases** en GitHub: https://github.com/Javisandomcoder/macetohuerto/releases/latest.
2. Descarga la APK correspondiente a la arquitectura de tu dispositivo (rm64-v8a es la mas comun).
3. Copia el archivo al telefono (si lo descargaste en otro equipo) y abrelo.
4. Permite la instalacion de aplicaciones desde origen desconocido cuando Android lo solicite.
5. Al iniciar la app, otorga el permiso de notificaciones para recibir los recordatorios.

> Tip: Si las notificaciones no suenan, comprueba en Ajustes > Aplicaciones > Macetohuerto > Notificaciones que esten activadas.

## Construir desde el codigo fuente
`bash
flutter pub get
flutter build apk --release --split-per-abi
`
Las APK generadas se guardaran en uild/app/outputs/flutter-apk/.

## Contribuir
Los issues y pull requests son bienvenidos en la rama development.

## Licencia
Este proyecto se distribuye bajo la licencia MIT.
