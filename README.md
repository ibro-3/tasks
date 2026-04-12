# Tasks - Flutter Todo App

A modern, expressive todo list application built with Flutter.

## Features

- Multiple task lists (My Day, My Tasks, Important, Completed)
- Custom lists with custom icons and colors
- Date-based task grouping (Today, Tomorrow, Overdue, Later)
- Task reminders with local notifications
- Dark/Light theme support with OLED mode
- Material Design 3 theming with dynamic colors
- Task completion confetti animation

## Architecture

```
lib/
├── main.dart                 # App entry point with theming
├── models/                   # Data models
│   ├── task.dart            # Task & SubTask models
│   ├── task_list.dart       # List model
│   └── enums.dart           # Repeat & AppThemeStyle enums
├── providers/                # State management
│   └── task_provider.dart   # Task state with Provider
├── services/                # Business logic
│   ├── task_repository.dart # Data persistence
│   └── notification_service.dart
├── screens/                 # UI screens
│   ├── home_page.dart      # Main task list
│   ├── detail_screen.dart  # Task details
│   └── settings_page.dart  # App settings
└── widgets/                # Reusable widgets
    ├── task_card.dart
    ├── drawer.dart
    ├── date_strip.dart
    └── new_list_dialog.dart
```

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `provider` - State management
- `shared_preferences` - Local storage
- `flutter_local_notifications` - Task reminders
- `dynamic_color` - Material You dynamic theming
- `timezone` - Timezone support for notifications