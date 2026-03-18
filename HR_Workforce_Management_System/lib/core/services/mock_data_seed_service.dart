import 'package:cloud_firestore/cloud_firestore.dart';

class MockDataSeedService {
  static final _db = FirebaseFirestore.instance;

  static Timestamp _ts(int y, int m, int d, [int h = 0, int min = 0]) {
    return Timestamp.fromDate(DateTime(y, m, d, h, min));
  }

  static Map<String, dynamic> _user({
    required String name,
    required String employeeId,
    required String designation,
    required String department,
    required String email,
    required String phone,
    required String role,
    required String status,
    String manager = '',
    String location = 'Mumbai Office',
    String employmentType = 'full-time',
    required Timestamp joiningDate,
    required num baseSalary,
    required num hra,
    required num conveyance,
    String bankLast4 = '',
    required int casualLeaveBalance,
    required int sickLeaveBalance,
    required int earnedLeaveBalance,
    String createdBy = 'admin001',
    required Timestamp createdAt,
  }) {
    return {
      'name': name,
      'employeeId': employeeId,
      'designation': designation,
      'department': department,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'isActive': status == 'active',
      'manager': manager,
      'location': location,
      'employmentType': employmentType,
      'joiningDate': joiningDate,
      'baseSalary': baseSalary,
      'basicSalary': baseSalary,
      'hra': hra,
      'conveyance': conveyance,
      'bankLast4': bankLast4,
      'casualLeaveBalance': casualLeaveBalance,
      'sickLeaveBalance': sickLeaveBalance,
      'earnedLeaveBalance': earnedLeaveBalance,
      'photoUrl': '',
      'createdAt': createdAt,
      'createdBy': createdBy,
      'username': email.split('@').first.toLowerCase(),
    };
  }

