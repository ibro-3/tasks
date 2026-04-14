import 'enums.dart';

class Task {
  String id;
  String title;
  String listName;
  String notes;
  bool isCompleted;
  bool isStarred;
  DateTime? dueDate;
  Repeat repeat;
  List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.listName = 'My Tasks',
    this.isStarred = false,
    this.dueDate,
    this.notes = '',
    this.subTasks = const [],
    this.repeat = Repeat.none,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'listName': listName,
    'isStarred': isStarred,
    'dueDate': dueDate?.toIso8601String(),
    'notes': notes,
    'subTasks': subTasks.map((s) => s.toMap()).toList(),
    'repeat': repeat.index,
  };

  factory Task.fromMap(Map<String, dynamic> map) {
    final repeatIndex = (map['repeat'] as int?) ?? 0;
    final safeRepeatIndex = repeatIndex.clamp(0, Repeat.values.length - 1);

    List<SubTask> subTasksList = [];
    if (map['subTasks'] != null && map['subTasks'] is List) {
      subTasksList = (map['subTasks'] as List)
          .map((s) => SubTask.fromMap(s as Map<String, dynamic>))
          .toList();
    }

    return Task(
      id: map['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      listName: map['listName'] ?? map['list'] ?? 'My Tasks',
      isStarred: map['isStarred'] ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'])
          : null,
      notes: map['notes'] ?? '',
      repeat: Repeat.values[safeRepeatIndex],
      subTasks: subTasksList,
    );
  }
}

class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubTask.fromMap(Map<String, dynamic> m) => SubTask(
    id: m['id'] ?? '',
    title: m['title'] ?? '',
    isCompleted: m['isCompleted'] ?? false,
  );
}
