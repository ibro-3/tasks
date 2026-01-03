import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // For TaskAppState
import '../models/task.dart';
import '../models/task_list.dart';
import '../models/enums.dart'; // <--- ADDED THIS IMPORT TO FIX THE ERROR
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
  const TaskHomePage({super.key, required this.settings});
  @override State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<Task> tasks = [];
  List<TaskListModel> lists = [TaskListModel(name: 'My Day', iconCode: Icons.sunny.codePoint, colorValue: Colors.deepPurple.value), TaskListModel(name: 'My Tasks', iconCode: Icons.check_circle_outline.codePoint, colorValue: Colors.indigo.value)];
  String currentList = 'My Tasks';
  DateTime _selectedDate = DateTime.now();
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _confettiController.addListener(() { setState(() {}); if (_confettiController.status == AnimationStatus.completed) _particles.clear(); });
    _searchController.addListener(() { setState(() {}); });
    _loadData();
    NotificationService.requestPermissions();
    NotificationService.onNotificationTap.listen((taskId) { if (taskId != null) _handleNotificationTap(taskId); });
  }

  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _confettiController.dispose(); _searchController.dispose(); _searchFocus.dispose(); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _loadData(); }

  void _spawnConfetti() { _particles.clear(); for (int i = 0; i < 40; i++) { _particles.add(ConfettiParticle()); } _confettiController.forward(from: 0.0); }
  void _handleNotificationTap(String taskId) { try { final task = tasks.firstWhere((t) => t.id == taskId); Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, onUpdate: (nt) => _modifyTask(nt), onDelete: () => _modifyTask(task, delete: true)))); } catch (e) {} }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('tasks') != null) tasks = (jsonDecode(p.getString('tasks')!) as List).map((i) => Task.fromMap(i)).toList();
    if (p.getString('lists_v9') != null) lists = (jsonDecode(p.getString('lists_v9')!) as List).map((i) => TaskListModel.fromMap(i)).toList();
    bool saveNeeded = false;
    if (!lists.any((l) => l.name == 'My Day')) { lists.insert(0, TaskListModel(name: 'My Day', iconCode: Icons.sunny.codePoint, colorValue: Colors.deepPurple.value)); saveNeeded = true; }
    if (!lists.any((l) => l.name == 'My Tasks')) { lists.insert(1, TaskListModel(name: 'My Tasks', iconCode: Icons.check_circle_outline.codePoint, colorValue: Colors.indigo.value)); saveNeeded = true; }
    if (saveNeeded) _saveData();
    setState(() {});
  }

  Future<void> _saveData() async { final p = await SharedPreferences.getInstance(); p.setString('tasks', jsonEncode(tasks.map((t) => t.toMap()).toList())); p.setString('lists_v9', jsonEncode(lists.map((l) => l.toMap()).toList())); }

  void _addTask(String title, {bool isStarred = false, DateTime? dueDate, String? notes}) {
    String finalTitle = title; DateTime? finalDate = dueDate;
    if (finalDate == null) {
      final lower = title.toLowerCase();
      if (lower.contains('today')) { finalDate = DateTime.now(); finalTitle = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim(); } 
      else if (lower.contains('tomorrow')) { finalDate = DateTime.now().add(const Duration(days: 1)); finalTitle = title.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim(); }
    }
    String targetList = currentList;
    if (currentList == 'Important' || currentList == 'Completed') targetList = 'My Tasks';
    final newTask = Task(id: DateTime.now().toString(), title: finalTitle, listName: targetList, isStarred: isStarred, dueDate: finalDate, notes: notes ?? '');
    setState(() => tasks.add(newTask));
    NotificationService.schedule(newTask);
    _saveData();
  }

  void _modifyTask(Task t, {bool delete = false}) {
    setState(() {
      if (delete) {
        tasks.removeWhere((e) => e.id == t.id); NotificationService.cancel(t); HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted '${t.title}'"), action: SnackBarAction(label: "Undo", textColor: Colors.white, onPressed: () => _modifyTask(t))));
      } else {
        final index = tasks.indexWhere((e) => e.id == t.id);
        if (index != -1) tasks[index] = t; else tasks.add(t);
        if (t.isCompleted) { 
          _spawnConfetti(); 
          HapticFeedback.lightImpact(); 
          NotificationService.cancel(t); 
          if (widget.settings.soundOn) SystemSound.play(SystemSoundType.click); 
          
          // Logic for Repeating Tasks (Requires Repeat Enum)
          if (t.repeat != Repeat.none && t.dueDate != null) { 
            final next = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day).add(t.repeat == Repeat.daily ? const Duration(days: 1) : t.repeat == Repeat.weekly ? const Duration(days: 7) : const Duration(days: 30)); 
            final newTask = Task(id: DateTime.now().toString(), title: t.title, listName: t.listName, dueDate: next, repeat: t.repeat); 
            tasks.add(newTask); 
            NotificationService.schedule(newTask); 
          } 
        } else { NotificationService.schedule(t); }
      }
    });
    _saveData();
  }

  void _switchList(String name) { HapticFeedback.selectionClick(); setState(() { currentList = name; if (name != 'My Day') _selectedDate = DateTime.now(); }); }
  void _startSearch() { setState(() { _isSearchActive = true; }); _searchFocus.requestFocus(); }
  void _endSearch() { setState(() { _isSearchActive = false; _searchController.clear(); }); FocusScope.of(context).unfocus(); }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    List<Task> activeTasks;
    if (_isSearchActive) { activeTasks = tasks.where((t) => t.title.toLowerCase().contains(_searchController.text.toLowerCase())).toList(); } 
    else { activeTasks = tasks.where((t) { if (currentList == 'Important') return t.isStarred; if (currentList == 'Completed') return t.isCompleted; if (currentList == 'My Day') return t.dueDate != null && t.dueDate!.year == _selectedDate.year && t.dueDate!.month == _selectedDate.month && t.dueDate!.day == _selectedDate.day && !t.isCompleted; return t.listName == currentList; }).toList(); }
    activeTasks.sort((a, b) { if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1; return (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100)); });

    final progress = tasks.isEmpty ? 0.0 : (tasks.where((t) => t.dueDate != null && t.dueDate!.day == DateTime.now().day && !t.isCompleted).length) / (tasks.where((t) => t.dueDate != null && t.dueDate!.day == DateTime.now().day).length);
    final isCustomList = !['My Day', 'My Tasks', 'Important', 'Completed'].contains(currentList);
    final groupedTasks = <String, List<Task>>{};
    for (var t in activeTasks) { String key = "Later"; if (t.dueDate == null) key = "No Date"; else { final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day); final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); if (d.isBefore(today)) key = "Overdue"; else if (d.isAtSameMomentAs(today)) key = "Today"; else if (d.difference(today).inDays == 1) key = "Tomorrow"; } if (!groupedTasks.containsKey(key)) groupedTasks[key] = []; groupedTasks[key]!.add(t); }
    final groupOrder = ["Overdue", "Today", "Tomorrow", "Later", "No Date"];

    // In lib/screens/home_page.dart

    return Scaffold(
      key: _scaffoldKey, 
      // Inside build() -> Scaffold -> drawer:
      drawer: CustomDrawer(
        theme: theme,
        currentList: currentList,
        lists: lists,
        onSwitchList: _switchList,
        onSettings: () {
          // FIX: Removed Navigator.pop(context); here.
          Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(s: widget.settings)));
        },
        onAddList: () {
          // FIX: Removed Navigator.pop(context); here.
          showDialog(
              context: context,
              builder: (ctx) => NewListDialog(
                  existingNames: lists.map((l) => l.name).toList(),
                  onCreate: (name, icon, color) {
                    setState(() {
                      lists.add(TaskListModel(name: name, iconCode: icon, colorValue: color));
                      currentList = name;
                    });
                    _saveData();
                  }));
        },
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(fit: StackFit.expand, children: [
        CustomScrollView(slivers: [
          SliverAppBar.large(automaticallyImplyLeading: false, title: _isSearchActive ? Text("Results for '${_searchController.text}'", style: const TextStyle(fontSize: 22)) : (currentList == 'My Day' ? Row(children: [SizedBox(width: 24, height: 24, child: CircularProgressIndicator(value: progress.isNaN ? 0 : progress, strokeWidth: 4, backgroundColor: theme.colorScheme.surfaceContainerHighest)), const SizedBox(width: 16), const Text("My Day")]) : Text(currentList)), actions: [if (isCustomList && !_isSearchActive) IconButton(icon: Icon(Icons.delete_outline, color: theme.colorScheme.error), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Delete List?"), content: Text("All tasks in '$currentList' will be lost."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), FilledButton(style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error), onPressed: () { setState(() { lists.removeWhere((l) => l.name == currentList); tasks.removeWhere((t) => t.listName == currentList); currentList = 'My Tasks'; }); _saveData(); Navigator.pop(ctx); }, child: const Text("Delete"))])))],),
          if (currentList == 'My Day' && !_isSearchActive) SliverToBoxAdapter(child: DateStrip(selectedDate: _selectedDate, onDateSelect: (d) => setState(() => _selectedDate = d), theme: theme)),
          if (activeTasks.isEmpty) SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_available_rounded, size: 80, color: theme.colorScheme.surfaceContainerHighest), const SizedBox(height: 20), Text(_isSearchActive ? "No matches" : "All clear", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary))]))),
          if (activeTasks.isNotEmpty) SliverPadding(padding: const EdgeInsets.only(bottom: 140), sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
            List<Widget> flatList = [];
            for (var key in groupOrder) {
              if (groupedTasks[key] != null && groupedTasks[key]!.isNotEmpty) {
                if (currentList != 'My Day' || _isSearchActive) flatList.add(Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), child: Text(key, style: TextStyle(color: key == "Overdue" ? theme.colorScheme.error : theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0))));
                for (var task in groupedTasks[key]!) {
                  final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.dueDate!.isAtSameMomentAs(DateTime.now());
                  flatList.add(Dismissible(key: Key(task.id), background: Container(color: Colors.green, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 24), child: const Icon(Icons.check, color: Colors.white)), secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), child: const Icon(Icons.delete, color: Colors.white)), confirmDismiss: (dir) async { if (dir == DismissDirection.startToEnd) { task.isCompleted = !task.isCompleted; _modifyTask(task); return false; } return true; }, onDismissed: (_) => _modifyTask(task, delete: true), child: TactileTaskCard(task: task, settings: widget.settings, isOverdue: isOverdue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, onUpdate: (nt) => _modifyTask(nt), onDelete: () => _modifyTask(task, delete: true)))), onCheck: () { task.isCompleted = !task.isCompleted; _modifyTask(task); }, onStar: () { task.isStarred = !task.isStarred; _modifyTask(task); })));
                }
              }
            }
            if (i < flatList.length) return flatList[i]; return null;
          }, childCount: activeTasks.length + ((currentList != 'My Day' || _isSearchActive) ? groupedTasks.keys.where((k) => groupedTasks[k]!.isNotEmpty).length : 0)))),
        ]),
        
        AnimatedPositioned(duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic, bottom: bottomPadding + 24, left: 16, right: 16, child: ClipRRect(borderRadius: BorderRadius.circular(32), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(height: 80, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer.withOpacity(0.8), borderRadius: BorderRadius.circular(32), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2))), child: _isSearchActive ? Row(children: [IconButton(padding: const EdgeInsets.all(12), icon: const Icon(Icons.arrow_back, size: 28), onPressed: _endSearch), Expanded(child: TextField(controller: _searchController, focusNode: _searchFocus, decoration: InputDecoration(hintText: "Search tasks...", border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => _searchController.clear()) : null), style: theme.textTheme.bodyLarge)), const SizedBox(width: 16)]) : Row(children: [const SizedBox(width: 12), IconButton(padding: const EdgeInsets.all(12), icon: const Icon(Icons.menu, size: 28), onPressed: () => _scaffoldKey.currentState?.openDrawer()), const SizedBox(width: 4), IconButton(padding: const EdgeInsets.all(12), icon: const Icon(Icons.search, size: 28), onPressed: _startSearch), const Spacer(), Padding(padding: const EdgeInsets.only(right: 12), child: Material(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(24), child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => _showAddSheet(context), child: Container(height: 56, width: 56, alignment: Alignment.center, child: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary, size: 32))))) ]))))),
        
        if (_confettiController.isAnimating) Positioned.fill(child: CustomPaint(painter: ConfettiPainter(_particles, _confettiController.value))),
      ]),
    );
  }

  void _showAddSheet(BuildContext ctx) {
    final tc = TextEditingController(); final nc = TextEditingController(); DateTime? d = currentList == 'My Day' ? _selectedDate : null; bool isStarred = currentList == 'Important'; bool showNote = false;
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => StatefulBuilder(builder: (context, setSheetState) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20), child: Container(decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surface, borderRadius: BorderRadius.circular(widget.settings.radius)), padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: tc, autofocus: true, decoration: const InputDecoration(hintText: "I need to...", border: InputBorder.none, filled: false), style: Theme.of(ctx).textTheme.headlineSmall),
          AnimatedSize(duration: const Duration(milliseconds: 300), child: showNote ? Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: nc, maxLines: 3, decoration: const InputDecoration(hintText: "Add notes...", border: InputBorder.none, filled: true))) : const SizedBox()),
          const SizedBox(height: 16),
          Row(children: [
             if (d != null) ActionChip(avatar: const Icon(Icons.calendar_today, size: 16), label: Text("${d!.month}/${d!.day}"), onPressed: () => setSheetState(() => d = null)) else IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async { final dp = await showDatePicker(context: ctx, initialDate: d ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100)); if(dp!=null) setSheetState(()=> d = dp); }),
             IconButton(icon: Icon(showNote ? Icons.description : Icons.description_outlined, color: showNote ? Theme.of(ctx).colorScheme.primary : null), onPressed: () => setSheetState(() => showNote = !showNote)),
             IconButton(icon: Icon(isStarred ? Icons.star : Icons.star_border, color: isStarred ? Colors.orange : null), onPressed: () => setSheetState(() => isStarred = !isStarred)),
             const Spacer(),
             FloatingActionButton.small(onPressed: () { if (tc.text.isNotEmpty) { _addTask(tc.text, isStarred: isStarred, dueDate: d, notes: nc.text); Navigator.pop(ctx); } }, child: const Icon(Icons.arrow_upward))
          ])])))));
  }
}