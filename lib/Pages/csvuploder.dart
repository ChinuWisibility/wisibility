import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:wisibility/Pages/result.dart';

import 'db/csv_db.dart';

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

  const CsvUploader({super.key, required this.onResultGenerated});

  @override
  State<CsvUploader> createState() => _CsvUploaderState();
}

class _CsvUploaderState extends State<CsvUploader> {
  List<String> headers = [];
  Map<String, String?> mappedFields = {};
  Map<String, dynamic> stats = {};
  Map<String, List<String>> validatedDetails = {};
  late final ScrollController _horizontalController;

  String? errorMessage;

  final TextEditingController appNameController =
  TextEditingController(text: "App Name");
  final TextEditingController ownerNameController =
  TextEditingController(text: "Owner Name");

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
      print('📂 Picked CSV rows: ${table.length}');

      if (table.isNotEmpty) {
        final parsedHeaders =
        table.first.map((e) => e.toString().trim()).toList();
        print('📌 Parsed headers: $parsedHeaders');

        setState(() {
          headers = parsedHeaders;
          csvTable = table;

          mappedFields = {
            for (final field in mandatoryFields)
              field: parsedHeaders.contains(field) ? field : null,
          };

          final missingFields = mappedFields.entries
              .where((e) => e.value == null)
              .map((e) => e.key)
              .toList();

          errorMessage = missingFields.isNotEmpty
              ? '❌ Missing mandatory fields: ${missingFields.join(", ")}'
              : null;
        });
      }
    } else {
      print('❌ No file picked.');
    }
  }

  void onBeginPressed() async {
    stats = {
      'RowCount': csvTable.length,
    };
    validatedDetails = {
      'RawRows': csvTable.skip(1).map((r) => r.join(', ')).toList(),
    };

    final id = await CsvDB.saveCsvUpload(
      appName: appNameController.text,
      ownerName: ownerNameController.text,
      csvTable: csvTable,
    );

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (_) => CsvResultsPage(
          stats: stats,
          details: validatedDetails,
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('CSV Uploader')),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextBox(controller: appNameController)),
                const SizedBox(width: 20),
                Expanded(child: TextBox(controller: ownerNameController)),
                const SizedBox(width: 20),
                Button(
                  child: const Text('Upload CSV'),
                  onPressed: pickCsvFile,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (headers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.yellow.light,
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
                                        final stillMissing = mappedFields.entries
                                            .where((e) => e.value == null)
                                            .map((e) => e.key)
                                            .toList();
                                        errorMessage =
                                        stillMissing.isNotEmpty
                                            ? '❌ Missing mandatory fields: ${stillMissing.join(", ")}'
                                            : null;
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
                    Text(errorMessage!,
                        style:  TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  Button(
                    child: const Text('Proceed to Save'),
                    onPressed: onBeginPressed,
                  ),
                ],
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
              .map((header) =>
              ComboBoxItem<String>(value: header, child: Text(header)))
              .toList(),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
