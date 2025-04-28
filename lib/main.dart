import 'package:flutter/material.dart';
import 'dart:math';

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
  String? _currentStep; // Currently active step
  int _idx = 0; // Index of current region in the overall list
  var _stepRegions = <StepRegion>[]; // List of regions (fixed and unordered)

  Tasklist({required stepRegions}) : _stepRegions = stepRegions;

  // Returns the current active step, or null if none
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
  final _current_tasklist = Tasklist(
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
