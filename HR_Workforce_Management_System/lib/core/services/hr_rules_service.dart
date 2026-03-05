import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: `hrRules`
///
/// Document ID = ruleName (e.g. 'office_intime')
/// Document fields: value (String), description, category
///
/// Default rules seeded by [HrRulesService.seedDefaults]:
///   office_intime, office_outtime, late_threshold_minutes,
///   max_late_marks_per_month, halfday_threshold_hours
class HrRulesService {
  static final _db = FirebaseFirestore.instance;

  /// Returns all HR rules as a map of { ruleName: value }.
  static Future<Map<String, String>> getAllRules() async {
    final snap = await _db.collection('hrRules').get();
    return {for (final d in snap.docs) d.id: d.data()['value'] as String};
  }

  /// Returns the value of a single rule by [ruleName].
  static Future<String?> getRule(String ruleName) async {
    final doc = await _db.collection('hrRules').doc(ruleName).get();
    return doc.data()?['value'] as String?;
  }

  /// Admin: updates a rule value.
  static Future<void> updateRule(String ruleName, String value) async {
    await _db.collection('hrRules').doc(ruleName).update({'value': value});
  }

  /// Seeds default HR rules. Run once during initial setup.
  static Future<void> seedDefaults() async {
    final defaults = {
      'office_intime': {
        'value': '09:30',
        'description': 'Standard office in-time (HH:MM)',
        'category': 'attendance',
      },
      'office_outtime': {
        'value': '18:30',
        'description': 'Standard office out-time (HH:MM)',
        'category': 'attendance',
      },
      'late_threshold_minutes': {
        'value': '15',
        'description': 'Grace period in minutes before marking late',
        'category': 'attendance',
      },
      'max_late_marks_per_month': {
        'value': '3',
        'description': 'Max late marks allowed per month',
        'category': 'attendance',
      },
      'halfday_threshold_hours': {
        'value': '4',
        'description': 'Hours below which attendance is half-day',
        'category': 'attendance',
      },
    };

    final batch = _db.batch();
    defaults.forEach((ruleId, data) {
      batch.set(
        _db.collection('hrRules').doc(ruleId),
        data,
        SetOptions(merge: true), // don't overwrite existing values
      );
    });
    await batch.commit();
  }
}
