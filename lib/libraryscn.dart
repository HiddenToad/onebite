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
  void initState() {
    super.initState();
    () async {
      await _loader.loadTasklistTitles();

      if (!mounted) return;
      setState(() {
        _tasklistTitles = _loader.getTasklistTitles();
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    print("MEOW");
    print(_tasklistTitles);
    return Scaffold(
      appBar: AppBar(
        title: Text("My Onebites"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _tasklistTitles.length > 0
              ? ListView.builder(
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
                          Tasklist tasklist =
                              (await _loader.loadTasklist(title))!;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => TasklistPlayer(
                                    key: UniqueKey(),
                                    tasklist: tasklist,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "You don't have any onebites yet.",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 25.0),

                    ElevatedButton(onPressed: (){ 
                      //TODO: load creator scene
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: Size(125, 55),
                    ),
                    child: Text("Let's make one", style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onPrimary))),
                  ],
                ),
              ),
    );
  }
}
