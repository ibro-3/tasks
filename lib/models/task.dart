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

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    isCompleted: map['isCompleted'],
    listName: map['listName'] ?? map['list'] ?? 'My Tasks',
    isStarred: map['isStarred'],
    dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    notes: map['notes'],
    repeat: Repeat.values[map['repeat'] ?? 0],
    subTasks: (map['subTasks'] as List).map((s) => SubTask.fromMap(s)).toList(),
  );
}

class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory SubTask.fromMap(Map<String, dynamic> m) => SubTask(
    id: m['id'], title: m['title'], isCompleted: m['isCompleted'],
  );
}