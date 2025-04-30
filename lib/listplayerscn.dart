import 'package:flutter/material.dart';
import 'stepregion.dart';
import 'bite.dart';

class BitePlayer extends StatefulWidget {
  const BitePlayer({super.key, required this.bite});

  final Bite bite;
  final String title = "onebite";

  @override
  State<BitePlayer> createState() =>
      _BitePlayerState(bite: bite);
}

class _BitePlayerState extends State<BitePlayer> {
  _BitePlayerState({required bite})
    : _current_bite = bite,
      _finished = false;

  var _finished = false;

  /* = Bite(
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
  )*/

  Bite _current_bite;

  void _finishList() {
    _finished = true;
    //_loader.saveBite(_current_bite);
  }

  void confirmGoal() {
    setState(() {
      _current_bite.confirmGoal();
    });
    _nextTask();
  }

  void _nextTask() {
    setState(() {
      if (_current_bite.next() == null) {
        _finishList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _finished = false;
      _current_bite = widget.bite;
      _current_bite.restart();
    });
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
                return _current_bite.currentStep()!;
              }
            }(), style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 20.0),
            (!_finished
                ? ElevatedButton(
                  onPressed: _nextTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: Size(95, 50),
                  ),
                  child: const Icon(Icons.done),
                )
                : SizedBox.shrink()),
          ],
        ),
      ),

      //neat trick: no need to check that the current type is
      //Unordered, because if the stop mode is non-null,
      //it MUST be Unordered.

      //This is the goal thumbs up and goal text
      //that appears while waiting on goal conf.
      floatingActionButton:
          (_current_bite.currentRegionStopMode() == StopMode.untilGoalConf
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _current_bite.currentRegionGoalText()!,
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
