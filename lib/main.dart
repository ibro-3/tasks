import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';

import 'models/enums.dart';
import 'services/notification_service.dart';
import 'services/task_repository.dart';
import 'providers/task_provider.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(TaskApp(prefs: prefs));
}

class TaskApp extends StatefulWidget {
  final SharedPreferences prefs;
  const TaskApp({super.key, required this.prefs});
  @override
  State<TaskApp> createState() => TaskAppState();
}

class TaskAppState extends State<TaskApp> {
  late final TaskProvider _taskProvider;
  late final TaskRepository _repository;

  ThemeMode themeMode = ThemeMode.system;
  AppThemeStyle currentStyle = AppThemeStyle.blue;
  double radius = 32.0;
  bool isCompact = false;
  bool soundOn = true;
  bool isOled = false;
  Color? systemSeedColor;

  @override
  void initState() {
    super.initState();
    _repository = TaskRepository(widget.prefs);
    _taskProvider = TaskProvider(_repository);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = widget.prefs;
    setState(() {
      if (p.getString('theme_mode') != null) {
        themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == p.getString('theme_mode'),
        );
      }
      if (p.getString('theme_style') != null) {
        currentStyle = AppThemeStyle.values.firstWhere(
          (e) => e.toString() == p.getString('theme_style'),
          orElse: () => AppThemeStyle.blue,
        );
      }
      radius = p.getDouble('radius') ?? 32.0;
      isCompact = p.getBool('compact') ?? false;
      soundOn = p.getBool('sound') ?? true;
      isOled = p.getBool('oled') ?? false;
    });
  }

  void _save(String key, dynamic value) async {
    if (value is String) {
      widget.prefs.setString(key, value);
    } else if (value is int) {
      widget.prefs.setInt(key, value);
    } else if (value is double) {
      widget.prefs.setDouble(key, value);
    } else if (value is bool) {
      widget.prefs.setBool(key, value);
    }
  }

  void updateThemeMode(ThemeMode m) {
    setState(() => themeMode = m);
    _save('theme_mode', m.toString());
  }

  void updateStyle(AppThemeStyle s) {
    setState(() => currentStyle = s);
    _save('theme_style', s.toString());
  }

  void updateCornerRadius(double v) {
    setState(() => radius = v);
    _save('radius', v);
  }

  void updateCompact(bool v) {
    setState(() => isCompact = v);
    _save('compact', v);
  }

  void updateSound(bool v) {
    setState(() => soundOn = v);
    _save('sound', v);
  }

  void updateOled(bool v) {
    setState(() => isOled = v);
    _save('oled', v);
  }

  ThemeData _buildTheme(Brightness b, ColorScheme? systemScheme) {
    ColorScheme scheme;

    if (currentStyle == AppThemeStyle.dynamic && systemScheme != null) {
      scheme = systemScheme;
    } else {
      Color seed;
      switch (currentStyle) {
        case AppThemeStyle.blue:
          seed = const Color(0xFF2979FF);
          break;
        case AppThemeStyle.green:
          seed = Colors.teal;
          break;
        case AppThemeStyle.pink:
          seed = Colors.pinkAccent;
          break;
        case AppThemeStyle.orange:
          seed = Colors.orange;
          break;
        case AppThemeStyle.purple:
          seed = Colors.deepPurple;
          break;
        case AppThemeStyle.monochrome:
          seed = Colors.grey;
          break;
        default:
          seed = const Color(0xFF2979FF);
      }

      scheme = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: b,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      );
    }

    if (isOled && b == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF2C2C2C),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return null;
        }),
        shape: const CircleBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 2 : 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ).data,

      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
      ).data,

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        insetPadding: const EdgeInsets.all(24),
      ),

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius - 8),
        ),
        color: scheme.surfaceContainer,
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        systemSeedColor = lightDynamic?.primary ?? darkDynamic?.primary;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tasks $appVersion',
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light, lightDynamic),
          darkTheme: _buildTheme(Brightness.dark, darkDynamic),
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: _taskProvider,
            child: TaskHomePage(settings: this, taskProvider: _taskProvider),
          ),
        );
      },
    );
  }
}
