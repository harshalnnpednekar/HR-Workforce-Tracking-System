import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/admin_employee_service.dart';
import '../../../../core/services/attendance_service.dart';
import '../../../../core/services/payroll_service.dart';
import '../widgets/admin_ui_kit.dart';

class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _employees = const [];
  List<Map<String, dynamic>> _filteredEmployees = const [];
  bool _isLoading = true;
  String? _error;

  String? _selectedDepartment;
  String? _selectedStatus;
  String? _selectedDesignation;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_applySearch)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await AdminEmployeeService.getEmployees(
        department: _selectedDepartment,
        status: _selectedStatus,
        designation: _selectedDesignation,
      );
      if (!mounted) return;
      setState(() {
        _employees = rows;
        _isLoading = false;
      });
      _applySearch();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load employees.';
      });
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    final next = _employees.where((employee) {
      if (query.isEmpty) return true;
      final name = (employee['name'] as String?)?.toLowerCase() ?? '';
      final id = (employee['employeeId'] as String?)?.toLowerCase() ?? '';
      final role = (employee['designation'] as String?)?.toLowerCase() ?? '';
      return name.contains(query) || id.contains(query) || role.contains(query);
    }).toList();

    setState(() {
      _filteredEmployees = next;
    });
  }

  List<String> _distinctValues(String field) {
    final set = <String>{};
    for (final row in _employees) {
      final value = (row[field] as String?)?.trim() ?? '';
      if (value.isNotEmpty) {
        set.add(value);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _pickFilter({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelected,
  }) async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'All $title',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: selected == null
                    ? const Icon(
                        Icons.check_rounded,
                        color: AdminColors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(null),
              ),
              ...options.map(
                (value) => ListTile(
                  title: Text(value),
                  trailing: selected == value
                      ? const Icon(
                          Icons.check_rounded,
                          color: AdminColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (choice == selected) {
      return;
    }

    setState(() {
      onSelected(choice);
    });
    await _loadEmployees();
  }

  Future<void> _showAddEmployeeDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddEmployeeDialog(),
    );

    if (!mounted || result == null) {
      return;
    }

    final employeeId = (result['employeeId'] as String?) ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Employee $employeeId created successfully.')),
    );
    await _loadEmployees();
  }

  Future<void> _openEmployee(String uid) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _EmployeeDetailScreen(uid: uid)));
    await _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final departments = _distinctValues('department');
    final designations = _distinctValues('designation');

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Employees',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AdminColors.text,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showAddEmployeeDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Add Employee'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFFB2BED2)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, ID or role',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(
                  label: _selectedDepartment ?? 'All Departments',
                  active: _selectedDepartment != null,
                  onTap: () => _pickFilter(
                    title: 'Departments',
                    options: departments,
                    selected: _selectedDepartment,
                    onSelected: (value) => _selectedDepartment = value,
                  ),
                ),
                _FilterChip(
                  label: _selectedStatus == null
                      ? 'All Status'
                      : _selectedStatus == 'active'
                      ? 'Active'
                      : 'Inactive',
                  active: _selectedStatus != null,
                  onTap: () => _pickFilter(
                    title: 'Status',
                    options: const ['active', 'inactive'],
                    selected: _selectedStatus,
                    onSelected: (value) => _selectedStatus = value,
                  ),
                ),
                _FilterChip(
                  label: _selectedDesignation ?? 'All Designation',
                  active: _selectedDesignation != null,
                  onTap: () => _pickFilter(
                    title: 'Designations',
                    options: designations,
                    selected: _selectedDesignation,
                    onSelected: (value) => _selectedDesignation = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'ALL MEMBERS (${_filteredEmployees.length})',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadEmployees,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const AdminSurfaceCard(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              AdminSurfaceCard(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (_filteredEmployees.isEmpty)
              const AdminSurfaceCard(
                child: Text(
                  'No employees found for selected filters.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ..._filteredEmployees.map(
                (employee) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _EmployeeCard(
                    employee: employee,
                    onTap: () => _openEmployee(employee['id'] as String),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  static const List<String> _departments = [
    'Administration',
    'Developer',
    'CRM',
    'Project Manager',
    'Trainee',
  ];

  static const Map<String, List<String>> _departmentDesignations = {
    'Administration': ['Administrator', 'Office Manager'],
    'Developer': [
      'Junior Developer',
      'Senior Developer',
      'Full Stack Developer',
      'Flutter Developer',
    ],
    'CRM': ['CRM Executive', 'CRM Manager'],
    'Project Manager': ['Project Manager', 'Associate PM'],
    'Trainee': ['Trainee'],
  };

  static const List<String> _employmentTypes = [
    'Full Time',
    'Part Time',
    'Contract',
  ];

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _bankLast4Ctrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  DateTime _joiningDate = DateTime.now();
  String _department = _departments.first;
  String _designation = _departmentDesignations[_departments.first]!.first;
  String _employmentType = _employmentTypes.first;

  String _employeeId = 'Generating...';
  String _managerName = 'Administrator';
  String _location = 'Mumbai Office';

  int _casualLeaveBalance = 12;
  int _sickLeaveBalance = 10;
  int _earnedLeaveBalance = 20;
  int _conveyance = 9000;

  bool _loadingDefaults = true;
  bool _creating = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    _bankLast4Ctrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || adminUid.isEmpty) {
      if (!mounted) return;
      setState(() => _loadingDefaults = false);
      return;
    }

    try {
      final defaults = await AdminEmployeeService.getEmployeeCreateDefaults(
        adminUid,
      );
      final employeeId = await AdminEmployeeService.generateUniqueEmployeeId();
      if (!mounted) return;
      setState(() {
        _managerName = (defaults['managerName'] as String?) ?? _managerName;
        _location = (defaults['location'] as String?) ?? _location;
        _conveyance = (defaults['conveyance'] as int?) ?? _conveyance;
        _casualLeaveBalance =
            (defaults['casualLeaveBalance'] as int?) ?? _casualLeaveBalance;
        _sickLeaveBalance =
            (defaults['sickLeaveBalance'] as int?) ?? _sickLeaveBalance;
        _earnedLeaveBalance =
            (defaults['earnedLeaveBalance'] as int?) ?? _earnedLeaveBalance;
        _employeeId = employeeId;
        _loadingDefaults = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employeeId = 'EQT000';
        _loadingDefaults = false;
      });
    }
  }

  Future<void> _regenerateEmployeeId() async {
    setState(() => _loadingDefaults = true);
    try {
      final employeeId = await AdminEmployeeService.generateUniqueEmployeeId();
      if (!mounted) return;
      setState(() {
        _employeeId = employeeId;
        _loadingDefaults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDefaults = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || adminUid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin session not found.')));
      return;
    }

    setState(() => _creating = true);
    try {
      final result = await AdminEmployeeService.createEmployee(
        adminUid: adminUid,
        fullName: _fullNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        employeeId: _employeeId,
        designation: _designation,
        department: _department,
        phone: _phoneCtrl.text.trim(),
        joiningDate: _joiningDate,
        bankLast4: _bankLast4Ctrl.text.trim(),
        location: _location,
        manager: _managerName,
        employmentType: _employmentType,
        baseSalary: double.tryParse(_salaryCtrl.text.trim()) ?? 0,
        conveyance: _conveyance,
        casualLeaveBalance: _casualLeaveBalance,
        sickLeaveBalance: _sickLeaveBalance,
        earnedLeaveBalance: _earnedLeaveBalance,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on AdminEmployeeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong, please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Employee',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Personal Info'),
                  _textField(
                    _fullNameCtrl,
                    'Full Name*',
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Full Name is required'
                        : null,
                  ),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      final phone = (value ?? '').trim();
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                        return 'Enter a valid 10 digit phone number';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Phone Number*',
                      prefixText: '+91 ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Work Info'),
                  DropdownButtonFormField<String>(
                    value: _department,
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _department = value;
                        final options =
                            _departmentDesignations[value] ??
                            const ['Employee'];
                        if (!options.contains(_designation)) {
                          _designation = options.first;
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Department*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _designation,
                    items:
                        (_departmentDesignations[_department] ??
                                const ['Employee'])
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _designation = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Designation*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _joiningDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked == null) return;
                      setState(() => _joiningDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Joining Date*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_joiningDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _employmentType,
                    items: _employmentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _employmentType = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Employment Type*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Salary Info'),
                  TextFormField(
                    controller: _salaryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final salary = double.tryParse((value ?? '').trim()) ?? 0;
                      if (salary <= 0) {
                        return 'Base Salary is required';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Base Salary*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _bankLast4Ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      final bank = (value ?? '').trim();
                      if (bank.isNotEmpty &&
                          !RegExp(r'^[0-9]{4}$').hasMatch(bank)) {
                        return 'Bank Account Last 4 Digits should be 4 digits';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Bank Account Last 4 Digits',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Login Credentials'),
                  TextFormField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9._]'),
                      ),
                    ],
                    validator: (value) {
                      final username = (value ?? '').trim().toLowerCase();
                      if (username.isEmpty) {
                        return 'Username is required';
                      }
                      if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
                        return 'Only letters, numbers, dot and underscore allowed';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Username*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Login email: ${_usernameCtrl.text.trim().toLowerCase().isEmpty ? '<username>' : _usernameCtrl.text.trim().toLowerCase()}@hrapp.internal',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password*',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if ((value ?? '') != _passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password*',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Auto Generated'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Employee ID: $_employeeId')),
                            IconButton(
                              onPressed: _loadingDefaults
                                  ? null
                                  : _regenerateEmployeeId,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        Text('Manager: $_managerName'),
                        Text('Location: $_location'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _creating
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              _creating ||
                                  _loadingDefaults ||
                                  _employeeId == 'Generating...'
                              ? null
                              : _submit,
                          child: _creating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Employee'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AdminColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AdminColors.primary : AdminColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF566C8D),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : const Color(0xFF566C8D),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.onTap});

  final Map<String, dynamic> employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = ((employee['status'] as String?) ?? 'inactive')
        .toLowerCase()
        .trim();
    final isActive = status == 'active';
    final name = (employee['name'] as String?) ?? 'Employee';
    final email = (employee['email'] as String?) ?? '-';
    final employeeId = (employee['employeeId'] as String?) ?? '-';
    final designation = (employee['designation'] as String?) ?? '-';
    final photoUrl = (employee['photoUrl'] as String?) ?? '';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();

    return AdminSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFFEDE3)
                  : const Color(0xFFEAF0F7),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: photoUrl.isEmpty
                ? Text(
                    initials,
                    style: TextStyle(
                      color: isActive
                          ? AdminColors.primary
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        initials,
                        style: TextStyle(
                          color: isActive
                              ? AdminColors.primary
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AdminColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AdminStatusPill(
                      label: isActive ? 'ACTIVE' : 'INACTIVE',
                      backgroundColor: isActive
                          ? const Color(0xFFE2FBE8)
                          : const Color(0xFFF0F3F8),
                      textColor: isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$employeeId · $designation',
                  style: const TextStyle(
                    color: Color(0xFF7B8CA8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFA0AEC0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA8BE)),
        ],
      ),
    );
  }
}

class _EmployeeDetailScreen extends StatefulWidget {
  const _EmployeeDetailScreen({required this.uid});

  final String uid;

  @override
  State<_EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<_EmployeeDetailScreen> {
  late Future<_EmployeeDetailData?> _detailFuture;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<_EmployeeDetailData?> _loadDetail() async {
    final user = await AdminEmployeeService.getEmployeeById(widget.uid);
    if (user == null) {
      return null;
    }

    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final attendance = await AttendanceService.getMonthlyAttendance(
      widget.uid,
      month,
    );

    var presentDays = 0;
    var lateDays = 0;
    for (final item in attendance) {
      final status = (item['status'] as String?)?.toLowerCase() ?? '';
      if (status == 'present' || status == 'done' || status == 'late') {
        presentDays += 1;
      }
      if (status == 'late') {
        lateDays += 1;
      }
    }

    final payroll = await PayrollService.getCurrentMonthPayroll(widget.uid);

    return _EmployeeDetailData(
      user: user,
      presentDays: presentDays,
      lateDays: lateDays,
      payroll: payroll,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = _loadDetail();
    });
    await _detailFuture;
  }

  Future<void> _editEmployee(Map<String, dynamic> user) async {
    final formKey = GlobalKey<FormState>();
    final designationCtrl = TextEditingController(
      text: (user['designation'] as String?) ?? '',
    );
    final departmentCtrl = TextEditingController(
      text: (user['department'] as String?) ?? '',
    );
    final managerCtrl = TextEditingController(
      text: (user['manager'] as String?) ?? '',
    );
    final locationCtrl = TextEditingController(
      text: (user['location'] as String?) ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: (user['phone'] as String?) ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Employee',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _editableField(designationCtrl, 'Designation'),
                  _editableField(departmentCtrl, 'Department'),
                  _editableField(managerCtrl, 'Manager'),
                  _editableField(locationCtrl, 'Location'),
                  _editableField(phoneCtrl, 'Phone'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            await AdminEmployeeService.updateEmployee(
                              widget.uid,
                              {
                                'designation': designationCtrl.text.trim(),
                                'department': departmentCtrl.text.trim(),
                                'manager': managerCtrl.text.trim(),
                                'location': locationCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              },
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            await _refresh();
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deactivate(Map<String, dynamic> user) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || adminUid.isEmpty) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Employee'),
        content: Text(
          'Do you want to deactivate ${(user['name'] as String?) ?? 'this employee'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _updating = true);
    try {
      await AdminEmployeeService.deactivateEmployee(
        uid: widget.uid,
        adminUid: adminUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deactivated successfully.')),
      );
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Details')),
      body: FutureBuilder<_EmployeeDetailData?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('Employee not found.'));
          }

          final detail = snapshot.data!;
          final user = detail.user;
          final status = ((user['status'] as String?) ?? 'inactive')
              .toLowerCase();
          final payroll = detail.payroll;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user['name'] as String?) ?? '-',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(user['employeeId'] as String?) ?? '-'} · ${(user['designation'] as String?) ?? '-'}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (user['email'] as String?) ?? '-',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    AdminStatusPill(
                      label: status.toUpperCase(),
                      backgroundColor: status == 'active'
                          ? const Color(0xFFE2FBE8)
                          : const Color(0xFFF0F3F8),
                      textColor: status == 'active'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AdminSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Summary (This Month)',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text('Present Days: ${detail.presentDays}'),
                    Text('Late Days: ${detail.lateDays}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AdminSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leave Balances',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Casual: ${((user['casualLeaveBalance'] as num?) ?? 0).toInt()}',
                    ),
                    Text(
                      'Sick: ${((user['sickLeaveBalance'] as num?) ?? 0).toInt()}',
                    ),
                    Text(
                      'Earned: ${((user['earnedLeaveBalance'] as num?) ?? 0).toInt()}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AdminSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payroll Info',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                         Text(
                           'Basic Salary: ₹${NumberFormat('#,##0').format((user['basicSalary'] as num?) ?? 0)}',
                    ),
                         Text(
                           'Current Net Pay: ₹${NumberFormat('#,##0').format((payroll?['netSalary'] as num?) ?? 0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _updating ? null : () => _editEmployee(user),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _updating
                          ? null
                          : status == 'inactive'
                          ? null
                          : () => _deactivate(user),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                      ),
                      icon: _updating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.block_rounded),
                      label: const Text('Deactivate'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _editableField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _EmployeeDetailData {
  const _EmployeeDetailData({
    required this.user,
    required this.presentDays,
    required this.lateDays,
    required this.payroll,
  });

  final Map<String, dynamic> user;
  final int presentDays;
  final int lateDays;
  final Map<String, dynamic>? payroll;
}
