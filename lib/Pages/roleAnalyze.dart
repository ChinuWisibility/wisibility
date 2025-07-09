import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wisibility/Pages/csvuploder.dart';

class RoleAnalyze extends StatefulWidget {
  const RoleAnalyze({super.key});

  @override
  State<RoleAnalyze> createState() => _RoleAnalyzeState();
}

class _RoleAnalyzeState extends State<RoleAnalyze> {
  int currentIndex = 0;

  late List<String> titles;
  late List<String> departments;
  late List<String> groups;

  int idxTitle = -1;
  int idxDepartment = -1;
  int idxGroup = -1;

  String? selectedTitle;
  String? selectedTitleGroup;

  String? selectedDepartment;
  String? selectedDepartmentGroup;

  bool showTitleResult = false;
  bool showDepartmentResult = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  void _prepareData() {
    if (csvTable.isEmpty) return;

    final headers = csvTable.first.map((e) => e.toString().trim()).toList();
    final rows = csvTable.skip(1);

    idxTitle = headers.indexWhere((h) => h.toLowerCase() == 'title');
    idxDepartment = headers.indexWhere((h) => h.toLowerCase() == 'department');
    idxGroup = headers.indexWhere((h) => h.toLowerCase().contains('group'));

    final titleSet = <String>{};
    final departmentSet = <String>{};
    final groupSet = <String>{};

    for (final row in rows) {
      if (idxTitle >= 0 && idxTitle < row.length) {
        final val = row[idxTitle]?.toString().trim() ?? '';
        if (val.isNotEmpty) titleSet.add(val);
      }
      if (idxDepartment >= 0 && idxDepartment < row.length) {
        final val = row[idxDepartment]?.toString().trim() ?? '';
        if (val.isNotEmpty) departmentSet.add(val);
      }
      if (idxGroup >= 0 && idxGroup < row.length) {
        final val = row[idxGroup]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          final splitGroups = val.split(';').map((g) => g.trim()).where((g) => g.isNotEmpty);
          groupSet.addAll(splitGroups);
        }
      }
    }

