Map<String, List<String>> validateCsv({
  required List<List<dynamic>> csvTable,
  required List<String> headers,
  required Map<String, String?> mappedFields,
}) {
  final List<String> allUsers = [];
  final List<String> activeUsers = [];
  final List<String> inactiveUsers = [];
  final Set<String> uniqueGroups = {};
  final Set<String> uniqueManagers = {};
  final Set<String> uniqueDepartments = {};
  final List<String> expiringUsers = [];
  final List<String> activeWithPastEndDate = [];
  final List<String> inactiveWithFutureEndDate = [];
  final List<String> noManager = [];
  final List<String> missingDisplayName = [];
  final List<String> missingTitle = [];
  final List<String> missingDepartment = [];
  final List<String> noStatus = [];
  final List<String> noGroups = [];
  final List<String> specialCharDisplayName = [];

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
    if (status == 'active') activeUsers.add(name);
    if (status == 'inactive') inactiveUsers.add(name);
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

  return {
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
}
