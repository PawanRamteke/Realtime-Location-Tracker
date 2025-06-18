# Location Tracking App

> 📍 **Real-time location tracking with Google Maps integration, store management, and background location services. Built with Flutter & GetX.**

A comprehensive Flutter application for real-time location tracking with background functionality, store management, and interactive mapping features.

## 🚀 Features

### Core Location Tracking
- **Real-time Location Monitoring**: Track your current location with precise GPS coordinates
- **Background Location Service**: Continue tracking location even when the app is in the background
- **Start/Stop Tracking**: Easy-to-use controls to manage location tracking sessions
- **Location History**: View and manage your location tracking history

### Interactive Mapping
- **Google Maps Integration**: Full-featured map interface using Google Maps Flutter
- **Location Picker**: Interactive map for selecting and picking specific locations
- **Place Search**: Search for places using Google Places API with autocomplete functionality
- **Location Details**: Get detailed information about selected locations

### Store Management System
- **Store CRUD Operations**: Create, Read, Update, and Delete store locations
- **Store Categories**: Organize stores with custom categories
- **Store Details**: Store comprehensive information including name, address, coordinates, and notes
- **Store Search**: Search through your saved stores
- **Store Mapping**: View all stores on an interactive map

### User Experience
- **Modern UI/UX**: Clean and intuitive Material Design 3 interface
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Permission Handling**: Proper handling of location and storage permissions
- **Error Handling**: Robust error handling and user feedback

## 🏗️ Architecture

### State Management
- **GetX Framework**: Used for state management, dependency injection, and navigation
- **Reactive Programming**: Observable state management for real-time UI updates

### Project Structure
```
lib/
├── controllers/          # GetX controllers for state management
│   ├── home_controller.dart
│   ├── location_picker_controller.dart
│   └── store_controller.dart
├── screens/             # UI screens
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── map_location_picker.dart
│   └── store_management_screen.dart
├── services/            # External service integrations
│   └── places_service.dart
├── location_services/   # Location-related services
├── database_helper/     # Local database operations
├── utils/              # Utility functions and helpers
└── widgets/            # Reusable UI components
```

### Key Dependencies
- **geolocator**: Location services and GPS functionality
- **google_maps_flutter**: Interactive maps integration
- **sqflite**: Local SQLite database for data persistence
- **permission_handler**: Handle device permissions
- **http**: HTTP requests for API calls
- **shared_preferences**: Local data storage
- **intl**: Internationalization and date formatting

## 📱 Screens

### Home Screen
- Welcome message and current location display
- Start/Stop tracking controls
- Navigation to Map and Store Management screens
- Real-time location updates

### Map Screen
- Interactive Google Maps interface
- Current location marker
- Location tracking visualization
- Map controls and zoom functionality

### Location Picker
- Interactive map for location selection
- Place search with autocomplete
- Location confirmation and details
- Coordinate display

### Store Management
- Store listing with search functionality
- Add/Edit/Delete store operations
- Store categorization
- Store details management
- Map view of all stores

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Google Maps API Key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd location_tracking
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API**
   - Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the following APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Places API
   - Update the API key in `lib/services/places_service.dart`

4. **Platform-specific setup**

   **Android:**
   - Add location permissions to `android/app/src/main/AndroidManifest.xml`
   - Add Google Maps API key to `android/app/src/main/AndroidManifest.xml`

   **iOS:**
   - Add location permissions to `ios/Runner/Info.plist`
   - Add Google Maps API key to `ios/Runner/AppDelegate.swift`

5. **Run the application**
   ```bash
   flutter run
   ```

## 🔐 Permissions

The app requires the following permissions:
- **Location**: For GPS tracking and location services
- **Storage**: For saving location data and store information
- **Internet**: For Google Maps and Places API integration

## 🗄️ Database Schema

The app uses SQLite for local data storage with the following tables:
- **locations**: Stores location tracking history
- **stores**: Stores store information and coordinates
- **categories**: Stores store categories

## 🚀 Usage

1. **Start Location Tracking**
   - Open the app and tap "Start Tracking"
   - Grant location permissions when prompted
   - View your current location in real-time

2. **View Map**
   - Tap "View Map" to see your location on Google Maps
   - Interact with the map to explore different areas

3. **Manage Stores**
   - Tap "Store Management" to access store features
   - Add new stores with location details
   - Search and manage existing stores
   - View all stores on a map

4. **Pick Locations**
   - Use the location picker to select specific locations
   - Search for places using the search functionality
   - Save locations for future reference

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues or have questions:
1. Check the existing issues in the repository
2. Create a new issue with detailed information
3. Contact the development team

## 🔄 Version History

- **v1.0.0**: Initial release with core location tracking and store management features

---

**Built with ❤️ using Flutter and GetX**
