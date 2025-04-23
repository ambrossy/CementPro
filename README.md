# CementCalc

Quick and easy cement calculator built with Flutter.

**Download README:** [Raw Markdown](https://raw.githubusercontent.com/ambrossy/cementcalc/main/README.md)

## 🔍 Description

CementCalc helps you calculate how many kg of cement you need based on the average thickness of your measurements, the area, and the density.

## ⚙️ Features

- **Digit Mode**: auto-input when 2 or 3 digits typed.  
- **Classic Mode**: manually add values with the “Add” button.  
- Undo last entry.  
- History of measurements with individual delete.  
- Set surface (m²) and specific weight.  
- Data persists on device and web.  

## 🚀 Installation

1. Clone the repo:  
   ```bash
   git clone https://github.com/ambrossy/cementcalc.git
   ```
2. Go into the project & fetch deps:  
   ```bash
   cd cementcalc
   flutter pub get
   ```
3. Run it on emulator or device:  
   ```bash
   flutter run
   ```

## 💾 Persistence

- **Mobile**: saves to local JSON.  
- **Web**: uses LocalStorage for measurements and settings.  

## 📱 PWA vs APK

### Progressive Web App (PWA)
- **How to install**: Open the app in your browser (e.g., Chrome or Safari). Tap the menu (⋮ or share icon) and select “Add to Home Screen”.  
- **Pros**: No store download, works offline after initial load, auto-updates.  
- **Cons**: Limited native APIs, less performance than native.  

### APK (Android Package)
- **How to install**: Download the `.apk` from releases or build locally with `flutter build apk`, then sideload on your Android device.  
- **Pros**: Full native performance, access to all device sensors and features.  
- **Cons**: Requires manual updates or Play Store listing, larger file size.  

## 🎮 Usage

1. Pick a mode (2-digit, 3-digit or classic) ▶️  
2. Enter values via keyboard or “Add”.  
3. Adjust surface and specific weight in ⚙️ Settings.  
4. Check average thickness (mm) and total cement (kg).  

## 🛠️ Settings

- **Surface (m²)**: area to work on.  
- **Specific Weight**: cement density (default 1.8).  
- **Classic Mode**: disable auto-input.  
- **Digit Mode**: switch between 2 or 3 digits for quick input.  

## 🤝 Contributing

PRs and suggestions welcome! Open an issue or PR 😊

## 📄 License

This project is licensed under the MIT License.
