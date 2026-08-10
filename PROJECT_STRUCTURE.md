# Visit Log App - Project Structure

## Overview
A Flutter mobile application for tracking and managing school visits with Arabic localization and RTL support.

**App Name**: سجل زيارات (Visit Log)  
**Framework**: Flutter  
**Database**: Hive (Local Storage)  
**Language**: Arabic with RTL support  
**Platform**: Mobile (Android/iOS)

## Project Structure

```
lib/
├── main.dart                    # App entry point and configuration
├── models/
│   ├── visit.dart              # Visit model with Hive annotations
│   └── visit.g.dart            # Generated Hive adapter
├── services/
│   ├── hive_service.dart       # Database operations
│   ├── export_service.dart     # HTML report generation
│   └── backup_service.dart     # JSON backup import/export
├── screens/
│   ├── calendar_screen.dart    # Main calendar interface with drawer
│   ├── add_visit_page.dart     # Add new visit
│   ├── edit_visit_page.dart    # Edit existing visit
│   ├── visit_details_page.dart # View visit details
│   ├── settings_page.dart      # Settings page with backup features
│   └── feedback_page.dart      # Send feedback page
├── widgets/
│   └── day_tile.dart           # Calendar day component with Friday holiday support
├── assets/
│   └── icon.png                # App icon
└── inspire/
    └── inpire1.png             # Additional assets
```

## Core Features

### 1. Visit Management
- **Add Visits**: Record school visits with date, school name, visit details, and notes
- **Edit Visits**: Modify existing visit information with separate fields for details and notes
- **Delete Visits**: Remove visit records
- **View Details**: Display comprehensive visit information
- **Quick Insert Options**: Predefined visit types including "صديق ناقد", "تحقيق", "دوام", "تنظيم دوام", "متابعة امتحانات", "تدقيق قطاعي"
- **Friday Restrictions**: Fridays are marked as holidays - no visits can be added

### 2. Calendar Interface
- **Monthly View**: Display visits in a calendar grid layout (3 columns)
- **Arabic Dates**: Full Arabic month and day names
- **Navigation**: Switch between months with intuitive controls
- **Visual Indicators**: Show visit status with colors and counters
- **Holiday Display**: Fridays show holiday indicator with red styling
- **Drawer Navigation**: Left drawer menu for easy access to features

### 3. Data Export & Backup
- **HTML Reports**: Generate monthly visit reports with separate columns for visit details and notes
- **Arabic Formatting**: Proper RTL layout and Arabic text
- **Word Compatible**: HTML format that can be opened in Microsoft Word
- **Friday Exclusion**: Fridays are automatically excluded from export reports
- **File Storage**: Save reports to Downloads folder
- **JSON Backup**: Complete data backup and restore functionality
- **Import/Export**: Full data import/export with JSON format
- **Structured Data**: Reports include visit details in "تفاصيل الزيارة" column and additional notes in "الملاحظات" column

### 4. Settings & Configuration
- **Settings Page**: Comprehensive settings with backup options
- **Data Export**: Save all data to JSON file in Downloads folder
- **Data Import**: Import data from JSON file using file browser
- **Backup Management**: Complete backup and restore system

### 5. Communication & Feedback
- **Feedback System**: Dedicated feedback page for user suggestions
- **Contact Integration**: WhatsApp and Gmail integration
- **Developer Info**: About page with app description and contact details

### 6. Localization
- **Arabic UI**: Complete Arabic interface
- **RTL Support**: Right-to-left text direction
- **Date Formatting**: Arabic month and day names
- **Cultural Adaptation**: Appropriate for Arabic-speaking users

## Data Model

### Visit Class
```dart
class Visit {
  String id;              // Unique identifier
  DateTime date;          // Visit date
  String schoolName;      // Name of visited school
  String? visitDetails;   // Optional visit details (type of visit)
  String? notes;          // Optional additional notes
  String? photoPath;      // Optional photo reference
  DateTime? visitTime;    // Optional specific visit time
}
```

## Key Services

### HiveService
- **Database Management**: Initialize and manage Hive database
- **CRUD Operations**: Create, read, update, delete visits
- **Query Methods**: Get visits by date, month, or all visits
- **ID Generation**: Create unique visit identifiers

### ExportService
- **Report Generation**: Create HTML reports with Arabic support and structured data columns
- **Date Formatting**: Convert dates to Arabic format
- **File Management**: Save reports to Downloads folder
- **Word Compatibility**: Generate HTML that opens properly in Word
- **Friday Filtering**: Automatically exclude Fridays from export reports
- **Data Structure**: Separates visit details from general notes in export format

### BackupService
- **JSON Export**: Export all data to JSON format with metadata
- **JSON Import**: Import data from JSON files using file browser
- **Data Validation**: Validate backup file structure and integrity
- **Fallback Handling**: Robust error handling and fallback mechanisms
- **File Management**: Save backups to Downloads folder with timestamps

## UI Components

### CalendarScreen (Main Interface)
- Monthly calendar grid (3 columns layout)
- Month navigation with Arabic month names
- Export functionality
- Left drawer navigation menu
- No info icon in AppBar (moved to drawer)
- Responsive design with proper Arabic styling
- Clean, modern interface

### DayTile (Calendar Day Component)
- Display day number and Arabic day name
- Show visit indicators (green dot for single visit, counter for multiple)
- Interactive tap handling (add visit or view details)
- Visual feedback for today's date and visit status
- **Friday Holiday Support**: Red styling and "عطلة" indicator for Fridays
- **Disabled Fridays**: No interaction allowed on Friday tiles

