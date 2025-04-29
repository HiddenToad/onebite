import 'utils.dart';

// Types of step regions: either a fixed order or an unordered set of steps
enum StepRegionType { Fixed, Unordered }

// Abstract base class for any region of steps
sealed class StepRegion {
  // Returns the next step string, or null if there are no steps left
  String? next();

  // Returns the type of this step region (Fixed or Unordered)
  StepRegionType type();

  Map<String, dynamic> toJson();

  void restart();

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

  @override
  void restart() {
    _idx = 0;
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
  StopMode stopMode() {
    return _stopMode;
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


  @override void restart(){
    if (_pullMode == PullMode.pullRandN) {
      assert(_pullN != null);
      assert((_pullN!) <= _steps.length);
      _activeSubset = randomSubset(_steps, _pullN!);
    } else {
      _activeSubset = randomSubset(_steps, _steps.length); //still randomize
    }

    _backupSubset = List.from(_activeSubset);
    _subsetCycleCount = 0;  
    goalConfirmed = false;
    // Validation: stopN must be set if untilSetSeenNTimes mode is used
    if (_stopMode == StopMode.untilSetSeenNTimes) {
      assert(_stopN != null);
    }
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
