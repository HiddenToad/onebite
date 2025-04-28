import 'package:flutter/material.dart';

void main() {
  runApp(const OnebiteApp());
}

enum StepRegionType { Fixed, Unordered }

sealed class StepRegion {
  String? next();
  StepRegionType type();
}

class FixedStepRegion extends StepRegion {
  int _idx = 0;
  var steps = <String>[];

  FixedStepRegion({required this.steps});

  void addStep(step) {
    steps.add(step);
  }

  @override
  String? next() {
    if (_idx < steps.length) {
      return steps[_idx++];
    } else {
      return null;
    }
  }

  @override
  StepRegionType type() {
    return StepRegionType.Fixed;
  }
}

enum UnorderedSRPullMode { pullRandN, pullAll }

enum UnorderedSRStopMode { untilGoalConf, untilSetSeen, untilSetSeenNTimes }

class UnorderedStepRegion extends StepRegion {
  var _steps = <String>[];
  late UnorderedSRPullMode _pullMode;
  late UnorderedSRStopMode _stopMode;
  int? _pullN;
  int? _stopN;

  UnorderedStepRegion(pullMode, stopMode, int? pullN, int? setN) {
    _pullMode = pullMode;
    _stopMode = stopMode;
    _pullN = pullN;
    _stopN = setN;

    if (_pullMode == UnorderedSRPullMode.pullRandN) {
      assert(_pullN != null);
    }
    if (_stopMode == UnorderedSRStopMode.untilSetSeenNTimes) {
      assert(_stopN != null);
    }
  }

  @override
  String? next() {
    return null; //TODO unimplemented
  }

  @override
  StepRegionType type() {
    return StepRegionType.Unordered;
  }
}

class Tasklist {
  String? _currentStep;
  int _idx = 0;
  var stepRegions = <StepRegion>[];
  Tasklist({required this.stepRegions});

  String? current() {
    return _currentStep;
  }

  String? next() {
    if (_idx < stepRegions.length) {
      var next = null;

      while (next == null && _idx < stepRegions.length) {
        next = stepRegions[_idx].next();
        if (next != null) {
          break;
        }
        _idx++;
      }
      _currentStep = next;
      return next;
    } else {
      _currentStep = null;
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<OBHome> createState() => _OBHomeState();
}

class _OBHomeState extends State<OBHome> {
  var _finished = false;
  var _current_tasklist = Tasklist(
    stepRegions: [
      FixedStepRegion(
        steps: [
          "Turn on your music",
          "Put down your phone",
          "Pick up room",
          "Pick up bathroom",
        ],
      ),
    ],
  );
  void _finishList() {
    _finished = true;
  }


  void _nextTask() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the OBHome object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(() {
              if (_finished) {
                return "YAAAYY! FINISHED!";
              } else {
                return _current_tasklist.current() ?? "ERROR ERROR HOW HOW";
              }
            }(), style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 20.0),
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
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
