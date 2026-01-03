import 'package:flutter/material.dart';
import '../models/task_list.dart';

class CustomDrawer extends StatelessWidget {
  final ThemeData theme;
  final String currentList;
  final List<TaskListModel> lists;
  final Function(String) onSwitchList;
  final VoidCallback onSettings;
  final VoidCallback onAddList;

  const CustomDrawer({super.key, required this.theme, required this.currentList, required this.lists, required this.onSwitchList, required this.onSettings, required this.onAddList});

  @override Widget build(BuildContext context) {
    return Drawer(backgroundColor: theme.colorScheme.surface, child: Column(children: [
      Expanded(child: ListView(padding: EdgeInsets.zero, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 60, 20, 20), child: Text("Expressive", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary))),
        _item(Icons.sunny, "My Day", theme.colorScheme.primary, context),
        _item(Icons.task_alt, "My Tasks", Colors.indigoAccent, context),
        _item(Icons.star, "Important", Colors.orange, context),
        _item(Icons.check_circle, "Completed", Colors.teal, context),
        const Divider(indent: 20, endIndent: 20, height: 40),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
           Row(children: [Icon(Icons.list, size: 18, color: theme.colorScheme.secondary), const SizedBox(width: 8), Text("LISTS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11, color: theme.colorScheme.secondary))]),
           IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () {
             Navigator.pop(context); // Close drawer first
             onAddList();
           })
        ])),
        ...lists.where((l) => l.name != 'My Day' && l.name != 'My Tasks').map((l) => _item(IconData(l.iconCode, fontFamily: 'MaterialIcons'), l.name, Color(l.colorValue), context))
      ])),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.fromLTRB(0, 8, 0, 24), child: _item(Icons.settings, "Settings", theme.colorScheme.onSurfaceVariant, context, isSetting: true))
    ]));
  }

  Widget _item(IconData icon, String label, Color color, BuildContext ctx, {bool isSetting = false}) {
    final isSel = currentList == label && !isSetting;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), child: ListTile(leading: Icon(icon, color: isSel ? color : theme.colorScheme.onSurfaceVariant), title: Text(label, style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.normal, color: isSel ? color : null)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), tileColor: isSel ? color.withOpacity(0.1) : null, onTap: () { 
      Navigator.pop(ctx); // FIX: Close drawer immediately
      if(isSetting) onSettings(); else onSwitchList(label); 
    }));
  }
}