### SettingsPage
- **Backup Section**: Export and import data options
- **User-Friendly**: Clear Arabic descriptions and instructions
- **File Browser Integration**: Native file picker for import/export

### FeedbackPage
- **Contact Options**: WhatsApp and Gmail integration
- **Professional Design**: Clean interface with contact cards
- **Arabic Instructions**: Clear guidance for users

## Technical Details

### Dependencies
- `flutter/material.dart` - UI framework
- `hive_flutter` - Local database
- `google_fonts` - Cairo font for Arabic text
- `intl` - Date formatting
- `url_launcher` - External link handling
- `path_provider` - File system access
- `file_picker` - File selection for import/export

### Database Schema
- Uses Hive NoSQL database for local storage
- Single box for Visit objects
- Type-safe with generated adapters
- **Fixed Hive Adapter**: Corrected visitDetails field serialization issue
- Efficient queries for date-based operations
- Support for all visit fields including visitDetails and notes

### Styling
- Material Design with Arabic customization
- Cairo font family for better Arabic rendering
- **Unified Blue Theme**: Consistent blue color scheme across all screens
- **Modern AppBar Design**: Centralized blue AppBar theme with white text
- **Theme Configuration**: Global theme settings in main.dart
- Green accents for visit indicators and success states
- Red styling for Friday holidays and delete actions
- Responsive layouts with proper padding and shadows

## Navigation Structure

### Main Drawer Menu
1. **الإعدادات** (Settings) - Settings page with backup features
2. **إرسال ملاحظات** (Send Feedback) - Feedback page with contact options
3. **معلومات التطبيق** (About App) - App information and description

### App Flow
```
CalendarScreen (Main)
├── Drawer Navigation
│   ├── Settings Page → Backup/Restore
│   ├── Feedback Page → WhatsApp/Gmail
│   └── About Dialog → App Info
├── Add Visit Page
├── Edit Visit Page
└── Visit Details Page
```

## Developer Information
- **Developer**: Taha Kadhim
- **Email**: tahakadhim00@gmail.com

## File Naming Convention
- Arabic file names supported for export
- Timestamp-based naming to avoid conflicts
- HTML format for reports, JSON format for backups
- Automatic Downloads folder storage

## Recent Major Updates

### Holiday System Implementation
- **Friday Holidays**: Complete Friday holiday system implemented
- **Visual Indicators**: Red styling and "عطلة" badges for Fridays
- **Export Filtering**: Fridays automatically excluded from all reports
- **User Experience**: Clear visual feedback for non-working days

### Navigation & UI Overhaul
- **Drawer Navigation**: Implemented left drawer menu system
- **Info Icon Removal**: Moved from AppBar to drawer for cleaner design
- **Menu Simplification**: Removed redundant "التقويم" option from drawer
- **Professional Layout**: Clean, educational supervisor-focused design

### Backup & Data Management
- **Complete Backup System**: Full JSON import/export functionality
- **File Browser Integration**: Native file picker for user-friendly operation
- **Downloads Folder Storage**: Automatic storage in accessible location
- **Data Validation**: Robust validation and error handling

### Communication Features
- **Feedback System**: Dedicated feedback page with contact integration
- **Contact Integration**: Direct WhatsApp and Gmail functionality
- **Pre-filled Messages**: Smart message templates for better user experience

### Code Quality & Performance
- **Deprecated Code Fixed**: Updated all deprecated Flutter methods
- **Performance Optimization**: Improved widget efficiency and memory usage
- **VS Code Compliance**: Fixed all linting warnings and suggestions
- **Future-proof Code**: Updated to use current Flutter best practices
- **Error Handling**: Comprehensive error handling throughout the app
- **Theme Consistency**: Unified app-wide theme with consistent blue color scheme
- **Hive Adapter Fix**: Fixed visitDetails field serialization in Hive database
- **Const Optimization**: Applied const constructors for better performance

### Export & Reports Enhancement
- **Friday Filtering**: Automatic exclusion of Fridays from all exports
- **Improved Reports**: Better HTML structure and Arabic support
- **Downloads Integration**: Direct save to Downloads folder
- **Structured Data**: Clear separation of visit details and notes
- **Professional Formatting**: Clean, printable report layout

### Recent Bug Fixes & Improvements (Latest)
- **Visit Details Save Issue**: Fixed Hive adapter to properly serialize visitDetails field
- **Theme Unification**: Implemented consistent blue theme across all pages
- **AppBar Standardization**: Unified AppBar design with global theme configuration
- **Code Cleanup**: Removed unused methods and optimized const declarations
- **Linting Compliance**: Resolved all Flutter linting warnings and suggestions
- **Performance Enhancements**: Applied const constructors where applicable
- **Color Scheme Consistency**: Replaced inconsistent red theme in edit page with blue theme

## App Description
"تم تطوير هذا التطبيق خصيصًا للمشرفين التربويين، ليساعدهم على تسجيل زياراتهم وأنشطتهم بسهولة ومرونة، مع إمكانية تصدير سجل كامل للزيارات الشهرية بشكل منظم وجاهز للطباعة."

This application was developed specifically for educational supervisors to help them record their visits and activities with ease and flexibility, with the ability to export a complete log of monthly visits in an organized and print-ready format.