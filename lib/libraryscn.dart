import 'package:flutter/material.dart';
import 'package:onebite/bitebuilderscn.dart';
import 'loader.dart';
import 'bite.dart';
import 'biteplayerscn.dart';

class BiteLibrary extends StatefulWidget {
  const BiteLibrary({super.key});

  @override
  State<BiteLibrary> createState() => _BiteLibraryState();
}

class _BiteLibraryState extends State<BiteLibrary> {
  List<String> _BiteTitles = [];
  BiteLoader _loader = BiteLoader();

  @override
  void initState() {
    super.initState();
    () async {
      await _loader.loadBiteTitles();

      if (!mounted) return;
      setState(() {
        _BiteTitles = _loader.getBiteTitles();
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Bites"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(
              tooltip: 'New Bite',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BiteBuilder(key: UniqueKey(), editing: false),
                  ),
                );
                await _loader.loadBiteTitles();
                setState(() {
                  _BiteTitles = _loader.getBiteTitles();
                });
              },
              icon: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
      body:
          _BiteTitles.isNotEmpty
              ? Padding(
                padding: EdgeInsets.only(top: 40),
                child: ListView.builder(
                  itemCount: _BiteTitles.length,
                  itemBuilder: (context, index) {
                    final title = _BiteTitles[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 40,
                        right: 40,
                        bottom: 7,
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Theme.of(context).colorScheme.onPrimary,
                        child: ListTile(
                          title: Text(title),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final bite = await _loader.loadBite(title);
                                if (!mounted || bite == null) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => BiteBuilder(
                                          key: UniqueKey(),
                                          lastSavedBite: bite,
                                          editing: true,
                                        ),
                                  ),
                                );
                                await _loader.loadBiteTitles();
                                setState(() {
                                  _BiteTitles = _loader.getBiteTitles();
                                }); // Refresh list
                              } else if (value == 'delete') {
                                // Optional: Confirm deletion with user
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: Text("Delete Bite"),
                                        content: Text(
                                          "Are you sure you want to delete '$title'?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  await _loader.deleteBite(title);
                                  await _loader.loadBiteTitles();
                                  setState(() {
                                    _BiteTitles = _loader.getBiteTitles();
                                  }); // Refresh list
                                }
                              } else if (value == 'rename') {
                                final controller = TextEditingController(
                                  text: title,
                                );
                                final newTitle = await showDialog<String>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Rename Bite"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            labelText: "New title",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  null,
                                                ),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  controller.text.trim(),
                                                ),
                                            child: const Text("Rename"),
                                          ),
                                        ],
                                      ),
                                );

                                if (newTitle != null &&
                                    newTitle.isNotEmpty &&
                                    newTitle != title) {
                                  final bite = await _loader.loadBite(title);
                                  if (bite != null) {
                                    bite.title = newTitle;
                                    await _loader.deleteBite(title);
                                    await _loader.saveBite(bite);
                                    await _loader.loadBiteTitles();
                                    setState(() {
                                      _BiteTitles = _loader.getBiteTitles();
                                    }); // Refresh list
                                  }
                                }
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(color: Colors.red),
                                    ),
                                  ),
                                ],
                          ),
                          onTap: () async {
                            // Navigate to Bite view
                            await _loader.loadBiteTitles();
                            setState(() {
                              _BiteTitles = _loader.getBiteTitles();
                            }); // Refresh list
                            Bite bite = (await _loader.loadBite(title))!;
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => BitePlayer(
                                      key: UniqueKey(),
                                      bite: bite,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "You don't have any Bites yet.",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 25.0),

                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BiteBuilder(
                                  key: UniqueKey(),
                                  editing: false,
                                ),
                          ),
                        );
                        await _loader.loadBiteTitles();
                        setState(() {
                          _BiteTitles = _loader.getBiteTitles();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        minimumSize: Size(125, 55),
                      ),
                      child: Text(
                        "Let's make one",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
