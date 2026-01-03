import 'package:flutter/material.dart';

class DateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelect;
  final ThemeData theme;
  const DateStrip({super.key, required this.selectedDate, required this.onDateSelect, required this.theme});

  @override Widget build(BuildContext context) => Container(height: 85, margin: const EdgeInsets.only(bottom: 12), child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 14, itemBuilder: (context, index) {
    final d = DateTime.now().add(Duration(days: index));
    final isSel = d.year == selectedDate.year && d.month == selectedDate.month && d.day == selectedDate.day;
    return GestureDetector(onTap: () => onDateSelect(d), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 58, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: isSel ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(["M","T","W","T","F","S","S"][d.weekday - 1], style: TextStyle(fontSize: 12, color: isSel ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text("${d.day}", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: isSel ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface))])));
  }));
}