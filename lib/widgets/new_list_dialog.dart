import 'package:flutter/material.dart';

class NewListDialog extends StatefulWidget {
  final List<String> existingNames;
  final Function(String, int, int) onCreate;
  const NewListDialog({super.key, required this.existingNames, required this.onCreate});
  @override State<NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<NewListDialog> {
  final TextEditingController _c = TextEditingController();
  int _icon = Icons.folder_outlined.codePoint; Color _color = Colors.blue;
  final _icons = [Icons.work, Icons.home, Icons.shopping_cart, Icons.flight, Icons.fitness_center, Icons.book, Icons.code, Icons.music_note];
  final _colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal, Colors.indigo];

  @override Widget build(BuildContext context) => AlertDialog(title: const Text("New List"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextField(controller: _c, autofocus: true, decoration: const InputDecoration(hintText: "List Name", border: InputBorder.none)),
    const SizedBox(height: 16),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _icons.map((i) => GestureDetector(onTap: () => setState(() => _icon = i.codePoint), child: Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 8), alignment: Alignment.center, decoration: BoxDecoration(color: _icon == i.codePoint ? Theme.of(context).colorScheme.primaryContainer : null, shape: BoxShape.circle), child: Icon(i, size: 20)))).toList())),
    const SizedBox(height: 16),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _colors.map((c) => GestureDetector(onTap: () => setState(() => _color = c), child: Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: _color == c ? Border.all(width: 2) : null)))).toList()))
  ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), TextButton(onPressed: () { if (_c.text.isNotEmpty && !widget.existingNames.contains(_c.text)) { widget.onCreate(_c.text, _icon, _color.value); Navigator.pop(context); } }, child: const Text("Create"))]);
}