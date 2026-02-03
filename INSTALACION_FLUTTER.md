# 📥 Guía de Instalación de Flutter (Manual)

## Paso 1: Descargar Flutter

1. Abre tu navegador y ve a: **https://docs.flutter.dev/get-started/install/windows**
2. Haz clic en el botón azul "Download Flutter SDK"
3. Descarga el archivo ZIP (flutter_windows_xxx.zip)

## Paso 2: Extraer Flutter

1. Crea la carpeta: `C:\src` (si no existe)
2. Extrae el ZIP en `C:\src\flutter`
3. La ruta final debe ser: `C:\src\flutter\bin\flutter.bat`

## Paso 3: Agregar al PATH

### Opción A: Interfaz gráfica

1. Presiona `Windows + R` y escribe: `sysdm.cpl`
2. Ve a la pestaña "Opciones avanzadas"
3. Haz clic en "Variables de entorno"
4. En "Variables del sistema", busca "Path" y haz doble clic
5. Haz clic en "Nuevo"
6. Agrega: `C:\src\flutter\bin`
7. Haz clic en "Aceptar" en todas las ventanas

### Opción B: PowerShell (Administrador)

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")
```

## Paso 4: Verificar instalación

Cierra y abre una nueva terminal PowerShell o CMD, luego ejecuta:

```bash
flutter --version
flutter doctor
```

## Paso 5: Ejecutar la app

```bash
cd "C:\Users\Joel\Desktop\AppCOmpras"
flutter pub get
flutter run
```

---

## ⚡ Atajo rápido con PowerShell

Si prefieres, copia y pega este comando en PowerShell (Administrador):

```powershell
# Descargar Flutter
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
$zipPath = "$env:USERPROFILE\Downloads\flutter.zip"
Invoke-WebRequest -Uri $flutterUrl -OutFile $zipPath

# Crear directorio y extraer
New-Item -ItemType Directory -Force -Path "C:\src"
Expand-Archive -Path $zipPath -DestinationPath "C:\src" -Force

# Agregar al PATH
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")

# Limpiar
Remove-Item $zipPath

Write-Host "¡Flutter instalado! Cierra y abre una nueva terminal para usar Flutter."
```

---

## 🔧 Requisitos adicionales

Flutter necesita:

- **Git**: https://git-scm.com/download/win
- **Android Studio** (para apps Android): https://developer.android.com/studio
- **Visual Studio** (para apps Windows): https://visualstudio.microsoft.com/

Ejecuta `flutter doctor` para ver qué falta.
