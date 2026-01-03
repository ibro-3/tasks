import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';

class TaskDetailScreen extends StatefulWidget { final Task task; final Function(Task) onUpdate; final VoidCallback onDelete; const TaskDetailScreen({super.key, required this.task, required this.onUpdate, required this.onDelete}); @override State<TaskDetailScreen> createState() => _TaskDetailScreenState(); }
class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController tC, nC, sC;
  @override void initState() { super.initState(); tC = TextEditingController(text: widget.task.title); nC = TextEditingController(text: widget.task.notes); sC = TextEditingController(); }
  void _save() { widget.task.title = tC.text; widget.task.notes = nC.text; widget.onUpdate(widget.task); }
  @override Widget build(BuildContext context) { final theme = Theme.of(context); return PopScope(canPop: true, onPopInvoked: (_) => _save(), child: Scaffold(body: CustomScrollView(slivers: [
    SliverAppBar.large(title: Hero(tag: 'title_${widget.task.id}', child: Material(color: Colors.transparent, child: Text(widget.task.title, style: theme.textTheme.headlineMedium))), actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { widget.onDelete(); Navigator.pop(context); })]),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: tC, style: theme.textTheme.headlineSmall, decoration: const InputDecoration(border: InputBorder.none, hintText: "Task Name"), onChanged: (_) => _save()),
      const SizedBox(height: 24),
      InkWell(borderRadius: BorderRadius.circular(16), onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100)); if (d!=null) { final t = await showTimePicker(context: context, initialTime: TimeOfDay.now()); setState(() { widget.task.dueDate = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0); _save(); }); }}, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.calendar_month, color: theme.colorScheme.primary), const SizedBox(width: 16), Text(widget.task.dueDate == null ? "Set Date & Time" : "${widget.task.dueDate!.month}/${widget.task.dueDate!.day}  ${widget.task.dueDate!.hour}:${widget.task.dueDate!.minute.toString().padLeft(2,'0')}", style: const TextStyle(fontWeight: FontWeight.bold))]))),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.repeat, color: theme.colorScheme.primary), const SizedBox(width: 16), Expanded(child: DropdownButton<Repeat>(value: widget.task.repeat, isExpanded: true, underline: const SizedBox(), borderRadius: BorderRadius.circular(16), items: Repeat.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(), onChanged: (v) => setState(() { widget.task.repeat = v!; _save(); })))])),
      const SizedBox(height: 32),
      Text("Subtasks", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ...widget.task.subTasks.map((s) => CheckboxListTile(title: Text(s.title, style: TextStyle(decoration: s.isCompleted ? TextDecoration.lineThrough : null)), value: s.isCompleted, onChanged: (v) => setState(() { s.isCompleted = v!; _save(); }))),
      TextField(controller: sC, decoration: const InputDecoration(prefixIcon: Icon(Icons.add), hintText: "Add step", border: InputBorder.none), onSubmitted: (v) { if(v.isNotEmpty) setState(() { widget.task.subTasks.add(SubTask(id: DateTime.now().toString(), title: v)); sC.clear(); _save(); }); }),
      const Divider(height: 40),
      TextField(controller: nC, maxLines: null, decoration: const InputDecoration(prefixIcon: Icon(Icons.notes), hintText: "Add notes...", border: InputBorder.none), onChanged: (_) => _save())
    ])))
  ]))); }
}