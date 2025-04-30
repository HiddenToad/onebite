import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bite.dart';
import 'stepregion.dart';
import 'loader.dart';

class BiteBuilder extends StatefulWidget {
  const BiteBuilder({super.key, this.lastSavedBite, required this.editing});
  final Bite? lastSavedBite;
  final bool editing;
  @override
  State<BiteBuilder> createState() =>
      _BiteBuilderState(lastSavedBite: lastSavedBite, editing: editing);
}

class _BiteBuilderState extends State<BiteBuilder> {
  _BiteBuilderState({this.lastSavedBite, required this.editing});
  bool editing;
  Bite? lastSavedBite;
  var regions = <StepRegion>[];
  var loader = BiteLoader();
  late List<DropdownMenuItem<PullMode>> _pullModeItems;
  late List<DropdownMenuItem<StopMode>> _stopModeItems;

  bool isDirty() {
    if (regions.isEmpty) return false;
    if (lastSavedBite == null) return true;
    if (Bite(stepRegions: regions, title: "").toJson()['regions'].toString() ==
        lastSavedBite!.toJson()['regions'].toString()) {
      return false;
    }

    return true;
  }

  void confirmSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Saved!",
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }

  Future<void> save() async {
    String prevtitle =
        (lastSavedBite ?? Bite(stepRegions: [], title: "")).title;
    if (prevtitle.isEmpty) {
      await saveDialog();
    } else {
      var createdBite = Bite(title: prevtitle, stepRegions: List.from(regions));
      await loader.saveBite(createdBite);
      setState(() {
        lastSavedBite = Bite.fromJson(createdBite.toJson());
      });
      confirmSave();
    }
  }

  Future<void> saveDialog() async {
    String prevtitle =
        (lastSavedBite ?? Bite(stepRegions: [], title: "")).title;

    final controller = TextEditingController(text: prevtitle);
    final title = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Save Bite As")],
            ),
            content: FractionallySizedBox(
              widthFactor: 0.75,
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('Save'),
              ),
            ],
          ),
    );
    if (title != null) {
      var createdBite = Bite(title: title, stepRegions: List.from(regions));
      await loader.saveBite(createdBite);
      if (editing) {
        await loader.deleteBite(lastSavedBite!.title);
      }
      setState(() {
        lastSavedBite = Bite.fromJson(createdBite.toJson());
      });
      confirmSave();
    }
  }

  @override
  void initState() {
    super.initState();
    if (lastSavedBite != null) {
      setState(() {
        regions = Bite.fromJson(lastSavedBite!.toJson()).getRegions();
      });
    }

    _pullModeItems =
        PullMode.values.map((mode) {
          return DropdownMenuItem(value: mode, child: Text(mode.asLabel()));
        }).toList();

    _stopModeItems =
        StopMode.values.map((mode) {
          return DropdownMenuItem(value: mode, child: Text(mode.asLabel()));
        }).toList();
  }

  Widget _buildUnorderedControls(UnorderedStepRegion region, int idx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Use all steps or a limited number?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButton<PullMode>(
          value: region.getPullMode(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                region.setPullMode(val);
              });
            }
          },
          items: _pullModeItems,
        ),
        if (region.getPullMode() == PullMode.pullRandN)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: TextFormField(
                initialValue:
                    (lastSavedBite
                        ?.getRegions()[idx - 1]
                        .upcastUnordered()
                        ?.getPullN()
                        .toString()),
                decoration: const InputDecoration(
                  labelText: "# of steps",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    region.setPullN(int.tryParse(val) ?? 1);
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          "When to stop pulling new steps?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButton<StopMode>(
          value: region.getStopMode(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                region.setStopMode(val);
              });
            }
          },
          items: _stopModeItems,
        ),
        if (region.getStopMode() == StopMode.untilSetSeenNTimes)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: TextFormField(
                initialValue:
                    (lastSavedBite
                        ?.getRegions()[idx - 1]
                        .upcastUnordered()
                        ?.getStopN()
                        .toString()),

                decoration: const InputDecoration(
                  labelText: "# of times to show steps",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    region.setStopN(int.tryParse(val) ?? 1);
                  });
                },
              ),
            ),
          ),
        if (region.getStopMode() == StopMode.untilGoalConf)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: TextFormField(
                initialValue:
                    (lastSavedBite
                            ?.getRegions()[idx - 1]
                            .upcastUnordered()
                            ?.goalText()
                            ?.toString() ??
                        ""),

                decoration: const InputDecoration(
                  labelText: "Goal question (ex: 'Is the sink empty?')",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    region.setGoal(val);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty(), // prevent auto-pop while we handle it manually
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (regions.isEmpty) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Save your Bite?"),
                content: const Text(
                  "You have unsaved changes. Do you want to save this Bite before leaving?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.outline,
                    ),
                    child: Text(
                      "Exit Without Saving",
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await save();
                      if (!mounted) return;
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                    ),
                    child: const Text("Save"),
                  ),
                ],
              ),
        );
        if (shouldLeave ?? false) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Bite Builder"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Save',
                    onPressed: save,
                    icon: const Icon(Icons.save),
                  ),
                  IconButton(
                    tooltip: 'Save As',
                    onPressed: saveDialog,
                    icon: const Icon(Icons.save_as),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: regions.length + 1,
          itemBuilder: (context, index) {
            return (index == 0
                ? Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Center(
                    child: SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () async {
                          final type = await showDialog<StepRegionType>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Choose Step Group Type"),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline),
                                        tooltip: "What’s this?",
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    "Step Group Types",
                                                  ),
                                                  content: const Text(
                                                    "• Fixed: Steps are shown in the exact order you enter them.\n\n"
                                                    "• Unordered: Steps are randomly chosen from the group and then shown either a certain number of times, or until you accomplish a specific goal.",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      child: const Text(
                                                        "Got it",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Which type of step group do you want to add?",
                                  ),
                                  actions: [
                                    SimpleDialogOption(
                                      onPressed:
                                          () => Navigator.pop(
                                            context,
                                            StepRegionType.Fixed,
                                          ),
                                      child: Text(
                                        "Fixed Steps",
                                      ), //PLACEHOLDER NAME
                                    ),
                                    SimpleDialogOption(
                                      onPressed:
                                          () => Navigator.pop(
                                            context,
                                            StepRegionType.Unordered,
                                          ),
                                      child: Text(
                                        "Unordered Steps",
                                      ), //PLACEHOLDER NAME
                                    ),
                                  ],
                                ),
                          );

                          if (type != null) {
                            setState(() {
                              if (type == StepRegionType.Fixed) {
                                regions.add(FixedStepRegion(steps: []));
                              } else {
                                regions.add(
                                  UnorderedStepRegion(
                                    steps: [],
                                    pullMode: PullMode.pullAll,
                                    stopMode: StopMode.untilSetSeen,
                                  ),
                                );
                              }
                            });
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.inversePrimary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          maximumSize: Size(100, 60),
                        ),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ),
                )
                : () {
                  final region = regions[index - 1];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  region.type() == StepRegionType.Fixed
                                      ? "Fixed Steps"
                                      : "Unordered Steps",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Row(
                                  children: [
                                    FloatingActionButton(
                                      mini: true,
                                      onPressed: () {
                                        setState(() {
                                          region.addStep(""); // Add empty step
                                        });
                                      },
                                      child: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (region is UnorderedStepRegion)
                              _buildUnorderedControls(region, index),

                            const SizedBox(height: 40),
                            ...region.getSteps().asMap().entries.map((entry) {
                              final i = entry.key;
                              final text = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: "Step ${i + 1}",
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                        controller: TextEditingController(
                                            text: text,
                                          )
                                          ..selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset: text.length,
                                                ),
                                              ),
                                        onChanged: (val) {
                                          setState(() {
                                            region.setNthStep(i, val);
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          region.removeStep(i);
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }());
          },
        ),
      ),
    );
  }
}
