import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show FloatingActionButton;
import 'package:wisibility/Pages/csvuploder.dart';

class GroupPair {
  List<String?> filters1 = [null];
  List<String?> filters2 = [null];
  List<Map<String, String>> usersInAll = [];
  bool hasFiltered = false;
  String title;
  String sodOwnerSearch = '';
  String? sodOwnerSelected;

  GroupPair({this.title = "SOD Title"});
}

class SodPage extends StatefulWidget {
  final List<List<dynamic>> csvTable;

  const SodPage({super.key, required this.csvTable});

  @override
  State<SodPage> createState() => _SodPageState();
}

class _SodPageState extends State<SodPage> {
  // Dynamic headers + indexes
  List<String> headers = [];
  Map<String, int> fieldIndexes = {};

  // Extracted sets
  List<String> groups = [];
  List<String> displayNames = [];


  List<GroupPair> groupPairs = [GroupPair()];

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  void _extractData() {
    if (widget.csvTable.isEmpty) return;

    headers = widget.csvTable.first.map((e) => e.toString().trim()).toList();

    // Build field index map dynamically
    fieldIndexes = {
      for (var f in mandatoryFields)
        f: headers.indexWhere((h) => h.toLowerCase() == f.toLowerCase())
    };

    // Fallback to detect actual 'Group' and 'DisplayName' fields
    final idxGroup = fieldIndexes['Groups'] ?? -1;
    final idxDisplayName = fieldIndexes['DisplayName'] ?? -1;

    final groupSet = <String>{};
    final displayNameSet = <String>{};

    for (final row in widget.csvTable.skip(1)) {
      if (idxGroup >= 0 && row.length > idxGroup) {
        final val = row[idxGroup]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          final groupNames = val.split(';').map((g) => g.trim()).where((g) => g.isNotEmpty);
          groupSet.addAll(groupNames);
        }
      }

      if (idxDisplayName >= 0 && row.length > idxDisplayName) {
        final dn = row[idxDisplayName]?.toString().trim() ?? '';
        if (dn.isNotEmpty) displayNameSet.add(dn);
      }
    }

