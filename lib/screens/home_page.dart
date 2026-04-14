import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/notification_service.dart';
import '../utils/confetti_painter.dart';
import '../widgets/drawer.dart';
import '../widgets/task_card.dart';
import '../widgets/date_strip.dart';
import '../widgets/new_list_dialog.dart';
import 'detail_screen.dart';
import 'settings_page.dart';

class TaskHomePage extends StatefulWidget {
  final TaskAppState settings;
  final TaskProvider taskProvider;

  const TaskHomePage({
    super.key,
    required this.settings,
    required this.taskProvider,
  });

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _confettiController.addListener(() {
      setState(() {});
      if (_confettiController.status == AnimationStatus.completed) {
        _particles.clear();
      }
    });
    _searchController.addListener(() {
      setState(() {});
    });
    NotificationService.requestPermissions();
    NotificationService.onNotificationTap.listen((taskId) {
      if (taskId != null) _handleNotificationTap(taskId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.taskProvider.loadData();
  }

  void _spawnConfetti() {
    _particles.clear();
    for (int i = 0; i < 40; i++) {
      _particles.add(ConfettiParticle());
    }
    _confettiController.forward(from: 0.0);
  }

  void _handleNotificationTap(String taskId) {
    try {
      final task = widget.taskProvider.tasks.firstWhere((t) => t.id == taskId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: task,
            onUpdate: (nt) => widget.taskProvider.updateTask(nt),
            onDelete: () => widget.taskProvider.updateTask(task, delete: true),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Task not found: $taskId');
    }
  }

  void _onTaskComplete(Task task, bool isCompleted) {
    if (isCompleted) {
      _spawnConfetti();
      HapticFeedback.lightImpact();
      if (widget.settings.soundOn) SystemSound.play(SystemSoundType.click);
    }
    widget.taskProvider.updateTask(task);
  }

  void _switchList(String name) => widget.taskProvider.switchList(name);

  void _startSearch() {
    setState(() {
      _isSearchActive = true;
    });
    _searchFocus.requestFocus();
  }

  void _endSearch() {
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final currentList = provider.currentList;
        final lists = provider.lists;

        List<Task> activeTasks;
        if (_isSearchActive) {
          activeTasks = provider.searchTasks(_searchController.text);
        } else {
          activeTasks = _getActiveTasks(provider, currentList);
        }

        final progress = _calculateProgress(provider.tasks);
        final isCustomList = ![
          'My Day',
          'My Tasks',
          'Important',
          'Completed',
        ].contains(currentList);
        final groupedTasks = _groupTasks(activeTasks);

        return Scaffold(
          key: _scaffoldKey,
          drawer: CustomDrawer(
            theme: theme,
            currentList: currentList,
            lists: lists,
            onSwitchList: _switchList,
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(s: widget.settings),
              ),
            ),
            onAddList: () => showDialog(
              context: context,
              builder: (ctx) => NewListDialog(
                existingNames: lists.map((l) => l.name).toList(),
                onCreate: (name, icon, color) {
                  provider.addList(
                    TaskListModel(
                      name: name,
                      iconCode: icon,
                      colorValue: color,
                    ),
                  );
                  _switchList(name);
                },
              ),
            ),
          ),
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildTaskList(
                context,
                theme,
                currentList,
                activeTasks,
                groupedTasks,
                progress,
                isCustomList,
                provider,
                bottomPadding,
              ),
              _buildBottomBar(theme, bottomPadding),
              if (_confettiController.isAnimating)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ConfettiPainter(
                      _particles,
                      _confettiController.value,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Task> _getActiveTasks(TaskProvider provider, String currentList) {
    return provider.tasks.where((t) {
      if (currentList == 'Important') return t.isStarred;
      if (currentList == 'Completed') return t.isCompleted;
      if (currentList == 'My Day') {
        return t.dueDate != null &&
            t.dueDate!.year == _selectedDate.year &&
            t.dueDate!.month == _selectedDate.month &&
            t.dueDate!.day == _selectedDate.day &&
            !t.isCompleted;
      }
      return t.listName == currentList;
    }).toList()..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return (a.dueDate ?? DateTime(2100)).compareTo(
        b.dueDate ?? DateTime(2100),
      );
    });
  }

  double _calculateProgress(List<Task> tasks) {
    final todayTasks = tasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.day == DateTime.now().day &&
              !t.isCompleted,
        )
        .length;
    final totalToday = tasks
        .where((t) => t.dueDate != null && t.dueDate!.day == DateTime.now().day)
        .length;
    return totalToday == 0 ? 0.0 : todayTasks / totalToday;
  }

  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (var t in tasks) {
      String key = "Later";
      if (t.dueDate == null) {
        key = 'No Date';
      } else {
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (d.isBefore(today)) {
          key = 'Overdue';
        } else if (d.isAtSameMomentAs(today)) {
          key = 'Today';
        } else if (d.difference(today).inDays == 1) {
          key = 'Tomorrow';
        }
      }
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }
    return grouped;
  }

