import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

List<T> randomSubset<T>(List<T> list, int n) {
  if (n >= list.length) {
    return List<T>.from(list)..shuffle();
  }
  var rng = Random();
  var copy = List<T>.from(list);
  copy.shuffle(rng);
  return copy.take(n).toList();
}

extension SafePop<T> on List<T> {
  T? popOrNull() {
    if (isEmpty) return null;
    return removeLast();
  }
}

void main() {
  runApp(const OnebiteApp());
}

// Types of step regions: either a fixed order or an unordered set of steps
enum StepRegionType { Fixed, Unordered }

// Abstract base class for any region of steps
sealed class StepRegion {
  // Returns the next step string, or null if there are no steps left
  String? next();

  // Returns the type of this step region (Fixed or Unordered)
  StepRegionType type();

  Map<String, dynamic> toJson();

  static StepRegion fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'fixed':
        return FixedStepRegion.fromJson(json);
      case 'unordered':
        return UnorderedStepRegion.fromJson(json);
      default:
        throw Exception('Unknown StepRegion type: ${json['type']}');
    }
  }
}

// A region where steps are performed in a fixed, linear order
class FixedStepRegion extends StepRegion {
  int _idx = 0; // Tracks the current position in the list
  var _steps = <String>[]; // Ordered list of steps

  // Constructor
  FixedStepRegion({required List<String> steps}) : _steps = steps;

  // Adds a new step at the end of the list
  void addStep(step) {
    _steps.add(step);
  }

  static FixedStepRegion fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'fixed');
    return FixedStepRegion(steps: List<String>.from(json['steps']));
  }

  @override
  String? next() {
    // Return the current step and move to the next
    if (_idx < _steps.length) {
      return _steps[_idx++];
    } else {
      return null; // No more steps
    }
  }

  @override
  StepRegionType type() {
    return StepRegionType.Fixed;
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": "fixed", "steps": _steps};
  }
}

// Set-building modes for unordered step regions
enum PullMode { pullRandN, pullAll }

// Stop conditions for unordered step regions
enum StopMode { untilGoalConf, untilSetSeen, untilSetSeenNTimes }

// A region where steps are performed in an unordered/randomized fashion
class UnorderedStepRegion extends StepRegion {
  var _steps = <String>[]; // List of available steps
  var _activeSubset = <String>[]; // The actual subset being worked on
  var _backupSubset = <String>[]; //Backup for modifying subset
  PullMode _pullMode; // How steps are pulled (all or some)
  StopMode _stopMode; // When to stop pulling steps from this region
  int? _pullN; // Number of steps to pull if pullRandN is active
  int? _stopN; // How many times to see steps if untilSetSeenNTimes is active
  int _subsetCycleCount = 0;
  String? _goal;
  bool goalConfirmed = false;

  UnorderedStepRegion({
    required List<String> steps,
    required PullMode pullMode,
    required StopMode stopMode,
    int? pullN,
    int? stopN,
    String? goal,
  }) : _steps = steps,
       _pullMode = pullMode,
       _stopMode = stopMode,
       _pullN = pullN,
       _stopN = stopN,
       _goal = goal {
    // Validation: pullN must be set if pullRandN mode is used
    if (_pullMode == PullMode.pullRandN) {
      assert(_pullN != null);
      assert((_pullN!) <= _steps.length);
      _activeSubset = randomSubset(_steps, _pullN!);
    } else {
      _activeSubset = randomSubset(_steps, _steps.length); //still randomize
    }

    _backupSubset = List.from(_activeSubset);

    // Validation: stopN must be set if untilSetSeenNTimes mode is used
    if (_stopMode == StopMode.untilSetSeenNTimes) {
      assert(_stopN != null);
    } else if (_stopMode == StopMode.untilGoalConf) {
      assert(goal != null);
      _goal = goal;
    }
  }

  String? goalText() {
    return _goal;
  }

  static UnorderedStepRegion fromJson(Map<String, dynamic> json) {
    return UnorderedStepRegion(
      steps: List<String>.from(json['steps']),
      pullMode: PullMode.values.byName(json['pullMode']),
      stopMode: StopMode.values.byName(json['stopMode']),
      pullN: json['pullN'],
      stopN: json['stopN'],
      goal: json['goal'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'unordered',
      'steps': _steps,
      'pullMode': _pullMode.name,
      'stopMode': _stopMode.name,
      'pullN': _pullN,
      'stopN': _stopN,
      'goal': _goal,
    };
  }

  @override
  String? next() {
    switch (_stopMode) {
      case StopMode.untilSetSeen:
        return _activeSubset
            .popOrNull(); //Remove pre-randomized tasks until empty
      case StopMode.untilSetSeenNTimes:
        if (_subsetCycleCount >= _stopN!) {
          //Stop after N cycles
          return null;
        } else {
          var nextTask =
              _activeSubset.popOrNull(); //Remove pre randomized tasks...
          if (nextTask == null) {
            // Until empty, then inc count and refill
            _subsetCycleCount++;
            _backupSubset = randomSubset(_backupSubset, _backupSubset.length);
            _activeSubset = List.from(_backupSubset);
            nextTask = _activeSubset.popOrNull();
          }
          return nextTask;
        }
      case StopMode.untilGoalConf:
        if (goalConfirmed) {
          //Stop after goal completed
          return null;
        } else {
          var nextTask =
              _activeSubset.popOrNull(); //Remove pre randomized tasks...
          if (nextTask == null) {
            //and refill, start anew
            _backupSubset = randomSubset(_backupSubset, _backupSubset.length);
            _activeSubset = List.from(_backupSubset);
            nextTask = _activeSubset.popOrNull();
          }
          return nextTask;
        }
    }
  }

  @override
  StepRegionType type() {
    return StepRegionType.Unordered;
  }
}

// A full checklist made of multiple step regions
class Tasklist {
  String title; //Title of the tasklist. What are we accomplishing?
  String? _currentStep; // Currently active step
  int _idx = 0; // Index of current region in the overall list
  var _stepRegions = <StepRegion>[]; // List of regions (fixed and unordered)

