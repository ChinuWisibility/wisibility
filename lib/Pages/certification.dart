import 'package:fluent_ui/fluent_ui.dart';
import 'package:wisibility/Pages/csv/csvAnalysis.dart';
import 'package:wisibility/Pages/csvuploder.dart'; // your csvTable lives here
 // wherever your analyzeCsv is

class CertificationPage extends StatefulWidget {
  const CertificationPage({super.key});

  @override
  State<CertificationPage> createState() => _CertificationPageState();
}

class _CertificationPageState extends State<CertificationPage> {
  String? selectedTitleValue;
  String? selectedGroupValue;

  String? selectedTitleHeader = 'Title';
  String? selectedGroupHeader = 'Groups';

  final TextEditingController nameController = TextEditingController();

  late final Map<String, dynamic> analyzed;
  late final List<String> uniqueGroups;

  @override
  void initState() {
    super.initState();

    analyzed = analyzeCsv(csvTable, {
      'EmployeeID': 'EmployeeID',
      'DisplayName': 'DisplayName',
      'Title': 'Title',
      'Department': 'Department',
      'EndDate': 'EndDate',
      'Status': 'Status',
      'Email': 'Email',
      'PhoneNumber': 'PhoneNumber',
      'Location': 'Location',
      'Groups': 'Groups',
      'ManagerID': 'ManagerID',
    });

    uniqueGroups = List<String>.from(analyzed['details']['UniqueGroups'] ?? []);
  }

  List<String> get csvHeaders =>
      csvTable.isNotEmpty ? csvTable.first.map((e) => e.toString()).toList() : [];

  List<String> get matchingDisplayNames {
    if (selectedTitleHeader == null ||
        selectedGroupHeader == null ||
        selectedTitleValue == null ||
        selectedGroupValue == null) {
      return [];
    }

    final titleIndex = csvHeaders.indexOf(selectedTitleHeader!);
    final groupIndex = csvHeaders.indexOf(selectedGroupHeader!);
    final displayNameIndex = csvHeaders.indexOf('DisplayName');

    if (titleIndex == -1 || groupIndex == -1 || displayNameIndex == -1) {
      return [];
    }

    return csvTable.skip(1).where((row) {
      final groups = row[groupIndex].toString().split(';').map((e) => e.trim());
      return row[titleIndex].toString() == selectedTitleValue &&
          groups.contains(selectedGroupValue);
    }).map((row) => row[displayNameIndex].toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Create Certification')),
      content: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Title'),
                        ComboBox<String>(
                          isExpanded: true,
                          placeholder: const Text('Pick Title'),
                          value: selectedTitleValue,
                          items: csvTable
                              .skip(1)
                              .map((row) => row[csvHeaders.indexOf('Title')].toString())
                              .toSet()
                              .map((val) => ComboBoxItem<String>(
                            value: val,
                            child: Text(val),
                          ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedTitleValue = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Group'),
                        ComboBox<String>(
                          isExpanded: true,
                          placeholder: const Text('Pick Group'),
                          value: selectedGroupValue,
                          items: uniqueGroups
                              .map((val) => ComboBoxItem<String>(
                            value: val,
                            child: Text(val),
                          ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedGroupValue = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
          
              const Text('Enter Certificate Name'),
              TextBox(
                controller: nameController,
                placeholder: 'Certificate name',
              ),
          
              const SizedBox(height: 20),
          
              FilledButton(
                child: const Text('Create Certificate'),
                onPressed: () {
                  debugPrint(
                      'Creating certificate: ${nameController.text} for ${matchingDisplayNames.length} users');
                },
              ),
          
              const SizedBox(height: 30),
          
              if (matchingDisplayNames.isNotEmpty) ...[
                const Text(
                  'These people will receive the certificate:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...matchingDisplayNames.map((name) => Text('- $name')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