  Widget _buildTaskList(
    BuildContext context,
    ThemeData theme,
    String currentList,
    List<Task> activeTasks,
    Map<String, List<Task>> groupedTasks,
    double progress,
    bool isCustomList,
    TaskProvider provider,
    double bottomPadding,
  ) {
    final groupOrder = ["Overdue", "Today", "Tomorrow", "Later", "No Date"];

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          automaticallyImplyLeading: false,
          title: _isSearchActive
              ? Text(
                  "Results for '${_searchController.text}'",
                  style: const TextStyle(fontSize: 22),
                )
              : (currentList == 'My Day'
                    ? Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: progress.isNaN ? 0 : progress,
                              strokeWidth: 4,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text("My Day"),
                        ],
                      )
                    : Text(currentList)),
          actions: [
            if (isCustomList && !_isSearchActive)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: () =>
                    _confirmDeleteList(context, provider, currentList),
              ),
          ],
        ),
        if (currentList == 'My Day' && !_isSearchActive)
          SliverToBoxAdapter(
            child: DateStrip(
              selectedDate: _selectedDate,
              onDateSelect: (d) => setState(() => _selectedDate = d),
              theme: theme,
            ),
          ),
        if (activeTasks.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 80,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSearchActive ? "No matches" : "All clear",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (activeTasks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  List<Widget> flatList = [];
                  for (var key in groupOrder) {
                    if (groupedTasks[key] != null &&
                        groupedTasks[key]!.isNotEmpty) {
                      if (currentList != 'My Day' || _isSearchActive) {
                        flatList.add(
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Text(
                              key,
                              style: TextStyle(
                                color: key == 'Overdue'
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        );
                      }
                      for (var task in groupedTasks[key]!) {
                        final isOverdue =
                            task.dueDate != null &&
                            task.dueDate!.isBefore(DateTime.now()) &&
                            !task.dueDate!.isAtSameMomentAs(DateTime.now());
                        flatList.add(_buildTaskItem(task, isOverdue, provider));
                      }
                    }
                  }
                  if (i < flatList.length) return flatList[i];
                  return null;
                },
                childCount:
                    activeTasks.length +
                    ((currentList != 'My Day' || _isSearchActive)
                        ? groupedTasks.keys
                              .where((k) => groupedTasks[k]!.isNotEmpty)
                              .length
                        : 0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskItem(Task task, bool isOverdue, TaskProvider provider) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          task.isCompleted = !task.isCompleted;
          _onTaskComplete(task, task.isCompleted);
          return false;
        }
        return true;
      },
      onDismissed: (_) => widget.taskProvider.updateTask(task, delete: true),
      child: TactileTaskCard(
        task: task,
        settings: widget.settings,
        isOverdue: isOverdue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              task: task,
              onUpdate: (nt) => provider.updateTask(nt),
              onDelete: () => provider.updateTask(task, delete: true),
            ),
          ),
        ),
        onCheck: () {
          task.isCompleted = !task.isCompleted;
          _onTaskComplete(task, task.isCompleted);
        },
        onStar: () => provider.toggleStar(task),
      ),
    );
  }

  void _confirmDeleteList(
    BuildContext context,
    TaskProvider provider,
    String listName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete List?"),
        content: Text("All tasks in '$listName' will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              provider.deleteList(listName);
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, double bottomPadding) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      bottom: bottomPadding + 24,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: _isSearchActive
                ? Row(
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(12),
                        icon: const Icon(Icons.arrow_back, size: 28),
                        onPressed: _endSearch,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          decoration: InputDecoration(
                            hintText: "Search tasks...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  )
                : Row(
                    children: [
                      const SizedBox(width: 12),
                      IconButton(
                        padding: const EdgeInsets.all(12),
                        icon: const Icon(Icons.menu, size: 28),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: const EdgeInsets.all(12),
                        icon: const Icon(Icons.search, size: 28),
                        onPressed: _startSearch,
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _showAddSheet(context),
                            child: Container(
                              height: 56,
                              width: 56,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext ctx) {
    final tc = TextEditingController();
    final nc = TextEditingController();
    DateTime? d = widget.taskProvider.currentList == 'My Day'
        ? _selectedDate
        : null;
    bool isStarred = widget.taskProvider.currentList == 'Important';
    bool showNote = false;
    TimeOfDay? t;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(widget.settings.radius),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tc,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "I need to...",
                    border: InputBorder.none,
                    filled: false,
                  ),
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: showNote
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: nc,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: "Add notes...",
                              border: InputBorder.none,
                              filled: true,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (d != null)
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          t != null
                              ? '${d!.month}/${d!.day} ${t!.hour.toString().padLeft(2, '0')}:${t!.minute.toString().padLeft(2, '0')}'
                              : '${d!.month}/${d!.day}',
                        ),
                        onPressed: () => setSheetState(() {
                          d = null;
                          t = null;
                        }),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final dp = await showDatePicker(
                            context: ctx,
                            initialDate: d ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (dp != null) setSheetState(() => d = dp);
                        },
                      ),
                    if (d != null)
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final tp = await showTimePicker(
                            context: ctx,
                            initialTime: t ?? TimeOfDay.now(),
                          );
                          if (tp != null) setSheetState(() => t = tp);
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        showNote
                            ? Icons.description
                            : Icons.description_outlined,
                        color: showNote
                            ? Theme.of(ctx).colorScheme.primary
                            : null,
                      ),
                      onPressed: () =>
                          setSheetState(() => showNote = !showNote),
                    ),
                    IconButton(
                      icon: Icon(
                        isStarred ? Icons.star : Icons.star_border,
                        color: isStarred ? Colors.orange : null,
                      ),
                      onPressed: () =>
                          setSheetState(() => isStarred = !isStarred),
                    ),
                    const Spacer(),
                    FloatingActionButton.small(
                      onPressed: () {
                        if (tc.text.isNotEmpty) {
                          DateTime? finalDate;
                          if (d != null) {
                            finalDate = DateTime(
                              d!.year,
                              d!.month,
                              d!.day,
                              t?.hour ?? 9,
                              t?.minute ?? 0,
                            );
                          }
                          widget.taskProvider.addTask(
                            tc.text,
                            isStarred: isStarred,
                            dueDate: finalDate,
                            notes: nc.text,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
