
import 'package:flutter/material.dart';


import 'stepregion.dart';
import 'tasklist.dart';
import 'loader.dart';



void main() {
  runApp(const OnebiteApp());
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
