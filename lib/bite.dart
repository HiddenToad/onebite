import 'stepregion.dart';

// A full checklist made of multiple step regions
class Bite {
  String title; //Title of the Bite. What are we accomplishing?
  String? _currentStep; // Currently active step
  int _idx = 0; // Index of current region in the overall list
  var _stepRegions = <StepRegion>[]; // List of regions (fixed and unordered)

  Bite({required List<StepRegion> stepRegions, required this.title})
    : _stepRegions = stepRegions;

  void restart() {
    _idx = 0;
    for (var region in _stepRegions) {
      region.restart();
    }
  }

  List<StepRegion> getRegions(){
    return _stepRegions;
  }

  int getIdx() {
    return _idx;
  }

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
        UnorderedStepRegion region => region.stopMode(),
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

  static Bite fromJson(Map<String, dynamic> json) {
    List<StepRegion> regions = [];
    for (var region in json['regions']) {
      regions.add(StepRegion.fromJson(region));
    }
    return Bite(
      title: json['title'] ?? 'Untitled Checklist',
      stepRegions: regions,
    );
  }
}
