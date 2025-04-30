import 'bite.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class BiteLoader {
  var _BitesByTitle = <String>[];
  Map<String, Bite> _BiteCache = {};

  List<String> getBiteTitles() {
    return _BitesByTitle;
  }

  Future<void> loadBiteTitles() async {
    final directory = await getApplicationDocumentsDirectory();
    final BiteDirectory = Directory('${directory.path}/Bites');
    if (!await BiteDirectory.exists()) {
      BiteDirectory.create(recursive: true);
    }

    var jsonFiles =
        BiteDirectory
            .listSync()
            .where((entity) => entity.path.endsWith('.json'))
            .toList();

    _BitesByTitle =
        jsonFiles
            .map(
              (file) => file.uri.pathSegments.last.split('.').first,
            ) // Extract file names (titles)
            .toList();
  }

  Future<void> saveBite(Bite Bite) async {
    final directory = await getApplicationDocumentsDirectory();
    final BiteDirectory = Directory('${directory.path}/Bites');
    final file = File('${BiteDirectory.path}/${Bite.title}.json');
    final jsonString = jsonEncode(Bite.toJson());
    _BitesByTitle.add(Bite.title);
    await file.writeAsString(jsonString);
    await loadBiteTitles();
  }

  Future<Bite?> loadBite(String title) async {
    // Check if already loaded
    if (_BiteCache.containsKey(title)) {
      _BiteCache[title]!.restart();
      return _BiteCache[title];
    }

    // Read the file and decode
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/Bites/$title.json';
    final fileContent = await File(filePath).readAsString();
    final json = jsonDecode(fileContent);

    final bite = Bite.fromJson(json);

    // Cache the Bite data for future use
    _BiteCache[title] = bite;

    return bite;
  }
}
