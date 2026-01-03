import 'package:flutter/material.dart';
import '../main.dart'; 
import '../models/enums.dart';

class SettingsPage extends StatelessWidget {
  final TaskAppState s;
  const SettingsPage({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'val': AppThemeStyle.blue, 'color': const Color(0xFF2979FF), 'name': 'Original'},
      {
        'val': AppThemeStyle.dynamic, 
        'color': Colors.blue,
        'name': 'Dynamic', 
        'isDynamic': true
      },
      {'val': AppThemeStyle.green, 'color': Colors.teal, 'name': 'Green'},
      {'val': AppThemeStyle.pink, 'color': Colors.pinkAccent, 'name': 'Pink'},
      {'val': AppThemeStyle.orange, 'color': Colors.orange, 'name': 'Orange'},
      {'val': AppThemeStyle.purple, 'color': Colors.deepPurple, 'name': 'Purple'},
      {'val': AppThemeStyle.monochrome, 'color': Colors.grey, 'name': 'Mono'}
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text("Appearance",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold))),
          ListTile(
              title: const Text("Theme Mode"),
              trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.smartphone))
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.updateThemeMode(v.first))),
          
          SizedBox(
              height: 200,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: themes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) {
                    final t = themes[i];
                    final seedColor = (t['isDynamic'] == true) 
                        ? (s.systemSeedColor ?? const Color(0xFF2979FF))
                        : (t['color'] as Color);

                    return _ThemePreviewNode(
                      label: t['name'] as String,
                      seedColor: seedColor,
                      isSelected: s.currentStyle == t['val'],
                      isDark: isDark,
                      onTap: () => s.updateStyle(t['val'] as AppThemeStyle),
                    );
                  })),
          
          SwitchListTile(title: const Text("Pure Black AMOLED"), value: s.isOled, onChanged: s.themeMode == ThemeMode.light ? null : (v) => s.updateOled(v)),
          const Divider(),
          Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text("Behavior", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text("Compact Mode"), value: s.isCompact, onChanged: (v) => s.updateCompact(v)),
          SwitchListTile(title: const Text("Sounds"), value: s.soundOn, onChanged: (v) => s.updateSound(v)),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.all(16), child: Text("Corner Radius: ${s.radius.toInt()}px", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
          Slider(value: s.radius, min: 0, max: 48, onChanged: (v) => s.updateCornerRadius(v)),
          const SizedBox(height: 40),
          const Center(child: Text("v12.1.0 (Full Palette Preview)", style: TextStyle(color: Colors.grey)))
        ]));
  }
}

class _ThemePreviewNode extends StatelessWidget {
  final String label;
  final Color seedColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemePreviewNode({
    required this.label,
    required this.seedColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 84,
            height: 130,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant.withOpacity(0.4),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
              ] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0, height: 40,
                    child: Container(color: scheme.surfaceContainer),
                  ),
                  Positioned(
                    top: 14, left: 10,
                    child: Container(
                      width: 30, height: 6,
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Positioned(
                    top: 50, left: 8, right: 8, height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          // Icon
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.onSecondaryContainer.withOpacity(0.5))),
                          const SizedBox(width: 4),
                          // Text Line
                          Container(width: 24, height: 4, decoration: BoxDecoration(color: scheme.onSecondaryContainer, borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80, left: 8, right: 24, height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(width: 20, height: 4, decoration: BoxDecoration(color: scheme.onTertiaryContainer, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add, size: 16, color: scheme.onPrimaryContainer),
                    ),
                  ),

                  // Selection Tint
                  if (isSelected)
                    Container(color: scheme.primary.withOpacity(0.1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? scheme.primary : (isDark ? Colors.white70 : Colors.black87),
              fontFamily: 'Roboto',
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}