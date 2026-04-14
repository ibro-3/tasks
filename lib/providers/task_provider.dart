import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/task_repository.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;

  List<Task> _tasks = [];
  List<TaskListModel> _lists = [];
  String _currentList = 'My Tasks';

  List<Task> get tasks => _tasks;
  List<TaskListModel> get lists => _lists;
  String get currentList => _currentList;

  TaskProvider(this._repository) {
    loadData();
  }

  Future<void> loadData() async {
    _tasks = _repository.loadTasks();
    _lists = _repository.loadLists();

    bool saveNeeded = false;
    if (!_lists.any((l) => l.name == 'My Day')) {
      _lists.insert(
        0,
        TaskListModel(
          name: 'My Day',
          iconCode: Icons.sunny.codePoint,
          colorValue: Colors.deepPurple.toARGB32(),
        ),
      );
      saveNeeded = true;
    }
    if (!_lists.any((l) => l.name == 'My Tasks')) {
      _lists.insert(
        1,
        TaskListModel(
          name: 'My Tasks',
          iconCode: Icons.check_circle_outline.codePoint,
          colorValue: Colors.indigo.toARGB32(),
        ),
      );
      saveNeeded = true;
    }
    if (saveNeeded) await _saveLists();

    notifyListeners();
  }

  Future<void> _saveTasks() async {
    await _repository.saveTasks(_tasks);
  }

  Future<void> _saveLists() async {
    await _repository.saveLists(_lists);
  }

  void switchList(String name) {
    HapticFeedback.selectionClick();
    _currentList = name;
    notifyListeners();
  }

  Future<void> addTask(
    String title, {
    bool isStarred = false,
    DateTime? dueDate,
    String? notes,
    String? listName,
  }) async {
    String finalTitle = title;
    DateTime? finalDate = dueDate;

    if (finalDate == null) {
      final lower = title.toLowerCase();
      if (lower.contains('today')) {
        finalDate = DateTime.now();
        finalTitle = title
            .replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '')
            .trim();
      } else if (lower.contains('tomorrow')) {
        finalDate = DateTime.now().add(const Duration(days: 1));
        finalTitle = title
            .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
            .trim();
      }
    }

    String targetList = listName ?? _currentList;
    if (targetList == 'Important' || targetList == 'Completed') {
      targetList = 'My Tasks';
    }

    final newTask = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: finalTitle,
      listName: targetList,
      isStarred: isStarred,
      dueDate: finalDate,
      notes: notes ?? '',
    );

    _tasks.add(newTask);
    NotificationService.schedule(newTask);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task task, {bool delete = false}) async {
    if (delete) {
      _tasks.removeWhere((e) => e.id == task.id);
      NotificationService.cancel(task);
      HapticFeedback.mediumImpact();
    } else {
      final index = _tasks.indexWhere((e) => e.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
      }

      if (task.isCompleted) {
        NotificationService.cancel(task);
        _handleRepeat(task);
      } else {
        NotificationService.schedule(task);
      }
    }
    _saveTasks();
    notifyListeners();
  }

  void _handleRepeat(Task task) {
    if (task.repeat != Repeat.none && task.dueDate != null) {
      final next =
          DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          ).add(
            task.repeat == Repeat.daily
                ? const Duration(days: 1)
                : task.repeat == Repeat.weekly
                ? const Duration(days: 7)
                : const Duration(days: 30),
          );

      final newTask = Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: task.title,
        listName: task.listName,
        dueDate: next,
        repeat: task.repeat,
      );
      _tasks.add(newTask);
      NotificationService.schedule(newTask);
    }
  }

  Future<void> toggleComplete(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final existingTask = _tasks[index];
      final updatedTask = Task(
        id: existingTask.id,
        title: existingTask.title,
        isCompleted: !existingTask.isCompleted,
        listName: existingTask.listName,
        isStarred: existingTask.isStarred,
        dueDate: existingTask.dueDate,
        notes: existingTask.notes,
        subTasks: existingTask.subTasks,
        repeat: existingTask.repeat,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> toggleStar(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final existingTask = _tasks[index];
      final updatedTask = Task(
        id: existingTask.id,
        title: existingTask.title,
        isCompleted: existingTask.isCompleted,
        listName: existingTask.listName,
        isStarred: !existingTask.isStarred,
        dueDate: existingTask.dueDate,
        notes: existingTask.notes,
        subTasks: existingTask.subTasks,
        repeat: existingTask.repeat,
      );
      await updateTask(updatedTask);
    }
  }

  void addList(TaskListModel list) {
    _lists.add(list);
    _saveLists();
    notifyListeners();
  }

  Future<void> deleteList(String name) async {
    _lists.removeWhere((l) => l.name == name);
    _tasks.removeWhere((t) => t.listName == name);
    if (_currentList == name) {
      _currentList = 'My Tasks';
    }
    await _saveLists();
    await _saveTasks();
    notifyListeners();
  }

  List<Task> get filteredTasks {
    return _tasks.where((t) {
      if (_currentList == 'Important') return t.isStarred;
      if (_currentList == 'Completed') return t.isCompleted;
      return t.listName == _currentList && !t.isCompleted;
    }).toList()..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return (a.dueDate ?? DateTime(2100)).compareTo(
        b.dueDate ?? DateTime(2100),
      );
    });
  }

  Map<String, List<Task>> get groupedTasks {
    final active = filteredTasks;
    final grouped = <String, List<Task>>{};

    for (var t in active) {
      String key = "Later";
      if (t.dueDate == null) {
        key = "No Date";
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

  static Map<String, List<Task>> groupTasksByDate(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (var t in tasks) {
      String key = "Later";
      if (t.dueDate == null) {
        key = "No Date";
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

  List<Task> searchTasks(String query) {
    return _tasks
        .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
