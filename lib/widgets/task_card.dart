import 'package:flutter/material.dart';
import '../models/task.dart';
import '../main.dart'; 

class TactileTaskCard extends StatefulWidget {
  final Task task;
  final TaskAppState settings;
  final bool isOverdue;
  final VoidCallback onTap, onCheck, onStar;

  const TactileTaskCard({super.key, required this.task, required this.settings, required this.isOverdue, required this.onTap, required this.onCheck, required this.onStar});
  @override State<TactileTaskCard> createState() => _TactileTaskCardState();
}

class _TactileTaskCardState extends State<TactileTaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _s = Tween<double>(begin: 1.0, end: 0.96).animate(_c); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    
    return GestureDetector(
      onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: widget.settings.isCompact ? 2 : 6),
        decoration: BoxDecoration(
          // Use Surface Container for the card background
          color: task.isCompleted 
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4) 
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(widget.settings.radius),
          border: Border.all(
            color: widget.isOverdue && !task.isCompleted 
                ? theme.colorScheme.error.withOpacity(0.5) 
                : theme.colorScheme.outlineVariant.withOpacity(task.isCompleted ? 0.1 : 0.3)
          )
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Transform.scale(
            scale: 1.1, 
            child: Checkbox(
              value: task.isCompleted, 
              onChanged: (_) => widget.onCheck(), 
              shape: const CircleBorder(),
              // FIX: Removed activeColor: Colors.green
              // It now uses the Theme's checkboxTheme (Primary Color)
            )
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Hero(
              tag: 'title_${task.id}', 
              child: Material(
                color: Colors.transparent, 
                child: Text(
                  task.title, 
                  style: TextStyle(
                    fontSize: 16, 
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null, 
                    // Use OnSurface variant for better readability
                    color: task.isCompleted ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface, 
                    fontWeight: FontWeight.w600
                  )
                )
              )
            ),
            if (task.dueDate != null) 
              Padding(
                padding: const EdgeInsets.only(top: 4), 
                child: Text(
                  "${task.dueDate!.month}/${task.dueDate!.day}", 
                  style: TextStyle(
                    fontSize: 12, 
                    // Overdue uses Error color, otherwise Primary color for the date
                    color: widget.isOverdue && !task.isCompleted ? theme.colorScheme.error : theme.colorScheme.primary, 
                    fontWeight: FontWeight.bold
                  )
                )
              )
          ])),
          IconButton(
            // Star uses Tertiary or Orange depending on preference. Keeping Orange for standard "Star" feel,
            // but you could change Colors.orange to theme.colorScheme.tertiary
            icon: Icon(
              task.isStarred ? Icons.star : Icons.star_border, 
              color: task.isStarred ? Colors.orange : theme.colorScheme.outline
            ), 
            onPressed: widget.onStar
          )
        ]))
      )),
    );
  }
}