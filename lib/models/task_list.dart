import 'package:flutter/material.dart';

class TaskListModel {
  String name;
  int iconCode;
  int colorValue;

  TaskListModel({
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'iconCode': iconCode,
    'colorValue': colorValue,
  };

  factory TaskListModel.fromMap(Map<String, dynamic> map) => TaskListModel(
    name: map['name'],
    iconCode: map['iconCode'] ?? Icons.folder.codePoint,
    colorValue: map['colorValue'] ?? Colors.indigo.value,
  );
}