  Tasklist({required stepRegions, required this.title})
    : _stepRegions = stepRegions;

  String? currentStep() {
    return _currentStep;
  }

  StepRegionType currentRegionType() {
    return _stepRegions[_idx].type();
  }

  StopMode? currentRegionStopMode() {
    if (_idx < _stepRegions.length) {
      return switch (_stepRegions[_idx]) {
        FixedStepRegion _ => null,
        UnorderedStepRegion region => region._stopMode,
      };
    } else {
      return null;
    }
  }

  String? currentRegionGoalText() {
    return switch (_stepRegions[_idx]) {
      FixedStepRegion _ => null,
      UnorderedStepRegion region => region.goalText(),
    };
  }

  void confirmGoal() {
    assert(_stepRegions[_idx].type() == StepRegionType.Unordered);
    switch (_stepRegions[_idx]) {
      case UnorderedStepRegion region:
        region.goalConfirmed = true;
        break;
      case _:
        break; //unreachable
    }
  }

  // Moves to the next step, advancing through regions as needed
  String? next() {
    if (_idx < _stepRegions.length) {
      String? next;

      // Continue pulling steps until a non-null step is found or all regions exhausted
      while (next == null && _idx < _stepRegions.length) {
        next = _stepRegions[_idx].next();
        if (next != null) {
          break;
        }
        _idx++; // Move to next region if current is exhausted
      }
      _currentStep = next;
      return next;
    } else {
      _currentStep = null; // No more steps in any region
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'regions': _stepRegions.map((region) => region.toJson()).toList(),
    };
  }

  static Tasklist fromJson(Map<String, dynamic> json) {
    List<StepRegion> regions = [];
    for (var region in json['regions']) {
      regions.add(StepRegion.fromJson(region));
    }
    return Tasklist(
      title: json['title'] ?? 'Untitled Checklist',
      stepRegions: regions,
    );
  }
}

class TasklistLoader {
  var _tasklistsByTitle = <String>[];
  Map<String, Tasklist> _tasklistCache = {};

  Future<void> loadTasklistTitles() async {
    final directory = await getApplicationDocumentsDirectory();
    final tasklistDirectory = Directory('${directory.path}/tasklists');
    print(tasklistDirectory.path);
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

  Future<void> saveTasklist(Tasklist tasklist) async{
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

class OnebiteApp extends StatelessWidget {
  const OnebiteApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'onebite',
      theme: ThemeData(
        // This is the theme of the application.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan.shade200,
          brightness: Brightness.dark,
        ),
      ),
      home: const OBHome(title: 'onebite'),
    );
  }
}

class OBHome extends StatefulWidget {
  const OBHome({super.key, required this.title});

  final String title;

  @override
  State<OBHome> createState() => _OBHomeState();
}

class _OBHomeState extends State<OBHome> {
  var _finished = false;
  var _loader = TasklistLoader();

  final _current_tasklist = Tasklist(
    title: "Clean my room",
    stepRegions: [
      FixedStepRegion(steps: ["Turn on your music", "Put down your phone"]),
      UnorderedStepRegion(
        steps: [
          "Pick up anything red",
          "Pick up anything green",
          "Pick up anything brown",
          "pick up any books",
          "pick up anything yellow",
          "pick up anything blue",
          "pick up any towels",
        ],
        pullMode: PullMode.pullAll,
        stopMode: StopMode.untilGoalConf,
        stopN: 2,
        goal: "Can you see the floor pretty well?",
      ),
      FixedStepRegion(steps: ["Pick up any trash/scraps", "make your bed"]),
    ],
  );
  void _finishList() {
    _finished = true;
    //_loader.saveTasklist(_current_tasklist);
  }

  void confirmGoal() {
    setState(() {
      _current_tasklist.confirmGoal();
    });
    _nextTask();
  }

  void _nextTask() {
    setState(() {
      if (_current_tasklist.next() == null) {
        _finishList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loader.loadTasklistTitles();
    _nextTask();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(() {
              if (_finished) {
                return "YAAAYY! FINISHED!";
              } else {
                return _current_tasklist.currentStep()!;
              }
            }(), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _nextTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: Size(95, 50),
              ),
              child: const Icon(Icons.done),
            ),
          ],
        ),
      ),

      //neat trick: no need to check that the current type is
      //Unordered, because if the stop mode is non-null,
      //it MUST be Unordered.

      //This is the goal thumbs up and goal text
      //that appears while waiting on goal conf.
      floatingActionButton:
          (_current_tasklist.currentRegionStopMode() == StopMode.untilGoalConf
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _current_tasklist.currentRegionGoalText()!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  FloatingActionButton.large(
                    onPressed: confirmGoal,
                    child: Transform.scale(
                      scaleX: 0.95,
                      scaleY: 1.05,
                      child: Icon(Icons.thumb_up_sharp),
                    ),
                  ),
                ],
              )
              : null),
    );
  }
}
