# 🇮🇹 Login con CIE - Flutter Cross-Platform

App Flutter per l'autenticazione con Carta d'Identità Elettronica (CIE) che funziona sia su **Android** che **iOS**.

## 🪟 Sviluppo su Windows

### ✅ Cosa puoi fare su Windows

| Attività | Possibile su Windows |
|----------|---------------------|
| Sviluppare codice Flutter/Dart | ✅ Sì |
| Testare su Android (emulatore) | ✅ Sì |
| Testare su Android (device fisico) | ✅ Sì |
| Build APK/AAB per Android | ✅ Sì |
| Sviluppare codice iOS | ✅ Sì |
| Testare/Build per iOS | ❌ No (richiede Mac) |

### 🚀 Setup su Windows

```powershell
# 1. Installa Flutter (se non l'hai già fatto)
# Scarica da: https://docs.flutter.dev/get-started/install/windows

# 2. Verifica l'installazione
flutter doctor

# 3. Clona/copia questo progetto
cd cie_login_flutter

# 4. Installa le dipendenze
flutter pub get

# 5. Esegui su Android
flutter run
```

### 📱 Testare su Android

```powershell
# Con emulatore
flutter emulators --launch <emulator_id>
flutter run

# Con device USB
flutter devices
flutter run -d <device_id>
```

### 🍎 Per compilare iOS (richiede Mac)

**Opzione 1: Usa un Mac**
- Copia il progetto su Mac
- Apri terminale nella cartella del progetto
- Esegui `flutter build ios`

**Opzione 2: Servizi Cloud**
- [Codemagic](https://codemagic.io/) - CI/CD per Flutter
- [GitHub Actions](https://github.com/features/actions) - con macOS runner
- [Bitrise](https://bitrise.io/) - CI/CD mobile

**Opzione 3: MacInCloud / MacStadium**
- Noleggia un Mac virtuale online

---

## 📋 Prerequisiti

### Per lo Sviluppatore
- Flutter SDK >= 3.0.0
- Android Studio (per Android)
- Xcode (solo su Mac, per iOS)
- **Service Provider federato AGID**

### Per l'Utente Finale
- Smartphone Android 6.0+ o iPhone 7+
- CIE 3.0 con PIN attivo
- App CieID installata

---

## ⚙️ Configurazione

### 1. Registrazione come Service Provider

**⚠️ IMPORTANTE**: Per usare "Entra con CIE" devi essere un Service Provider federato.

1. Vai su [developers.italia.it/it/cie/](https://developers.italia.it/it/cie/)
2. Registra la tua organizzazione
3. Ottieni l'URL del Service Provider
4. Integra il pulsante sul tuo backend

📖 [Guida completa Service Provider](https://www.cartaidentita.interno.gov.it/CIE3.0-ManualeSP.pdf)

### 2. Configura l'URL del Service Provider

Modifica `lib/services/cie_auth_service.dart`:

```dart
class CieConfig {
  static const String serviceProviderUrl = 'https://TUO_SERVICE_PROVIDER/login';
}
```

### 3. Configurazione Android

Il file `android/app/src/main/AndroidManifest.xml` è già configurato.

Cambia solo il package name se necessario:
```xml
<manifest package="com.tuaorganizzazione.tuaapp">
```

### 4. Configurazione iOS (quando avrai accesso a Mac)

Modifica `ios/Runner/Info.plist`:
- `SP_URL`: URL del tuo Service Provider
- `SP_URL_SCHEME`: Il tuo Bundle Identifier
- `CFBundleURLSchemes`: Il tuo Bundle Identifier

---

## 📦 Struttura del Progetto

```
cie_login_flutter/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── screens/
│   │   ├── home_screen.dart         # Schermata principale
│   │   ├── cie_webview_screen.dart  # WebView autenticazione
│   │   └── success_screen.dart      # Post-autenticazione
│   ├── services/
│   │   └── cie_auth_service.dart    # Logica CIE cross-platform
│   └── widgets/
│       └── cie_login_button.dart    # Pulsante "Entra con CIE"
├── android/
│   └── app/src/main/
│       ├── kotlin/.../MainActivity.kt  # Codice nativo Android
│       └── AndroidManifest.xml         # Configurazione Android
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift        # Codice nativo iOS
│       └── Info.plist               # Configurazione iOS
└── pubspec.yaml
```

---

## 🔄 Flusso di Autenticazione

```
┌─────────────────────────────────────────────────────────────────┐
│                        TUA APP FLUTTER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Utente preme "Entra con CIE"                                │
│         │                                                        │
│         ▼                                                        │
│  2. Si apre WebView → carica pagina Service Provider            │
│         │                                                        │
│         ▼                                                        │
│  3. WebView intercetta URL "/OpenApp"                           │
│         │                                                        │
│         ▼                                                        │
│  4. Si apre APP CIEID (esterna)                                 │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────────────────────────────┐                       │
│  │         APP CIEID                     │                       │
│  │  • Lettura CIE via NFC                │                       │
│  │  • Inserimento PIN                    │                       │
│  │  • Autenticazione                     │                       │
│  └──────────────────────────────────────┘                       │
│         │                                                        │
│         ▼                                                        │
│  5. CieID ritorna alla tua app con callback URL                 │
│         │                                                        │
│         ▼                                                        │
│  6. WebView carica URL di callback                              │
│         │                                                        │
│         ▼                                                        │
│  7. Estrazione dati utente → Autenticazione completata!         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧪 Test su Emulatore

L'autenticazione CIE richiede NFC, quindi non funziona completamente su emulatore.

**Per testare l'UI:**
```powershell
flutter run
```

**Per testare l'intero flusso:**
- Usa un dispositivo fisico Android con NFC
- Installa l'app CieID
- Usa una CIE 3.0 reale

---

## 🐛 Troubleshooting

### L'app CieID non si apre

**Android:**
1. Verifica che CieID sia installata
2. Controlla che `<queries>` sia presente in AndroidManifest.xml
3. Ricompila l'app

**iOS:**
1. Verifica `LSApplicationQueriesSchemes` in Info.plist
2. Reinstalla l'app

### WebView non carica

1. Controlla la connessione internet
2. Verifica l'URL del Service Provider
3. Controlla i log: `flutter run --verbose`

### Errore "Permission denied"

**Android:** Assicurati che `INTERNET` sia nei permessi

### Build iOS fallisce

Ricorda: iOS richiede un Mac con Xcode!

---

## 📚 Risorse Utili

### Documentazione Ufficiale
- [CieID Android SDK](https://github.com/italia/cieid-android-sdk)
- [CieID iOS SDK](https://github.com/italia/cieid-ios-sdk)
- [Developers Italia - CIE](https://developers.italia.it/it/cie/)
- [Manuale Service Provider](https://www.cartaidentita.interno.gov.it/CIE3.0-ManualeSP.pdf)

### Flutter
- [Flutter Docs](https://docs.flutter.dev/)
- [WebView Flutter](https://pub.dev/packages/webview_flutter)
- [Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)

### CI/CD per Build iOS su Windows
- [Codemagic](https://codemagic.io/) - Gratuito per progetti open source
- [GitHub Actions macOS](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)

---

## 📄 Licenza

MIT License

---

## 🇮🇹 Made in Italy

Supporta l'identità digitale italiana! 🎉
