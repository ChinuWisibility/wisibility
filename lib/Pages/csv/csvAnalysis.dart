Map<String, dynamic> analyzeCsv(
    List<List<dynamic>> csvTable, Map<String, String?> mappings) {
  if (csvTable.isEmpty) return {'stats': {}, 'details': {}};

  final headers = csvTable.first.map((e) => e.toString().trim()).toList();
  final rows = csvTable.skip(1);

  int colIdxByMap(String mappedHeader) => headers.indexWhere(
          (h) => h.toLowerCase() == mappedHeader.toLowerCase());

  final idxEmployee = colIdxByMap(mappings['EmployeeID']!);
  final idxDisplayName = colIdxByMap(mappings['DisplayName']!);
  final idxTitle = colIdxByMap(mappings['Title']!);
  final idxDepartment = colIdxByMap(mappings['Department']!);
  final idxGroup = colIdxByMap(mappings['Groups']!);
  final idxEndDate = colIdxByMap(mappings['EndDate']!);
  final idxStatus = colIdxByMap(mappings['Status']!);
  final idxManager = colIdxByMap(mappings['ManagerID']!);
  final idxEmail = colIdxByMap(mappings['Email']!);
  final idxPhoneNumber = colIdxByMap(mappings['PhoneNumber']!);
  final idxLocation = colIdxByMap(mappings['Location']!);

  final now = DateTime.now();

  final displayNameSet = <String>{};
  final groupSet = <String>{};
  final departmentSet = <String>{};
  final managerSet = <String>{};

  final userGroupMap = <String, Set<String>>{};
  int maxGroupCount = 0;
  final maxGroupUsers = <String>[];

  final allUsers = <String>[];
  final activeUsers = <String>[];
  final inactiveUsers = <String>[];
  final expiringUsers = <String>[];
  final uniqueGroups = <String>[];
  final uniqueDepartments = <String>[];
  final uniqueManagers = <String>[];

  final activeWithPastEndDate = <String>[];
  final inactiveWithFutureEndDate = <String>[];
  final noManagerList = <String>[];
  final missingDisplayName = <String>[];
  final missingTitle = <String>[];
  final missingDepartment = <String>[];
  final noStatus = <String>[];
  final allGroups = <String>[];
  final noGroups = <String>[];
  final specialCharDisplayName = <String>[];

  for (final row in rows) {
    if (idxGroup >= 0 && row.length > idxGroup) {
      final val = row[idxGroup]?.toString().trim() ?? '';
      if (val.isNotEmpty) {
        final groups = val.split(';').map((g) => g.trim()).where((g) => g.isNotEmpty);
        groupSet.addAll(groups);
      }
    }

    if (idxDepartment >= 0 && row.length > idxDepartment) {
      final dep = row[idxDepartment]?.toString().trim() ?? '';
      if (dep.isNotEmpty) departmentSet.add(dep);
    }

    if (idxManager >= 0 && row.length > idxManager) {
      final mgr = row[idxManager]?.toString().trim() ?? '';
      if (mgr.isNotEmpty) managerSet.add(mgr);
    }
  }
  uniqueGroups.addAll(groupSet);
  uniqueDepartments.addAll(departmentSet);
  uniqueManagers.addAll(managerSet);

  for (final row in rows) {
    final empNum = (idxEmployee >= 0 && row.length > idxEmployee) ? row[idxEmployee]?.toString().trim() ?? '' : '';
    if (empNum.isEmpty) continue;

    final displayName = (idxDisplayName >= 0 && row.length > idxDisplayName) ? row[idxDisplayName]?.toString().trim() ?? '' : '';
    final title = (idxTitle >= 0 && row.length > idxTitle) ? row[idxTitle]?.toString().trim() ?? '' : '';
    final department = (idxDepartment >= 0 && row.length > idxDepartment) ? row[idxDepartment]?.toString().trim() ?? '' : '';
    final groupVal = (idxGroup >= 0 && row.length > idxGroup) ? row[idxGroup]?.toString().trim() ?? '' : '';
    final status = (idxStatus >= 0 && row.length > idxStatus) ? row[idxStatus]?.toString().trim().toLowerCase() : '';
    final manager = (idxManager >= 0 && row.length > idxManager) ? row[idxManager]?.toString().trim() ?? '' : '';
    final endDateStr = (idxEndDate >= 0 && row.length > idxEndDate) ? row[idxEndDate]?.toString().trim() : '';

    final userLabel = displayName.isNotEmpty ? displayName : empNum;
    if (displayName.isNotEmpty) displayNameSet.add(displayName);
    allUsers.add(userLabel);

    if (status == 'active') activeUsers.add(userLabel);
    if (status == 'inactive') inactiveUsers.add(userLabel);

    DateTime? endDate;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      try {
        if (endDateStr.contains('-')) {
          endDate = DateTime.parse(endDateStr);
        } else if (endDateStr.contains('/')) {
          final parts = endDateStr.split('/');
          if (parts.length == 3) {
            final m = int.parse(parts[0]);
            final d = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            endDate = DateTime(y, m, d);
          }
        }
      } catch (_) {}
    }

    if (endDate != null && endDate.isAfter(now) && endDate.difference(now).inDays <= 7) {
      expiringUsers.add(userLabel);
    }

    if (status == 'active' && endDate != null && endDate.isBefore(now)) {
      activeWithPastEndDate.add(userLabel);
    }
    if (status == 'inactive' && endDate != null && endDate.isAfter(now)) {
      inactiveWithFutureEndDate.add(userLabel);
    }

    if (manager.isEmpty) noManagerList.add(userLabel);
    if (displayName.isEmpty) missingDisplayName.add(userLabel);
    if (displayName.isNotEmpty && RegExp(r'[^\w\s]').hasMatch(displayName)) {
      specialCharDisplayName.add(userLabel);
    }
    if (title.isEmpty) missingTitle.add(userLabel);
    if (department.isEmpty) missingDepartment.add(userLabel);
    if (status!.isEmpty) noStatus.add(userLabel);

    final groups = groupVal.isNotEmpty
        ? groupVal.split(';').map((g) => g.trim()).where((g) => g.isNotEmpty).toSet()
        : <String>{};
    userGroupMap[userLabel] = groups;
    if (groups.isEmpty) noGroups.add(userLabel);

    if (groups.length > maxGroupCount) {
      maxGroupCount = groups.length;
      maxGroupUsers
        ..clear()
        ..add(userLabel);
    } else if (groups.length == maxGroupCount && maxGroupCount > 0) {
      maxGroupUsers.add(userLabel);
    }
  }

  for (final entry in userGroupMap.entries) {
    if (entry.value.length == groupSet.length && groupSet.isNotEmpty) {
      allGroups.add(entry.key);
    }
  }

  return {
    'stats': {
      'Display Name': displayNameSet.length,
      'User': allUsers.length,
      'Status': {
        'Active': activeUsers.length,
        'Inactive': inactiveUsers.length,
      },
      'Group': groupSet.length,
      'Department': departmentSet.length,
      'Manager': managerSet.length,
      'End Date': expiringUsers.length,
    },
    'details': {
      'AllUsers': allUsers,
      'ActiveUsers': activeUsers,
      'InactiveUsers': inactiveUsers,
      'UniqueGroups': uniqueGroups,
      'UniqueDepartments': uniqueDepartments,
      'UniqueManagers': uniqueManagers,
      'ExpiringUsers': expiringUsers,
      'ActiveWithPastEndDate': activeWithPastEndDate,
      'InactiveWithFutureEndDate': inactiveWithFutureEndDate,
      'NoManager': noManagerList,
      'MissingDisplayName': missingDisplayName,
      'MissingTitle': missingTitle,
      'MissingDepartment': missingDepartment,
      'NoStatus': noStatus,
      'AllGroups': allGroups,
      'MaxGroups': maxGroupUsers,
      'NoGroups': noGroups,
      'SpecialCharDisplayName': specialCharDisplayName,
    }
  };
}
