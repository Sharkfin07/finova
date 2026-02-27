# Finova – Personal Finance Manager

A modern Flutter application for personal financial management. Track income & expenses, manage multiple wallets, and visualize spending habits with interactive charts.

## Features

- **Dashboard** – At-a-glance balance overview, quick actions, and recent transactions
- **Transactions** – Add, edit, and delete income/expense entries with categories
- **Wallets** – Manage multiple wallets (cash, bank, e-wallet, etc.) with color coding
- **Reports** – Interactive bar, line, and pie charts with weekly/monthly/yearly filters
- **Profile** – User settings, preferences, and account management
- **Authentication** – Firebase Auth with email/password sign-in and registration

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Navigation | go_router |
| Backend | Firebase (Auth, Firestore, Storage) |
| Local Storage | Hive |
| Charts | fl_chart |
| Fonts | Google Fonts (Poppins) |

## Project Structure

```
lib/
├── main.dart                  # App entry point & Hive initialization
├── app.dart                   # MaterialApp.router with theme
├── routes.dart                # GoRouter configuration & auth redirect
├── core/
│   ├── constants.dart         # Color palette & design tokens
│   ├── app_theme.dart         # Material 3 theme data
│   └── categories.dart        # Transaction category definitions
├── shared/
│   ├── widgets/
│   │   ├── main_shell.dart    # Bottom navigation shell
│   │   ├── custom_text_field.dart
│   │   └── custom_button.dart
│   └── services/
│       └── hive_service.dart  # Hive initialization & box management
└── features/
    ├── auth/
    │   ├── data/              # AuthRepository (Firebase Auth)
    │   ├── providers/         # authState, authNotifier
    │   └── presentation/      # LoginScreen, RegisterScreen
    ├── dashboard/
    │   └── presentation/      # DashboardScreen
    ├── transactions/
    │   ├── data/              # TransactionModel, TransactionRepository
    │   ├── providers/         # TransactionNotifier
    │   └── presentation/      # TransactionFormScreen
    ├── wallets/
    │   ├── data/              # WalletModel, WalletRepository
    │   ├── providers/         # WalletNotifier
    │   └── presentation/      # WalletsScreen
    ├── reports/
    │   └── presentation/      # ReportsScreen (Overview & Categories tabs)
    └── profile/
        └── presentation/      # ProfileScreen
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10
- Dart SDK ≥ 3.0
- Firebase project with Auth & Firestore enabled

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd finova
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Email/Password authentication
   - Enable Cloud Firestore
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform directories

4. **Run the app**
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --release
```

## Architecture

The app follows a **feature-first** architecture with clear separation of concerns:

- **Data layer** – Models (Hive-annotated) and repositories (Firestore + Hive cache)
- **Provider layer** – Riverpod StateNotifiers managing business logic and state
- **Presentation layer** – Stateless/Stateful widgets consuming providers

Offline-first approach: data is cached in Hive and synced with Firestore when available.

## Screenshots

| Dashboard | Transactions | Wallets | Reports |
|---|---|---|---|
| Home screen with balance & recent activity | Add/edit income and expense entries | Manage multiple wallets | Charts and spending analytics |

## License

This project is part of a Mobile Apps Development course assignment.