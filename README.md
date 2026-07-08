# FavFood

**My Fav Food** is a Flutter recipe app with Firebase authentication, Firestore-backed recipes, favorites, and profile photo uploads. It also includes web deployment support via Vercel.

## Features

### Core app
- Email and Google sign-in (Firebase Auth)
- Browse, create, edit, and delete recipes
- Favorite recipes with real-time Firestore sync
- Profile photo upload (Firebase Storage with Firestore fallback)
- Recipe photos and serving-size scaling
- Responsive UI for mobile and web

### Additional class activity
The **Album** and **JSON** tabs were added as supplementary coursework alongside the main recipe app:

- **Album** — Fetches and displays photo albums from the [JSONPlaceholder](https://jsonplaceholder.typicode.com/) API using HTTP requests and Provider state management.
- **JSON** — A JSON playground with tabs for manually building objects, generated `json_serializable` models, and fetching sample photos from a remote API.

## Tech stack

- Flutter
- Firebase (Auth, Firestore, Storage)
- Provider
- HTTP / JSON serialization
- Vercel (web hosting)

## Getting started

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repository:
   ```bash
   git clone https://github.com/Karen040409/FavFood.git
   cd FavFood
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Firebase setup

This project uses the Firebase project **`favfood-map`**.

- Android config: `android/app/google-services.json`
- Web options: `lib/firebase_options.dart`

For Google Sign-In on web, set your Web Client ID in `lib/main.dart`.

Enable **Firebase Storage** in the Firebase Console, then deploy rules:

```bash
firebase deploy --only storage,firestore --project favfood-map
```

## Project structure

```
lib/
├── screens/       # Home, recipes, album, JSON, settings
├── services/      # Firestore, Storage, API clients
├── viewmodels/    # Provider state (recipes, albums)
├── models/        # Recipe, album, JSON serializable models
├── widgets/       # Shared UI components
└── theme/         # App colors and typography
```

## Author

Karen — [GitHub](https://github.com/Karen040409)
