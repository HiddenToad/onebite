import 'tasklist.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class TasklistLoader {
  var _tasklistsByTitle = <String>[];
  Map<String, Tasklist> _tasklistCache = {};

  List<String> getTasklistTitles(){
    return _tasklistsByTitle;
  }

  Future<void> loadTasklistTitles() async {
    final directory = await getApplicationDocumentsDirectory();
    final tasklistDirectory = Directory('${directory.path}/tasklists');
    if (!await tasklistDirectory.exists()) {
      tasklistDirectory.create(recursive: true);
    }
    

    var jsonFiles =
        tasklistDirectory
            .listSync()
            .where((entity) => entity.path.endsWith('.json'))
            .toList();

    _tasklistsByTitle =
        jsonFiles
            .map(
              (file) => file.uri.pathSegments.last.split('.').first,
            ) // Extract file names (titles)
            .toList();
  }

  Future<void> saveTasklist(Tasklist tasklist) async {
    final directory = await getApplicationDocumentsDirectory();
    final tasklistDirectory = Directory('${directory.path}/tasklists');
    final file = File('${tasklistDirectory.path}/${tasklist.title}.json');
    final jsonString = jsonEncode(tasklist.toJson());
    _tasklistsByTitle.add(tasklist.title);
    await file.writeAsString(jsonString);
  }

  Future<Tasklist?> loadTasklist(String title) async {
    // Check if already loaded
    if (_tasklistCache.containsKey(title)) {
      _tasklistCache[title]!.restart();
      return _tasklistCache[title];
    }

    // Read the file and decode
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/tasklists/$title.json';
    final fileContent = await File(filePath).readAsString();
    final json = jsonDecode(fileContent);

    final tasklist = Tasklist.fromJson(json);

    // Cache the tasklist data for future use
    _tasklistCache[title] = tasklist;
    
    return tasklist;
  }
}
