import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onUpdate;
  final VoidCallback onDelete;
  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController tC, nC, sC;
  @override
  void initState() {
    super.initState();
    tC = TextEditingController(text: widget.task.title);
    nC = TextEditingController(text: widget.task.notes);
    sC = TextEditingController();
  }

  void _save() {
    final newTask = Task(
      id: widget.task.id,
      title: tC.text,
      listName: widget.task.listName,
      notes: nC.text,
      isCompleted: widget.task.isCompleted,
      isStarred: widget.task.isStarred,
      dueDate: widget.task.dueDate,
      repeat: widget.task.repeat,
      subTasks: widget.task.subTasks,
    );
    widget.onUpdate(newTask);
  }

  void _toggleSubTask(SubTask subtask, bool? value) {
    final updatedSubTasks = widget.task.subTasks.map((s) {
      if (s.id == subtask.id) {
        return SubTask(id: s.id, title: s.title, isCompleted: value ?? false);
      }
      return s;
    }).toList();

    final newTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      listName: widget.task.listName,
      notes: widget.task.notes,
      isCompleted: widget.task.isCompleted,
      isStarred: widget.task.isStarred,
      dueDate: widget.task.dueDate,
      repeat: widget.task.repeat,
      subTasks: updatedSubTasks,
    );
    widget.onUpdate(newTask);
  }

  void _addSubTask(String title) {
    final newSubTask = SubTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
    );
    final updatedSubTasks = [...widget.task.subTasks, newSubTask];

    final newTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      listName: widget.task.listName,
      notes: widget.task.notes,
      isCompleted: widget.task.isCompleted,
      isStarred: widget.task.isStarred,
      dueDate: widget.task.dueDate,
      repeat: widget.task.repeat,
      subTasks: updatedSubTasks,
    );
    widget.onUpdate(newTask);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, result) => _save(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.task.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.onDelete();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: tC,
                  style: theme.textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Task Name',
                  ),
                  onChanged: (_) => _save(),
                ),
                const SizedBox(height: 24),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: widget.task.dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && context.mounted) {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: widget.task.dueDate != null
                            ? TimeOfDay.fromDateTime(widget.task.dueDate!)
                            : TimeOfDay.now(),
                      );
                      if (t != null) {
                        final newTask = Task(
                          id: widget.task.id,
                          title: widget.task.title,
                          listName: widget.task.listName,
                          notes: widget.task.notes,
                          isCompleted: widget.task.isCompleted,
                          isStarred: widget.task.isStarred,
                          dueDate: DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t.hour,
                            t.minute,
                          ),
                          repeat: widget.task.repeat,
                          subTasks: widget.task.subTasks,
                        );
                        widget.onUpdate(newTask);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.task.dueDate == null
                              ? 'Set Date & Time'
                              : '${widget.task.dueDate!.month}/${widget.task.dueDate!.day}  ${widget.task.dueDate!.hour.toString().padLeft(2, '0')}:${widget.task.dueDate!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<Repeat>(
                          value: widget.task.repeat,
                          isExpanded: true,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(16),
                          items: Repeat.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            final newTask = Task(
                              id: widget.task.id,
                              title: widget.task.title,
                              listName: widget.task.listName,
                              notes: widget.task.notes,
                              isCompleted: widget.task.isCompleted,
                              isStarred: widget.task.isStarred,
                              dueDate: widget.task.dueDate,
                              repeat: v!,
                              subTasks: widget.task.subTasks,
                            );
                            widget.onUpdate(newTask);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Subtasks',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                ...widget.task.subTasks.map(
                  (s) => CheckboxListTile(
                    title: Text(
                      s.title,
                      style: TextStyle(
                        decoration: s.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    value: s.isCompleted,
                    onChanged: (v) => _toggleSubTask(s, v),
                  ),
                ),
                TextField(
                  controller: sC,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.add),
                    hintText: 'Add step',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (v) {
                    if (v.isNotEmpty) {
                      _addSubTask(v);
                      sC.clear();
                    }
                  },
                ),
                const Divider(height: 40),
                TextField(
                  controller: nC,
                  maxLines: null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes),
                    hintText: 'Add notes...',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
