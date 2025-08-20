# UniMark Deployment Guide

This guide explains how to run both the web dashboard and Android APK for the UniMark attendance system.

## Prerequisites

### For Web Dashboard
- Node.js (v14 or higher)
- npm or yarn
- Modern web browser

### For Android APK
- Flutter SDK (v3.0 or higher)
- Android Studio or VS Code with Flutter extension
- Android device or emulator
- Java Development Kit (JDK 8 or higher)

## Running the Web Dashboard

### 1. Navigate to Web Admin Directory
```bash
cd d:\Project\unimark\web-admin
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Start Development Server
```bash
npm start
```

### 4. Access the Dashboard
- Open your browser and go to: `http://localhost:3000`
- The dashboard will automatically reload when you make changes

### Web Dashboard Features
- **Faculty Login**: Manage attendance sessions, view reports
- **Admin Panel**: User management, system settings
- **Real-time Updates**: Live attendance tracking
- **Reports**: Generate attendance reports and analytics

## Running the Android APK

### 1. Navigate to Project Root
```bash
cd d:\Project\unimark
```

### 2. Get Flutter Dependencies
```bash
flutter pub get
```

### 3. Check Flutter Setup
```bash
flutter doctor
```
Ensure all checkmarks are green, especially:
- Flutter SDK
- Android toolchain
- Connected device or emulator

### 4. Run on Device/Emulator

#### For Development (Debug Mode)
```bash
flutter run
```

#### For Release APK
```bash
flutter build apk --release
```
The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

#### For App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```

### 5. Install APK on Device
```bash
flutter install
```
or manually install the APK file on your Android device.

## Mobile App Features

### For Students
- **Join Sessions**: Enter session codes to mark attendance
- **Location Verification**: GPS-based attendance validation
- **Attendance History**: View past attendance records
- **Profile Management**: Update personal information

### For Faculty
- **Create Sessions**: Generate attendance sessions with codes
- **Manage Sessions**: Monitor active sessions and attendees
- **Reports**: View detailed attendance analytics
- **Profile Settings**: Manage account and preferences

## Firebase Configuration

Both applications use Firebase for:
- **Authentication**: User login and registration
- **Firestore**: Real-time database for attendance data
- **Cloud Functions**: Backend logic and validation

### Configuration Files
- Web: `web-admin/src/firebase.ts`
- Android: `lib/firebase_options.dart`

## Troubleshooting

### Web Dashboard Issues

1. **Port Already in Use**
   ```bash
   npx kill-port 3000
   npm start
   ```

2. **Firebase Errors**
   - Check `firebase.ts` configuration
   - Verify API keys and project settings

3. **Build Errors**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   npm start
   ```

### Android App Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor --android-licenses
   flutter clean
   flutter pub get
   ```

2. **Build Failures**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Firebase Connection Issues**
   - Check `firebase_options.dart`
   - Verify internet connection
   - Ensure Firebase project is properly configured

## Development Workflow

### 1. Start Web Dashboard
```bash
cd web-admin
npm start
```

### 2. Start Android App (in new terminal)
```bash
cd ..
flutter run
```

### 3. Test Integration
- Create a session on web dashboard
- Join session using mobile app
- Verify real-time updates on both platforms

## Production Deployment

### Web Dashboard
1. Build for production:
   ```bash
   npm run build
   ```
2. Deploy `build/` folder to web server
3. Configure environment variables

### Android App
1. Build release APK:
   ```bash
   flutter build apk --release
   ```
2. Sign APK for distribution
3. Upload to Google Play Store or distribute directly

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase console for backend errors
3. Check browser console for web dashboard issues
4. Use `flutter logs` for Android app debugging

## Security Notes

- Never commit Firebase API keys to version control
- Use environment variables for sensitive configuration
- Enable Firebase security rules for production
- Implement proper user authentication and authorization