# سجل الزيارات - Visit Log App

A Flutter-based mobile application for tracking and managing visit logs to schools and educational institutions, designed specifically for Arabic-speaking users.

## 📱 Features

- **📅 Calendar View**: Monthly calendar interface with Arabic day/month names
- **➕ Add Visits**: Record new visits with school name, date, time, and notes
- **✏️ Edit/Delete**: Modify or remove existing visit records
- **📊 Export Reports**: Generate HTML reports with Arabic styling for monthly visits
- **🕐 Time Tracking**: Optional visit time recording
- **📝 Notes System**: Add detailed notes for each visit
- **💾 Offline Storage**: Local data persistence using Hive database
- **🌐 Arabic Interface**: Full RTL (Right-to-Left) layout support

## 🛠️ Technical Stack

### **Framework & Language**
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Arabic Localization** - Full RTL support with Arabic text

### **Database & Storage**
- **Hive** - Lightweight, fast NoSQL database for local storage
- **Hive Flutter** - Flutter integration for Hive
- **Path Provider** - Access to filesystem directories

### **UI & Design**
- **Material Design** - Flutter's material design components
- **Google Fonts (Cairo)** - Arabic font family for better text rendering
- **Custom Styling** - Arabic-optimized UI components

### **Export & External Services**
- **HTML Export** - Generate formatted reports with Arabic styling
- **URL Launcher** - Open external links (email, WhatsApp)
- **Intl** - Internationalization and date formatting

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point with Arabic localization
├── models/
│   ├── visit.dart              # Visit data model with Hive annotations
│   └── visit.g.dart            # Generated Hive adapter
├── services/
│   ├── hive_service.dart       # Database operations and queries
│   └── export_service.dart     # HTML report generation
├── screens/
│   ├── calendar_screen.dart    # Main calendar view
│   ├── add_visit_page.dart     # Add new visit form
│   ├── edit_visit_page.dart    # Edit existing visit
│   └── visit_details_page.dart # View visit details
└── widgets/
    └── day_tile.dart           # Calendar day component
```

## 💾 Data Model

### Visit Model
```dart
class Visit {
  String id;              // Unique identifier
  DateTime date;          // Visit date
  String schoolName;      // School/institution name
  String? notes;          // Optional notes
  String? photoPath;      // Optional photo path
  DateTime? visitTime;    // Optional visit time
}
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd visit_log
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📋 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  google_fonts: ^6.1.0
  path_provider: ^2.1.1
  url_launcher: ^6.2.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

## 📊 Export Functionality

The app generates HTML reports with:
- **Arabic styling** with RTL layout
- **Monthly visit summaries** with school names, dates, times, and notes
- **Word-compatible formatting** for easy editing
- **Automatic file naming** with Arabic month names
- **UTF-8 encoding** for proper Arabic text display

## 👨‍💻 Developer Information

**Developed by**: Taha Kadhim  
**Contact**: 
- 📧 Email: tahakadhim00@gmail.com
- 📱 WhatsApp: [redacted]

## 🌐 Localization

- **Primary Language**: Arabic (ar_SA)
- **Secondary Language**: English (en_US)
- **Text Direction**: RTL (Right-to-Left)
- **Date Format**: Arabic date formatting
- **Number System**: Arabic-Indic numerals support

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS (with proper configuration)

## 🔧 Configuration

### Android Configuration
Ensure proper Arabic text rendering in `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="سجل الزيارات"
    android:supportsRtl="true">
```

### iOS Configuration
Add Arabic language support in `ios/Runner/Info.plist`:
```xml
<key>CFBundleLocalizations</key>
<array>
    <string>ar</string>
    <string>en</string>
</array>
```

## 🎨 UI Design Principles

- **Arabic-First Design**: All UI elements optimized for Arabic text
- **Material Design**: Following Google's material design guidelines
- **Accessibility**: High contrast colors and readable fonts
- **Responsive Layout**: Adapts to different screen sizes
- **Intuitive Navigation**: Simple and clear user interface

## 📈 Future Enhancements

- 📷 Photo attachment for visits
- 🔄 Cloud synchronization
- 📊 Advanced analytics and charts
- 🔍 Search and filter functionality
- 📤 Multiple export formats (PDF, Excel)
- 🔔 Visit reminders and notifications

## 📄 License

This project is developed for educational and institutional use. Please contact the developer for commercial usage rights.

---

*Built with ❤️ for Arabic-speaking educators and administrators*
