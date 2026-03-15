/// Centralized department catalog used across the app.
class DepartmentCatalog {
  static const List<String> values = [
    'Administrator',
    'Developer',
    'CRM',
    'Project Manager',
    'Trainee',
  ];

  static bool isValid(String? department) {
    if (department == null) return false;
    return values.contains(department.trim());
  }
}
