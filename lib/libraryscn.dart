import 'dart:io';

import 'package:flutter/material.dart';
import 'loader.dart';
import 'tasklist.dart';
import 'listplayerscn.dart';


class TasklistLibrary extends StatefulWidget {
  const TasklistLibrary({super.key});


  @override
  State<TasklistLibrary> createState() => _TasklistLibraryState();
}


class _TasklistLibraryState extends State<TasklistLibrary> {
  List<String> _tasklistTitles = [];
  TasklistLoader _loader = TasklistLoader();

  @override
  void initState(){
    super.initState();
    () async{
        await _loader.loadTasklistTitles();
        
        if (!mounted) return;
        setState((){
          _tasklistTitles = _loader.getTasklistTitles();
        });
    }();

  }

  @override
  Widget build(BuildContext context) {
    print("MEOW");
    print(_tasklistTitles);
    return Scaffold(
      appBar: AppBar(title: Text("My Onebites"), backgroundColor: Theme.of(context).colorScheme.inversePrimary,),
      body: ListView.builder(
        itemCount: _tasklistTitles.length,
        itemBuilder: (context, index) {
          final title = _tasklistTitles[index];
          return Padding(
            padding: const EdgeInsets.all(42.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).colorScheme.onPrimary,
              child: ListTile(
                title: Text(title),
                onTap: () async {
                  // Navigate to tasklist view
                  Tasklist tasklist = (await _loader.loadTasklist(title))!;
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TasklistPlayer(key: UniqueKey(), tasklist: tasklist),
                    ),
                  );
               
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
