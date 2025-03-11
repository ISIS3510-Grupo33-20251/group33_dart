# group33_dart

# Universe - Flutter Organization App

Universe is an organization app for **Flutter** that helps users manage their schedules, connect with friends, create teams, and collaborate on projects.

## Prerequisites
- Flutter **3.10.0** or newer
- Dart **3.0.0** or newer
- Android Studio or Visual Studio Code (recommended)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/universe-flutter.git
   cd universe-flutter
   ```
2. Open the project in **VS Code** or **Android Studio**.
3. Update the API base URL in `lib/core/network/api_client.dart` to point to your FastAPI backend:
   ```dart
   class ApiClient {
     static const String baseUrl = "https://your-api-url.com";
   }
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app on an emulator or physical device:
   ```bash
   flutter run
   ```

## Architecture

Universe follows **MVVM (Model-View-ViewModel)** with **Clean Architecture principles**, ensuring scalability and maintainability.

```
lib/
├── core/                # Core utilities
│   ├── network/         # API client (Dio/Http)
│   ├── utils/           # Helper functions and constants
│   ├── di/              # Dependency injection setup
│   ├── theme/           # App theming
├── data/                # Data layer
│   ├── models/          # Data transfer objects
│   ├── repositories/    # Repository implementations
│   ├── sources/         # Local & remote data sources
│   │   ├── local/       # Local storage (Hive/SQLite)
│   │   ├── remote/      # API interfaces
├── domain/              # Domain layer
│   ├── models/          # Domain entities
│   ├── repositories/    # Repository interfaces
│   ├── usecases/        # Business logic
├── presentation/        # Presentation layer (UI)
│   ├── auth/            # Login screens
│   ├── common/          # Shared UI components
│   ├── schedule/        # Schedule management
│   ├── location/        # Location tracking
│   ├── profile/         # Profile management
└── main.dart            # App entry point
```

