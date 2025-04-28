import 'package:flutter/material.dart';

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
  var steps = <String>[]; // Ordered list of steps

  // Constructor
  FixedStepRegion({required this.steps});

  // Adds a new step at the end of the list
  void addStep(step) {
    steps.add(step);
  }

  @override
  String? next() {
    // Return the current step and move to the next
    if (_idx < steps.length) {
      return steps[_idx++];
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
  late PullMode _pullMode; // How steps are pulled (all or some)
  late StopMode _stopMode; // When to stop pulling steps from this region
  int? _pullN; // (optional) Number of steps to pull if pullRandN is active
  int? _stopN; // (optional) How many times to see steps if untilSetSeenNTimes is active

  UnorderedStepRegion(pullMode, stopMode, int? pullN, int? setN) {
    _pullMode = pullMode;
    _stopMode = stopMode;
    _pullN = pullN;
    _stopN = setN;

    // Validation: pullN must be set if pullRandN mode is used
    if (_pullMode == PullMode.pullRandN) {
      assert(_pullN != null);
    }
    // Validation: stopN must be set if untilSetSeenNTimes mode is used
    if (_stopMode == StopMode.untilSetSeenNTimes) {
      assert(_stopN != null);
    }
  }

  @override
  String? next() {
    // TODO: Implement logic for randomly selecting steps based on pull mode and stop conditions
    return null;
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
  var stepRegions = <StepRegion>[]; // List of regions (fixed and unordered)

  Tasklist({required this.stepRegions});

  // Returns the current active step, or null if none
  String? current() {
    return _currentStep;
  }

  // Moves to the next step, advancing through regions as needed
  String? next() {
    if (_idx < stepRegions.length) {
      var next = null;

      // Continue pulling steps until a non-null step is found or all regions exhausted
      while (next == null && _idx < stepRegions.length) {
        next = stepRegions[_idx].next();
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
