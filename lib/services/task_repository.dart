import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_list.dart';

class TaskRepository {
  static const String _tasksKey = 'tasks';
  static const String _listsKey = 'lists';

  final SharedPreferences _prefs;

  TaskRepository(this._prefs);

  List<Task> loadTasks() {
    final data = _prefs.getString(_tasksKey);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return [];
      return decoded
          .map((i) => Task.fromMap(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    await _prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toMap()).toList()),
    );
  }

  List<TaskListModel> loadLists() {
    final data = _prefs.getString(_listsKey);
    if (data == null) return _defaultLists();
    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return _defaultLists();
      return decoded
          .map((i) => TaskListModel.fromMap(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading lists: $e');
      return _defaultLists();
    }
  }

  Future<void> saveLists(List<TaskListModel> lists) async {
    await _prefs.setString(
      _listsKey,
      jsonEncode(lists.map((l) => l.toMap()).toList()),
    );
  }

  List<TaskListModel> _defaultLists() {
    return [
      TaskListModel(
        name: 'My Day',
        iconCode: Icons.sunny.codePoint,
        colorValue: Colors.deepPurple.toARGB32(),
      ),
      TaskListModel(
        name: 'My Tasks',
        iconCode: Icons.check_circle_outline.codePoint,
        colorValue: Colors.indigo.toARGB32(),
      ),
    ];
  }
}
