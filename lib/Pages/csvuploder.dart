import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';

List<List<dynamic>> csvTable = [];

const List<String> mandatoryFields = [
  'EmployeeID',
  'DisplayName',
  'Title',
  'Department',
  'EndDate',
  'Status',
  'Email',
  'PhoneNumber',
  'Location',
  'Groups',
  'ManagerID',
];

class CsvUploader extends StatefulWidget {
  final void Function(
      Map<String, dynamic> stats,
      Map<String, List<String>> details,
      ) onResultGenerated;

  const CsvUploader({
    super.key,
    required this.onResultGenerated,
  });

  @override
  State<CsvUploader> createState() => _CsvUploaderState();
}

class _CsvUploaderState extends State<CsvUploader> {
  List<String> headers = [];
  Map<String, String?> mappedFields = {};
  late final ScrollController _horizontalController;

  String? errorMessage;

  final TextEditingController appNameController = TextEditingController(text:  "App Name");
  final TextEditingController ownerNameController = TextEditingController(text: "Owner Name");

  bool isValidating = false;
  bool validationPassed = false;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    appNameController.dispose();
    ownerNameController.dispose();
    super.dispose();
  }

  Future<void> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path != null) {
      final content = await File(path).readAsString();
      final table = CsvToListConverter().convert(content);
      if (table.isNotEmpty) {
        setState(() {
          headers = table.first.map((e) => e.toString().trim()).toList();
          csvTable = table;
          mappedFields = {
            for (final field in mandatoryFields)
              field: headers.firstWhere(
                    (h) => h.toLowerCase() == field.toLowerCase(),
                orElse: () => "null",
              )
          };
          final unmapped = mappedFields.entries
              .where((e) => e.value == null)
              .map((e) => e.key)
              .toList();
          if (unmapped.isNotEmpty) {
            errorMessage =
            '⚠️ Missing mappings for: ${unmapped.join(', ')}. Please fix below.';
          } else {
            errorMessage = null;
          }
        });
      }
    }
  }

  Future<void> validateCsvData() async {
    setState(() {
      isValidating = true;
      validationPassed = false;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate loading

    bool validDates = true;
    bool hasNulls = false;
    bool validTypes = true;
    bool hasGroups = false;

    int dateColumnIndex = mappedFields.entries.firstWhere(
          (e) => e.key.toLowerCase().contains("date"),
      orElse: () => const MapEntry("", null),
    ).value != null
        ? headers.indexOf(mappedFields.entries
        .firstWhere((e) => e.key.toLowerCase().contains("date"))
        .value!)
        : -1;

    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];

      if (row.contains(null) || row.contains("")) {
        hasNulls = true;
      }

      if (dateColumnIndex >= 0 && dateColumnIndex < row.length) {
        final dateVal = row[dateColumnIndex].toString();
        if (!RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(dateVal)) {
          validDates = false;
        }
      }

      final idIndex = mappedFields["EmployeeID"] != null
          ? headers.indexOf(mappedFields["EmployeeID"]!)
          : -1;
      if (idIndex >= 0 && idIndex < row.length) {
        if (int.tryParse(row[idIndex].toString()) == null) {
          validTypes = false;
        }
      }

      final groupIndex = mappedFields["Groups"] != null
          ? headers.indexOf(mappedFields["Groups"]!)
          : -1;
      if (groupIndex >= 0 && groupIndex < row.length) {
        if (row[groupIndex].toString().isNotEmpty) {
          hasGroups = true;
        }
      }
    }

    if (!validDates) {
      errorMessage = "❌ Invalid date format detected.";
    } else if (hasNulls) {
      errorMessage = "❌ Null values found.";
    } else if (!validTypes) {
      errorMessage = "❌ EmployeeID must be an integer.";
    } else if (!hasGroups) {
      errorMessage = "❌ Group information missing.";
    } else {
      errorMessage = null;
      validationPassed = true;
    }

    setState(() {
      isValidating = false;
    });
  }

  void onBeginPressed() {
    // Do your final processing here
    widget.onResultGenerated(
      {'appName': appNameController.text, 'ownerName': ownerNameController.text},
      mappedFields.map((k, v) => MapEntry(k, [v ?? ''])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('CSV Uploader')),
      content: Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextBox(

              controller: appNameController,
            ),
            const SizedBox(height: 10),
            TextBox(

              controller: ownerNameController,
            ),
            const SizedBox(height: 10),
            Button(
              child: const Text('Upload CSV'),
              onPressed: pickCsvFile,
            ),
            const SizedBox(height: 20),
            if (headers.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.green,
                      ),
                      padding: const EdgeInsets.all(18),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _horizontalController,
                        child: Row(
                          children: [
                            ...mandatoryFields.map((field) {
                              final missing = mappedFields[field] == null;
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DropdownColumn(
                                      label: field,
                                      placeholder: field,
                                      headers: headers,
                                      value: mappedFields[field],
                                      onChanged: (v) {
                                        setState(() {
                                          mappedFields[field] = v;
                                          final unmapped = mappedFields.entries
                                              .where((e) => e.value == null)
                                              .map((e) => e.key)
                                              .toList();
                                          if (unmapped.isNotEmpty) {
                                            errorMessage =
                                            '⚠️ Missing mappings for: ${unmapped.join(', ')}.';
                                          } else {
                                            errorMessage = null;
                                          }
                                        });
                                      },
                                    ),
                                    if (missing)
                                       Text(
                                        '❌ Missing header',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style:  TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 20),
                    Button(
                      child: isValidating
                          ? const ProgressRing()
                          : validationPassed
                          ? const Icon(FluentIcons.check_mark)
                          : const Text('Next'),
                      onPressed: isValidating || validationPassed
                          ? null
                          : validateCsvData,
                    ),
                    const SizedBox(height: 10),
                    if (validationPassed)
                      Button(
                        child: const Text('Proceed to Next'),
                        onPressed: onBeginPressed,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownColumn extends StatelessWidget {
  final String label;
  final String placeholder;
  final List<String> headers;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DropdownColumn({
    super.key,
    required this.label,
    required this.placeholder,
    required this.headers,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select $label:"),
        const SizedBox(height: 4),
        ComboBox<String>(
          placeholder: Text(placeholder),
          isExpanded: true,
          items: headers
              .map((header) => ComboBoxItem<String>(
            value: header,
            child: Text(header),
          ),)
              .toList(),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
