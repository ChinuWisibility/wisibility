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

  const CsvUploader({super.key, required this.onResultGenerated});

  @override
  State<CsvUploader> createState() => _CsvUploaderState();
}

class _CsvUploaderState extends State<CsvUploader> {
  List<String> headers = [];
  Map<String, String?> mappedFields = {};
  late final ScrollController _horizontalController;

  String? errorMessage;

  final TextEditingController appNameController = TextEditingController(text: "App Name");
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
        final parsedHeaders = table.first.map((e) => e.toString().trim()).toList();
        setState(() {
          headers = parsedHeaders;
          csvTable = table;

          mappedFields = {
            for (final field in mandatoryFields)
              field: parsedHeaders.contains(field) ? field : null,
          };

          final missingFields = mappedFields.entries.where((e) => e.value == null).map((e) => e.key).toList();

          errorMessage = missingFields.isNotEmpty
              ? '❌ Missing mandatory fields: ${missingFields.join(", ")}'
              : null;
        });
      }
    }
  }

  Future<void> validateCsvData() async {
    int activeCount = 0;
    int inactiveCount = 0;
    Set<String> uniqueGroups = {};
    Set<String> uniqueManagers = {};
    Set<String> uniqueDepartments = {};
    List<String> allUsers = [];
    List<String> activeUsers = [];
    List<String> inactiveUsers = [];
    List<String> expiringUsers = [];
    List<String> activeWithPastEndDate = [];
    List<String> inactiveWithFutureEndDate = [];
    List<String> noManager = [];
    List<String> missingDisplayName = [];
    List<String> missingTitle = [];
    List<String> missingDepartment = [];
    List<String> noStatus = [];
    List<String> noGroups = [];
    List<String> specialCharDisplayName = [];

    final statusIndex = mappedFields['Status'] != null ? headers.indexOf(mappedFields['Status']!) : -1;
    final displayNameIndex = mappedFields['DisplayName'] != null ? headers.indexOf(mappedFields['DisplayName']!) : -1;
    final groupsIndex = mappedFields['Groups'] != null ? headers.indexOf(mappedFields['Groups']!) : -1;
    final managerIndex = mappedFields['ManagerID'] != null ? headers.indexOf(mappedFields['ManagerID']!) : -1;
    final departmentIndex = mappedFields['Department'] != null ? headers.indexOf(mappedFields['Department']!) : -1;
    final titleIndex = mappedFields['Title'] != null ? headers.indexOf(mappedFields['Title']!) : -1;
    final endDateIndex = mappedFields['EndDate'] != null ? headers.indexOf(mappedFields['EndDate']!) : -1;

    final today = DateTime.now();

    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      final name = displayNameIndex >= 0 && displayNameIndex < row.length ? row[displayNameIndex].toString().trim() : '';
      final status = statusIndex >= 0 && statusIndex < row.length ? row[statusIndex].toString().toLowerCase().trim() : '';
      final manager = managerIndex >= 0 && managerIndex < row.length ? row[managerIndex].toString().trim() : '';
      final department = departmentIndex >= 0 && departmentIndex < row.length ? row[departmentIndex].toString().trim() : '';
      final title = titleIndex >= 0 && titleIndex < row.length ? row[titleIndex].toString().trim() : '';
      final groups = groupsIndex >= 0 && groupsIndex < row.length ? row[groupsIndex].toString().trim() : '';

      if (name.isNotEmpty) allUsers.add(name);
      if (status == 'active') {
        activeCount++;
        activeUsers.add(name);
      }
      if (status == 'inactive') {
        inactiveCount++;
        inactiveUsers.add(name);
      }
      if (groups.isEmpty) noGroups.add(name);

      if (groups.isNotEmpty) {
        for (var g in groups.split(';')) {
          final clean = g.trim();
          if (clean.isNotEmpty) uniqueGroups.add(clean);
        }
      }

      if (manager.isEmpty) noManager.add(name);
      if (name.isEmpty) missingDisplayName.add(name);
      if (title.isEmpty) missingTitle.add(name);
      if (department.isEmpty) missingDepartment.add(name);
      if (status.isEmpty) noStatus.add(name);

      final specialCharPattern = RegExp(r'[^\w\s]');
      if (specialCharPattern.hasMatch(name)) specialCharDisplayName.add(name);

      if (endDateIndex >= 0 && endDateIndex < row.length) {
        final rawDate = row[endDateIndex].toString().trim();
        final dateParts = rawDate.split('-');
        if (dateParts.length == 3) {
          final day = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final year = int.tryParse(dateParts[2]);
          if (day != null && month != null && year != null) {
            final endDate = DateTime(year, month, day);
            final diff = endDate.difference(today).inDays;

            if (diff >= 0 && diff <= 7) expiringUsers.add(name);
            if (status == 'active' && diff < 0) activeWithPastEndDate.add(name);
            if (status == 'inactive' && diff >= 0) inactiveWithFutureEndDate.add(name);
          }
        }
      }

      if (department.isNotEmpty) uniqueDepartments.add(department);
      if (manager.isNotEmpty) uniqueManagers.add(manager);
    }

    Map<String, dynamic> stats = {
      'Display Name': allUsers.length,
      'Status': {'Active': activeCount, 'Inactive': inactiveCount},
      'Group': uniqueGroups.length,
      'Manager': uniqueManagers.length,
      'Department': uniqueDepartments.length,
      'End Date': expiringUsers.length,
    };

    Map<String, List<String>> details = {
      'AllUsers': allUsers,
      'ActiveUsers': activeUsers,
      'InactiveUsers': inactiveUsers,
      'UniqueGroups': uniqueGroups.toList(),
      'UniqueManagers': uniqueManagers.toList(),
      'UniqueDepartments': uniqueDepartments.toList(),
      'ExpiringUsers': expiringUsers,
      'ActiveWithPastEndDate': activeWithPastEndDate,
      'InactiveWithFutureEndDate': inactiveWithFutureEndDate,
      'NoManager': noManager,
      'MissingDisplayName': missingDisplayName,
      'MissingTitle': missingTitle,
      'MissingDepartment': missingDepartment,
      'NoStatus': noStatus,
      'NoGroups': noGroups,
      'SpecialCharDisplayName': specialCharDisplayName,
    };

    setState(() {
      validationPassed = true;
    });

    widget.onResultGenerated(stats, details);
  }

  void onBeginPressed() {
    widget.onResultGenerated({
      'appName': appNameController.text,
      'ownerName': ownerNameController.text,
    }, mappedFields.map((k, v) => MapEntry(k, [v ?? ''])));
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
            TextBox(controller: appNameController),
            const SizedBox(height: 10),
            TextBox(controller: ownerNameController),
            const SizedBox(height: 10),
            Button(child: const Text('Upload CSV'), onPressed: pickCsvFile),
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
                                          final stillMissing = mappedFields.entries
                                              .where((e) => e.value == null)
                                              .map((e) => e.key)
                                              .toList();
                                          errorMessage = stillMissing.isNotEmpty
                                              ? '❌ Missing mandatory fields: ${stillMissing.join(", ")}'
                                              : null;
                                        });
                                      },
                                    ),
                                    if (missing)
                                       Text('❌ Missing header', style: TextStyle(color: Colors.red)),
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
                      Text(errorMessage!, style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 20),
                    Button(
                      child: validationPassed
                          ? const Icon(FluentIcons.check_mark)
                          : const Text('Validate'),
                      onPressed: validationPassed ? null : validateCsvData,
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
          items: headers.map((header) => ComboBoxItem<String>(value: header, child: Text(header))).toList(),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
