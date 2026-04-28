import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String medicineBox = 'medicines';
  static const String reminderBox = 'reminders';
  static const String profileBox = 'profile';
  static const String adherenceBox = 'adherence';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(medicineBox);
    await Hive.openBox(reminderBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(adherenceBox);
  }

  // ── Medicines ─────────────────────────────────────
  static Future<void> cacheMedicines(List<dynamic> medicines) async {
    final box = Hive.box(medicineBox);
    await box.put('list', medicines);
  }

  static List<dynamic> getCachedMedicines() {
    final box = Hive.box(medicineBox);
    return box.get('list', defaultValue: []);
  }

  // ── Reminders ─────────────────────────────────────
  static Future<void> cacheReminders(List<dynamic> reminders) async {
    final box = Hive.box(reminderBox);
    await box.put('list', reminders);
  }

  static List<dynamic> getCachedReminders() {
    final box = Hive.box(reminderBox);
    return box.get('list', defaultValue: []);
  }

  // ── Profile ───────────────────────────────────────
  static Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(profileBox);
    await box.put('data', profile);
  }

  static Map<String, dynamic> getCachedProfile() {
    final box = Hive.box(profileBox);
    return Map<String, dynamic>.from(box.get('data', defaultValue: {}));
  }

  // ── Adherence ─────────────────────────────────────
  static Future<void> logAdherence(String medicineId, bool taken) async {
    final box = Hive.box(adherenceBox);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final records = box.get(today, defaultValue: []) as List;
    
    records.add({
      'medicineId': medicineId,
      'status': taken ? 'taken' : 'skipped',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await box.put(today, records);
  }

  static List<dynamic> getAdherenceForDate(DateTime date) {
    final box = Hive.box(adherenceBox);
    final dateStr = date.toIso8601String().split('T')[0];
    return box.get(dateStr, defaultValue: []);
  }
}