  static Map<String, dynamic> _attendanceRecord({
    required String date,
    Timestamp? clockIn,
    Timestamp? clockOut,
    required double totalHours,
    required String status,
    required String employeeName,
    required String department,
    required String designation,
  }) {
    return {
      'clockIn': clockIn,
      'clockOut': clockOut,
      'totalHours': totalHours,
      'status': status,
      'date': date,
      'employeeName': employeeName,
      'department': department,
      'designation': designation,
      'isManual': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> seedMockData() async {
    final users = <String, Map<String, dynamic>>{
      'emp001': _user(
        name: 'Ali Sayyed',
        employeeId: 'EQT101',
        designation: 'Flutter Developer',
        department: 'Developer',
        email: 'alisayyed@hrapp.internal',
        phone: '+91 9876543210',
        role: 'employee',
        status: 'active',
        manager: 'Sushant Patil',
        joiningDate: _ts(2024, 1, 10),
        baseSalary: 45000,
        hra: 18000,
        conveyance: 9000,
        bankLast4: '4291',
        casualLeaveBalance: 8,
        sickLeaveBalance: 8,
        earnedLeaveBalance: 15,
        createdAt: _ts(2024, 1, 10),
      ),
      'emp002': _user(
        name: 'Sarah Jenkins',
        employeeId: 'EQT102',
        designation: 'Senior Developer',
        department: 'Developer',
        email: 'sarahjenkins@hrapp.internal',
        phone: '+91 9876543211',
        role: 'employee',
        status: 'active',
        manager: 'Sushant Patil',
        joiningDate: _ts(2023, 3, 15),
        baseSalary: 65000,
        hra: 26000,
        conveyance: 9000,
        bankLast4: '3821',
        casualLeaveBalance: 6,
        sickLeaveBalance: 10,
        earnedLeaveBalance: 12,
        createdAt: _ts(2023, 3, 15),
      ),
      'emp003': _user(
        name: 'Marcus Thompson',
        employeeId: 'EQT103',
        designation: 'CRM Executive',
        department: 'CRM',
        email: 'marcusthompson@hrapp.internal',
        phone: '+91 9876543212',
        role: 'employee',
        status: 'active',
        manager: 'Sushant Patil',
        joiningDate: _ts(2022, 6, 20),
        baseSalary: 40000,
        hra: 16000,
        conveyance: 9000,
        bankLast4: '7612',
        casualLeaveBalance: 10,
        sickLeaveBalance: 7,
        earnedLeaveBalance: 18,
        createdAt: _ts(2022, 6, 20),
      ),
      'emp004': _user(
        name: 'Elena Rodriguez',
        employeeId: 'EQT104',
        designation: 'Project Manager',
        department: 'Project Manager',
        email: 'elenarodriguez@hrapp.internal',
        phone: '+91 9876543213',
        role: 'employee',
        status: 'active',
        manager: 'Sushant Patil',
        joiningDate: _ts(2023, 9, 5),
        baseSalary: 70000,
        hra: 28000,
        conveyance: 9000,
        bankLast4: '5544',
        casualLeaveBalance: 4,
        sickLeaveBalance: 9,
        earnedLeaveBalance: 20,
        createdAt: _ts(2023, 9, 5),
      ),
      'emp005': _user(
        name: 'Robert Fox',
        employeeId: 'EQT105',
        designation: 'Trainee',
        department: 'Trainee',
        email: 'robertfox@hrapp.internal',
        phone: '+91 9876543214',
        role: 'employee',
        status: 'active',
        manager: 'Sushant Patil',
        joiningDate: _ts(2024, 2, 1),
        baseSalary: 15000,
        hra: 6000,
        conveyance: 9000,
        bankLast4: '9901',
        casualLeaveBalance: 12,
        sickLeaveBalance: 10,
        earnedLeaveBalance: 0,
        createdAt: _ts(2024, 2, 1),
      ),
      'emp006': _user(
        name: 'Priya Mehta',
        employeeId: 'EQT106',
        designation: 'Administrator',
        department: 'Administration',
        email: 'priyamehta@hrapp.internal',
        phone: '+91 9876543215',
        role: 'employee',
        status: 'inactive',
        manager: 'Sushant Patil',
        joiningDate: _ts(2022, 1, 10),
        baseSalary: 35000,
        hra: 14000,
        conveyance: 9000,
        bankLast4: '1122',
        casualLeaveBalance: 0,
        sickLeaveBalance: 2,
        earnedLeaveBalance: 5,
        createdAt: _ts(2022, 1, 10),
      ),
      'admin001': {
        'name': 'Sushant Patil',
        'employeeId': 'EQT001',
        'designation': 'HR Manager',
        'department': 'Administration',
        'email': 'admin@equitec.com',
        'phone': '+91 9876543200',
        'role': 'admin',
        'status': 'active',
        'isActive': true,
        'location': 'Mumbai Office',
        'photoUrl': '',
        'createdAt': _ts(2021, 1, 1),
        'username': 'admin',
      },
    };

    for (final entry in users.entries) {
      await _db
          .collection('users')
          .doc(entry.key)
          .set(entry.value, SetOptions(merge: true));
    }

    final attendance = <String, Map<String, Map<String, dynamic>>>{
      'emp001': {
        '2023-10-02': _attendanceRecord(
          date: '2023-10-02',
          clockIn: _ts(2023, 10, 2, 9, 2),
          clockOut: _ts(2023, 10, 2, 18, 15),
          totalHours: 9.22,
          status: 'present',
          employeeName: 'Ali Sayyed',
          department: 'Developer',
          designation: 'Flutter Developer',
        ),
        '2023-10-03': _attendanceRecord(
          date: '2023-10-03',
          clockIn: _ts(2023, 10, 3, 9, 45),
          clockOut: _ts(2023, 10, 3, 18, 0),
          totalHours: 7.5,
          status: 'late',
          employeeName: 'Ali Sayyed',
          department: 'Developer',
          designation: 'Flutter Developer',
        ),
        '2023-10-06': _attendanceRecord(
          date: '2023-10-06',
          totalHours: 0,
          status: 'absent',
          employeeName: 'Ali Sayyed',
          department: 'Developer',
          designation: 'Flutter Developer',
        ),
      },
      'emp002': {
        '2023-10-02': _attendanceRecord(
          date: '2023-10-02',
          clockIn: _ts(2023, 10, 2, 9, 0),
          clockOut: _ts(2023, 10, 2, 18, 0),
          totalHours: 9,
          status: 'present',
          employeeName: 'Sarah Jenkins',
          department: 'Developer',
          designation: 'Senior Developer',
        ),
        '2023-10-05': _attendanceRecord(
          date: '2023-10-05',
          totalHours: 0,
          status: 'absent',
          employeeName: 'Sarah Jenkins',
          department: 'Developer',
          designation: 'Senior Developer',
        ),
      },
      'emp003': {
        '2023-10-04': _attendanceRecord(
          date: '2023-10-04',
          clockIn: _ts(2023, 10, 4, 10, 30),
          clockOut: _ts(2023, 10, 4, 18, 0),
          totalHours: 7.5,
          status: 'late',
          employeeName: 'Marcus Thompson',
          department: 'CRM',
          designation: 'CRM Executive',
        ),
      },
      'emp004': {
        '2023-10-04': _attendanceRecord(
          date: '2023-10-04',
          totalHours: 0,
          status: 'absent',
          employeeName: 'Elena Rodriguez',
          department: 'Project Manager',
          designation: 'Project Manager',
        ),
      },
      'emp005': {
        '2023-10-04': _attendanceRecord(
          date: '2023-10-04',
          clockIn: _ts(2023, 10, 4, 9, 0),
          clockOut: _ts(2023, 10, 4, 13, 0),
          totalHours: 4,
          status: 'half-day',
          employeeName: 'Robert Fox',
          department: 'Trainee',
          designation: 'Trainee',
        ),
      },
    };

    for (final empEntry in attendance.entries) {
      for (final recEntry in empEntry.value.entries) {
        await _db
            .collection('attendance')
            .doc(empEntry.key)
            .collection('records')
            .doc(recEntry.key)
            .set(recEntry.value, SetOptions(merge: true));
      }
    }

    final leaves = <String, Map<String, dynamic>>{
      'leave001': {
        'uid': 'emp001',
        'employeeName': 'Ali Sayyed',
        'designation': 'Flutter Developer',
        'department': 'Developer',
        'leaveType': 'sick',
        'fromDate': _ts(2023, 10, 12),
        'toDate': _ts(2023, 10, 13),
        'totalDays': 2,
        'reason': 'Viral fever, doctor advised rest.',
        'status': 'approved',
        'appliedOn': _ts(2023, 10, 11),
        'reviewedBy': 'admin001',
        'reviewedAt': _ts(2023, 10, 11),
        'rejectionReason': '',
      },
      'leave002': {
        'uid': 'emp002',
        'employeeName': 'Sarah Jenkins',
        'designation': 'Senior Developer',
        'department': 'Developer',
        'leaveType': 'casual',
        'fromDate': _ts(2023, 10, 24),
        'toDate': _ts(2023, 10, 27),
        'totalDays': 4,
        'reason': 'Family function out of city.',
        'status': 'pending',
        'appliedOn': _ts(2023, 10, 20),
        'reviewedBy': '',
        'reviewedAt': null,
        'rejectionReason': '',
      },
      'leave003': {
        'uid': 'emp003',
        'employeeName': 'Marcus Thompson',
        'designation': 'CRM Executive',
        'department': 'CRM',
        'leaveType': 'sick',
        'fromDate': _ts(2023, 10, 20),
        'toDate': _ts(2023, 10, 20),
        'totalDays': 1,
        'reason': 'Severe headache and cold.',
        'status': 'pending',
        'appliedOn': _ts(2023, 10, 19),
        'reviewedBy': '',
        'reviewedAt': null,
        'rejectionReason': '',
      },
      'leave004': {
        'uid': 'emp004',
        'employeeName': 'Elena Rodriguez',
        'designation': 'Project Manager',
        'department': 'Project Manager',
        'leaveType': 'earned',
        'fromDate': _ts(2023, 11, 1),
        'toDate': _ts(2023, 11, 5),
        'totalDays': 5,
        'reason': 'Planned vacation with family.',
        'status': 'pending',
        'appliedOn': _ts(2023, 10, 25),
        'reviewedBy': '',
        'reviewedAt': null,
        'rejectionReason': '',
      },
      'leave005': {
        'uid': 'emp005',
        'employeeName': 'Robert Fox',
        'designation': 'Trainee',
        'department': 'Trainee',
        'leaveType': 'casual',
        'fromDate': _ts(2023, 9, 18),
        'toDate': _ts(2023, 9, 18),
        'totalDays': 1,
        'reason': 'Personal work.',
        'status': 'rejected',
        'appliedOn': _ts(2023, 9, 15),
        'reviewedBy': 'admin001',
        'reviewedAt': _ts(2023, 9, 16),
        'rejectionReason': 'Insufficient casual leave balance.',
      },
      'leave006': {
        'uid': 'emp001',
        'employeeName': 'Ali Sayyed',
        'designation': 'Flutter Developer',
        'department': 'Developer',
        'leaveType': 'casual',
        'fromDate': _ts(2023, 11, 10),
        'toDate': _ts(2023, 11, 10),
        'totalDays': 1,
        'reason': 'Personal appointment.',
        'status': 'pending',
        'appliedOn': _ts(2023, 11, 1),
        'reviewedBy': '',
        'reviewedAt': null,
        'rejectionReason': '',
      },
    };

    for (final entry in leaves.entries) {
      await _db
          .collection('leaves')
          .doc(entry.key)
          .set(entry.value, SetOptions(merge: true));
    }

    Future<void> putPayroll(
      String uid,
      String docId,
      Map<String, dynamic> payload,
    ) async {
      await _db
          .collection('payroll')
          .doc(uid)
          .collection('months')
          .doc(docId)
          .set({
            ...payload,
            'monthYear': docId,
            'processedAt': _ts(2023, 10, 31),
          }, SetOptions(merge: true));
    }

    await putPayroll('emp001', 'october-2023', {
      'employeeId': 'EQT101',
      'employeeName': 'Ali Sayyed',
      'designation': 'Flutter Developer',
      'month': 'October',
      'year': 2023,
      'basicSalary': 45000,
      'hra': 18000,
      'conveyance': 9000,
      'grossSalary': 72000,
      'lateDeduction': 1000,
      'leaveDeduction': 0,
      'pf': 2800,
      'professionalTax': 200,
      'totalDeductions': 4000,
      'netSalary': 68000,
      'status': 'paid',
      'processedBy': 'admin001',
      'creditedOn': _ts(2023, 10, 31),
      'pdfSlipUrl': '',
    });

    await putPayroll('emp002', 'october-2023', {
      'employeeId': 'EQT102',
      'employeeName': 'Sarah Jenkins',
      'designation': 'Senior Developer',
      'month': 'October',
      'year': 2023,
      'basicSalary': 65000,
      'hra': 26000,
      'conveyance': 9000,
      'grossSalary': 100000,
      'lateDeduction': 500,
      'leaveDeduction': 2000,
      'pf': 4200,
      'professionalTax': 200,
      'totalDeductions': 6900,
      'netSalary': 93100,
      'status': 'pending',
      'processedBy': '',
      'creditedOn': null,
      'pdfSlipUrl': '',
    });

    await putPayroll('emp003', 'october-2023', {
      'employeeId': 'EQT103',
      'employeeName': 'Marcus Thompson',
      'designation': 'CRM Executive',
      'month': 'October',
      'year': 2023,
      'basicSalary': 40000,
      'hra': 16000,
      'conveyance': 9000,
      'grossSalary': 65000,
      'lateDeduction': 500,
      'leaveDeduction': 0,
      'pf': 2500,
      'professionalTax': 200,
      'totalDeductions': 3200,
      'netSalary': 61800,
      'status': 'paid',
      'processedBy': 'admin001',
      'creditedOn': _ts(2023, 10, 31),
      'pdfSlipUrl': '',
    });

    final logs = <String, Map<String, dynamic>>{
      'log001': {
        'message': 'Ali Sayyed clocked in at 09:02 AM',
        'type': 'clockin',
        'employeeName': 'Ali Sayyed',
        'uid': 'emp001',
        'timestamp': _ts(2023, 10, 5, 9, 2),
      },
      'log002': {
        'message': 'Sarah Jenkins submitted a Casual Leave request',
        'type': 'leave_request',
        'employeeName': 'Sarah Jenkins',
        'uid': 'emp002',
        'timestamp': _ts(2023, 10, 20, 10, 15),
      },
      'log003': {
        'message': 'Marcus Thompson clocked out at 06:00 PM',
        'type': 'clockout',
        'employeeName': 'Marcus Thompson',
        'uid': 'emp003',
        'timestamp': _ts(2023, 10, 5, 18, 0),
      },
      'log004': {
        'message': 'Payroll October 2023 processed for EQT101',
        'type': 'payroll',
        'employeeName': 'Ali Sayyed',
        'uid': 'emp001',
        'timestamp': _ts(2023, 10, 31, 17, 0),
      },
      'log005': {
        'message': 'Elena Rodriguez submitted an Earned Leave request',
        'type': 'leave_request',
        'employeeName': 'Elena Rodriguez',
        'uid': 'emp004',
        'timestamp': _ts(2023, 10, 25, 11, 30),
      },
      'log006': {
        'message': 'New employee Robert Fox (EQT105) added',
        'type': 'new_employee',
        'employeeName': 'Robert Fox',
        'uid': 'emp005',
        'timestamp': _ts(2024, 2, 1, 9, 0),
      },
      'log007': {
        'message': 'Ali Sayyed Sick Leave approved by Admin',
        'type': 'leave_approved',
        'employeeName': 'Ali Sayyed',
        'uid': 'emp001',
        'timestamp': _ts(2023, 10, 11, 14, 0),
      },
      'log008': {
        'message': 'Robert Fox Casual Leave rejected by Admin',
        'type': 'leave_rejected',
        'employeeName': 'Robert Fox',
        'uid': 'emp005',
        'timestamp': _ts(2023, 9, 16, 10, 0),
      },
    };

    for (final entry in logs.entries) {
      await _db
          .collection('activityLog')
          .doc(entry.key)
          .set(entry.value, SetOptions(merge: true));
    }

    Future<void> putNotif(
      String uid,
      String id,
      Map<String, dynamic> data,
    ) async {
      await _db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(id)
          .set(data, SetOptions(merge: true));
    }

    await putNotif('emp001', 'notif001', {
      'message': 'Your Sick Leave Oct 12-13 was Approved',
      'title': 'Leave Approved',
      'type': 'leave_approved',
      'isRead': true,
      'createdAt': _ts(2023, 10, 11, 14, 0),
    });
    await putNotif('emp001', 'notif002', {
      'message': 'Your October salary Rs 68,000 has been credited',
      'title': 'Payroll Update',
      'type': 'payroll',
      'isRead': false,
      'createdAt': _ts(2023, 10, 31, 17, 0),
    });
    await putNotif('admin001', 'notif001', {
      'message': '3 pending leave requests require approval',
      'title': 'Leave Requests',
      'type': 'leave_request',
      'isRead': false,
      'createdAt': _ts(2023, 10, 25, 11, 30),
    });

    await _db.collection('hrRules').doc('office_intime').set({
      'value': '09:00',
      'description': 'Office start time',
      'category': 'attendance',
    }, SetOptions(merge: true));
    await _db.collection('hrRules').doc('late_threshold_minutes').set({
      'value': '15',
      'description': 'Late buffer',
      'category': 'attendance',
    }, SetOptions(merge: true));
    await _db.collection('hrRules').doc('defaultCasualLeave').set({
      'value': '12',
      'description': 'Default casual leave',
      'category': 'leave',
    }, SetOptions(merge: true));
    await _db.collection('hrRules').doc('defaultSickLeave').set({
      'value': '10',
      'description': 'Default sick leave',
      'category': 'leave',
    }, SetOptions(merge: true));
    await _db.collection('hrRules').doc('defaultEarnedLeave').set({
      'value': '20',
      'description': 'Default earned leave',
      'category': 'leave',
    }, SetOptions(merge: true));

    await _db.collection('hr_rules').doc('equitec').set({
      'officeStartTime': '09:00',
      'lateBufferMinutes': 15,
      'maxLateMarksAllowed': 3,
      'lateDeductionPerMark': 500,
      'halfDayThresholdHours': 4,
      'absentDeductionPerDay': 2000,
      'pfPercentage': 12,
      'professionalTax': 200,
      'workingDaysPerWeek': 5,
      'officeLocation': 'Mumbai Office',
      'defaultCasualLeave': 12,
      'defaultSickLeave': 10,
      'defaultEarnedLeave': 20,
      'conveyanceFixed': 9000,
      'hraPercentage': 40,
    }, SetOptions(merge: true));
  }
}
