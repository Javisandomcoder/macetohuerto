[README.md](https://github.com/user-attachments/files/22573692/README.md)
# 🌱 Macetohuerto  

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter&logoColor=white)](https://flutter.dev/)  
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)  
[![Release](https://img.shields.io/github/v/release/Javisandomcoder/macetohuerto?label=última%20versión&color=brightgreen)](https://github.com/Javisandomcoder/macetohuerto/releases/latest)  
[![Stars](https://img.shields.io/github/stars/Javisandomcoder/macetohuerto?style=social)](https://github.com/Javisandomcoder/macetohuerto/stargazers)  

**Macetohuerto** es una aplicación móvil desarrollada en **Flutter** para gestionar de forma sencilla el cuidado de plantas y pequeños huertos urbanos.  

---

## ✨ Características principales  
- 🪴 Registro de plantas con **nombre, especie, ubicación, fecha de plantación y notas**.  
- 📋 Vista en **lista** y **detalle** para cada planta.  
- 📝 **Bitácora** básica de notas por planta.  
- 💾 Persistencia local usando *SharedPreferences*.  
- ⏰ **Recordatorios de riego** con notificaciones programadas.  

---

## 🚀 Hoja de ruta próxima  
- 🔔 Recordatorios adicionales (abonado, trasplantes).  
- 📸 Añadir fotos a la ficha de cada planta.  
- 📊 Gráficas de evolución y cuidados.  
- 🌡️ Integración con sensores (**ESP32 vía MQTT**) para humedad, temperatura y luz.  

---

## 📥 Instalación de la APK  
1. Visita la sección de 👉 [**Releases en GitHub**](https://github.com/Javisandomcoder/macetohuerto/releases/latest).  
2. 📂 Descarga la APK correspondiente a la arquitectura de tu dispositivo (**arm64-v8a** es la más común).  
3. 📲 Copia el archivo al teléfono (si lo descargaste en otro equipo) y ábrelo.  
4. 🔓 Permite la instalación de aplicaciones desde **orígenes desconocidos** cuando Android lo solicite.  
5. 🔔 Al iniciar la app, otorga el **permiso de notificaciones** para recibir recordatorios.  

💡 **Tip**: Si las notificaciones no suenan, comprueba en  
**Ajustes > Aplicaciones > Macetohuerto > Notificaciones** que estén activadas.  

---

## 🛠️ Construir desde el código fuente  
```bash
flutter pub get  
flutter build apk --release --split-per-abi
```  
Las APK generadas se guardarán en:  
```
build/app/outputs/flutter-apk/
```  

---

## 🤝 Contribuir  
Los *issues* y *pull requests* son bienvenidos en la rama **development**.  

👉 Puedes empezar aquí: [**Contribuciones**](https://github.com/Javisandomcoder/macetohuerto/issues)  

---

## 📄 Licencia  
Este proyecto se distribuye bajo la licencia **MIT**.  