    titles = titleSet.toList()..sort();
    departments = departmentSet.toList()..sort();
    groups = groupSet.toList()..sort();
  }

  List<List<dynamic>> get _filteredTitleRows {
    if (selectedTitle == null) return [];
    return csvTable.skip(1).where((row) {
      final hasTitle = idxTitle >= 0 &&
          idxTitle < row.length &&
          row[idxTitle]?.toString().trim() == selectedTitle;
      if (!hasTitle) return false;
      if (selectedTitleGroup == null) return true;

      final groupVal =
      idxGroup >= 0 && idxGroup < row.length ? row[idxGroup]?.toString().trim() ?? '' : '';
      final groupsInRow = groupVal.split(';').map((g) => g.trim());
      return groupsInRow.contains(selectedTitleGroup);
    }).toList();
  }

  List<List<dynamic>> get _filteredDepartmentRows {
    if (selectedDepartment == null) return [];
    return csvTable.skip(1).where((row) {
      final hasDepartment = idxDepartment >= 0 &&
          idxDepartment < row.length &&
          row[idxDepartment]?.toString().trim() == selectedDepartment;
      if (!hasDepartment) return false;
      if (selectedDepartmentGroup == null) return true;

      final groupVal =
      idxGroup >= 0 && idxGroup < row.length ? row[idxGroup]?.toString().trim() ?? '' : '';
      final groupsInRow = groupVal.split(';').map((g) => g.trim());
      return groupsInRow.contains(selectedDepartmentGroup);
    }).toList();
  }

  int _countForTitle() => _filteredTitleRows.length;

  int _totalForTitle() {
    if (selectedTitle == null) return 0;
    final rows = csvTable.skip(1);
    return rows.where((row) {
      return idxTitle >= 0 &&
          idxTitle < row.length &&
          row[idxTitle]?.toString().trim() == selectedTitle;
    }).length;
  }

  int _countForDepartment() => _filteredDepartmentRows.length;

  int _totalForDepartment() {
    if (selectedDepartment == null) return 0;
    final rows = csvTable.skip(1);
    return rows.where((row) {
      return idxDepartment >= 0 &&
          idxDepartment < row.length &&
          row[idxDepartment]?.toString().trim() == selectedDepartment;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Tab(
        text: const Text('Title'),
        body: _buildTitleTab(),
      ),
      Tab(
        text: const Text('Department'),
        body: _buildDepartmentTab(),
      ),
    ];

    return ScaffoldPage(
      header: const PageHeader(title: Text('Role Analyze')),
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
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: TabView(
            tabs: tabs,
            currentIndex: currentIndex,
            onChanged: (index) => setState(() => currentIndex = index),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Title:'),
                    ComboBox<String>(
                      placeholder: const Text('Title'),
                      items: titles
                          .map((t) => ComboBoxItem<String>(
                        value: t,
                        child: Text(t),
                      ))
                          .toList(),
                      value: selectedTitle,
                      onChanged: (v) => setState(() => selectedTitle = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Group:'),
                    ComboBox<String>(
                      placeholder: const Text('Group'),
                      items: groups
                          .map((g) => ComboBoxItem<String>(
                        value: g,
                        child: Text(g),
                      ))
                          .toList(),
                      value: selectedTitleGroup,
                      onChanged: (v) => setState(() => selectedTitleGroup = v),
                    ),
                    const SizedBox(height: 16),
                    Button(
                      child: const Text('Show'),
                      onPressed: () {
                        setState(() {
                          showTitleResult = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Count: ${_countForTitle()} / ${_totalForTitle()}',
                      style: FluentTheme.of(context).typography.title,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildPieChart(_countForTitle(), _totalForTitle()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (showTitleResult)
            Expanded(
              child: _buildScrollableTable(_filteredTitleRows),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Department:'),
                    ComboBox<String>(
                      placeholder: const Text('Department'),
                      items: departments
                          .map((d) => ComboBoxItem<String>(
                        value: d,
                        child: Text(d),
                      ))
                          .toList(),
                      value: selectedDepartment,
                      onChanged: (v) => setState(() => selectedDepartment = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Group:'),
                    ComboBox<String>(
                      placeholder: const Text('Group'),
                      items: groups
                          .map((g) => ComboBoxItem<String>(
                        value: g,
                        child: Text(g),
                      ))
                          .toList(),
                      value: selectedDepartmentGroup,
                      onChanged: (v) => setState(() => selectedDepartmentGroup = v),
                    ),
                    const SizedBox(height: 16),
                    Button(
                      child: const Text('Show'),
                      onPressed: () {
                        setState(() {
                          showDepartmentResult = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Count: ${_countForDepartment()} / ${_totalForDepartment()}',
                      style: FluentTheme.of(context).typography.title,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildPieChart(_countForDepartment(), _totalForDepartment()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (showDepartmentResult)
            Expanded(
              child: _buildScrollableTable(_filteredDepartmentRows),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollableTable(List<List<dynamic>> rows, {String? selectedGroup}) {
    final allHeaders = csvTable.first.map((h) => h.toString()).toList();

    const selectedColumns = [
      'EmployeeID',
      'DisplayName',
      'Title',
      'Department',
      'Status',
      'Groups',
      'ManagerID',
    ];

    final selectedIndexes = selectedColumns.map((col) {
      final idx = allHeaders.indexWhere((h) => h.toLowerCase() == col.toLowerCase());
      return idx >= 0 ? idx : null;
    }).whereType<int>().toList();

    final idxGroups = allHeaders.indexWhere((h) => h.toLowerCase().contains('group'));

    if (selectedIndexes.isEmpty || rows.isEmpty) {
      return const Text('No matching rows.');
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: Colors.grey.withOpacity(0.4)),
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withOpacity(0.1),
                ),
                children: selectedColumns
                    .map(
                      (h) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      h,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                    .toList(),
              ),
              // Data rows
              ...rows.map(
                    (row) => TableRow(
                  children: selectedIndexes.map((idx) {
                    dynamic val;
                    if (idx == idxGroups && selectedGroup != null && selectedGroup.isNotEmpty) {
                      // Show only the matching group
                      final groupVal = row[idx]?.toString() ?? '';
                      final matched = groupVal.split(';').map((g) => g.trim()).where((g) => g == selectedGroup);
                      val = matched.join('; ');
                    } else {
                      val = idx < row.length ? row[idx] : '';
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(val?.toString() ?? ''),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(int count, int total) {
    if (total == 0) {
      return const Text('No data to show.');
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: count.toDouble(),
              color: Colors.green.light,
              title: '$count',
            ),
            PieChartSectionData(
              value: (total - count).toDouble(),
              color: Colors.yellow,
              title: '${total - count}',
            ),
          ],
        ),
      ),
    );
  }
}
