import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final Function(String) onNav;
  TaskSearchDelegate(this.tasks, this.onNav);
  
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) => buildSuggestions(context);
  
  @override Widget buildSuggestions(BuildContext context) {
    final res = tasks.where((t) => t.title.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: res.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(res[i].title),
        subtitle: Text(res[i].listName),
        onTap: () { close(c, null); onNav(res[i].listName); }
      )
    );
  }
}