    setState(() {
      groups = groupSet.toList()..sort();
      displayNames = displayNameSet.toList()..sort();
    });
  }

  void _findUsersInAll(GroupPair pair) {
    final selected1 = pair.filters1.whereType<String>().toSet();
    final selected2 = pair.filters2.whereType<String>().toSet();

    if (selected1.isEmpty) {
      setState(() => pair.usersInAll = []);
      return;
    }

    final result = <Map<String, String>>[];

    final idxGroup = fieldIndexes['Groups'] ?? -1;

    for (final row in widget.csvTable.skip(1)) {
      if (idxGroup < 0 || row.length <= idxGroup) continue;

      final groupVal = row[idxGroup]?.toString().trim() ?? '';
      if (groupVal.isEmpty) continue;

      final userGroups = groupVal.split(';').map((g) => g.trim()).toSet();

      final inAllFilter1 = selected1.every((g) => userGroups.contains(g));
      final inAnyFilter2 = selected2.isNotEmpty && selected2.any((g) => userGroups.contains(g));

      if (inAllFilter1 && !inAnyFilter2) {
        final userMap = <String, String>{};
        for (final field in mandatoryFields) {
          final idx = fieldIndexes[field] ?? -1;
          userMap[field] = (idx >= 0 && idx < row.length && row[idx] != null)
              ? row[idx].toString()
              : '';
        }
        result.add(userMap);
      }
    }

    setState(() => pair.usersInAll = result);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('SOD: Segregation of Duties')),
      content: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...groupPairs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pair = entry.value;

                    final titleController = TextEditingController(text: pair.title);
                    final focusNode = FocusNode();

                    focusNode.addListener(() {
                      if (!focusNode.hasFocus) {
                        setState(() {
                          pair.title = titleController.text.isEmpty ? "SOD Title" : titleController.text;
                        });
                      }
                    });

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Focus(
                                      focusNode: focusNode,
                                      child: Builder(
                                        builder: (context) {
                                          bool isEditing = focusNode.hasFocus;
                                          return GestureDetector(
                                            onTap: () {
                                              FocusScope.of(context).requestFocus(focusNode);
                                            },
                                            child: isEditing
                                                ? TextBox(
                                              controller: titleController,
                                              autofocus: true,
                                              onSubmitted: (value) {
                                                setState(() {
                                                  pair.title = value.isEmpty ? "SOD Title" : value;
                                                });
                                                focusNode.unfocus();
                                              },
                                            )
                                                : Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              child: Text(
                                                pair.title,
                                                style: const TextStyle(
                                                  color: Color(0xFF888888),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: AutoSuggestBox(
                                        placeholder: 'Search SOD Owner',
                                        items: displayNames
                                            .map((name) => AutoSuggestBoxItem(
                                          value: name,
                                          label: name,
                                        ))
                                            .toList(),
                                        onSelected: (item) {
                                          setState(() {
                                            pair.sodOwnerSearch = item.value!;
                                            pair.sodOwnerSelected = item.value;
                                          });
                                        },
                                        onChanged: (text, reason) {
                                          setState(() {
                                            pair.sodOwnerSearch = text;
                                            pair.sodOwnerSelected = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Button(
                                    child: const Text('Clear All'),
                                    onPressed: () {
                                      setState(() {
                                        pair.filters1 = [null];
                                        pair.filters2 = [null];
                                        pair.usersInAll = [];
                                        pair.hasFiltered = false;
                                        pair.sodOwnerSearch = '';
                                        pair.sodOwnerSelected = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Group Filter 1', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ...pair.filters1.asMap().entries.map((filterEntry) {
                                          final filterIdx = filterEntry.key;
                                          final filterValue = filterEntry.value;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(0, 18, 8, 8),
                                                  child: ComboBox<String>(
                                                    placeholder: Text('Select Group ${filterIdx + 1}'),
                                                    items: groups
                                                        .map((g) => ComboBoxItem<String>(
                                                      value: g,
                                                      child: Text(g),
                                                    ))
                                                        .toList(),
                                                    value: filterValue,
                                                    onChanged: (v) => setState(() => pair.filters1[filterIdx] = v),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(FluentIcons.add),
                                                onPressed: () {
                                                  setState(() => pair.filters1.insert(filterIdx + 1, null));
                                                },
                                              ),
                                              if (pair.filters1.length > 1)
                                                IconButton(
                                                  icon: const Icon(FluentIcons.delete),
                                                  onPressed: () {
                                                    setState(() => pair.filters1.removeAt(filterIdx));
                                                  },
                                                ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Group Filter 2', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ...pair.filters2.asMap().entries.map((filterEntry) {
                                          final filterIdx = filterEntry.key;
                                          final filterValue = filterEntry.value;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(0, 18, 8, 8),
                                                  child: ComboBox<String>(
                                                    placeholder: Text('Select Group ${filterIdx + 1}'),
                                                    items: groups
                                                        .map((g) => ComboBoxItem<String>(
                                                      value: g,
                                                      child: Text(g),
                                                    ))
                                                        .toList(),
                                                    value: filterValue,
                                                    onChanged: (v) => setState(() => pair.filters2[filterIdx] = v),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(FluentIcons.add),
                                                onPressed: () {
                                                  setState(() => pair.filters2.insert(filterIdx + 1, null));
                                                },
                                              ),
                                              if (pair.filters2.length > 1)
                                                IconButton(
                                                  icon: const Icon(FluentIcons.delete),
                                                  onPressed: () {
                                                    setState(() => pair.filters2.removeAt(filterIdx));
                                                  },
                                                ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  child: const Text('Begin'),
                                  onPressed: () {
                                    setState(() => pair.hasFiltered = true);
                                    _findUsersInAll(pair);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (pair.hasFiltered)
                                (pair.usersInAll.isNotEmpty)
                                    ? SizedBox(
                                  height: 300,
                                  child: _buildUserTable(pair.usersInAll),
                                )
                                    : const Text('No users found in all selected groups.'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                child: const Icon(FluentIcons.add),
                onPressed: () => setState(() => groupPairs.add(GroupPair())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable(List<Map<String, String>> users) {
    return Column(
      children: [
        Container(
          color: FluentTheme.of(context).accentColor.withOpacity(0.1),
          child: Row(
            children: mandatoryFields
                .map(
                  (field) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text(
                    field,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18.0),
                  bottomRight: Radius.circular(18.0),
                ),
              ),
              color: Colors.white,
            ),
            child: Scrollbar(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                      ),
                    ),
                    child: Row(
                      children: mandatoryFields
                          .map(
                            (field) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            child: Text(user[field] ?? ''),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
