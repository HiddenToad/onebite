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
    print("MEOW");
    print(_BiteTitles);
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
                    builder: (context) => BiteBuilder(key: UniqueKey()),
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
          _BiteTitles.length > 0
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
                          onTap: () async {
                            // Navigate to Bite view
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
                            builder: (context) => BiteBuilder(key: UniqueKey()),
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
