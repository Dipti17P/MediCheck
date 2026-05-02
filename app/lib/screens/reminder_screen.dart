import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryDark  = Color(0xFF1E40AF);
  static const Color _bg           = Color(0xFFF8FAFC);
  static const Color _surface      = Colors.white;
  static const Color _textPrimary  = Color(0xFF0F172A);
  static const Color _textSecondary= Color(0xFF64748B);

  bool _isLoading = true;
  String? _error;
  List<dynamic> _reminders = [];
  
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchReminders() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getReminders();
      if (mounted) {
        setState(() {
          _reminders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _addReminder() async {
    if (!_formKey.currentState!.validate() || _selectedTime == null) return;

    final name = _medicineNameController.text.trim();
    final hour = _selectedTime!.hour;
    final minute = _selectedTime!.minute;
    final timeStr = _selectedTime!.format(context);

    try {
      final res = await ApiService.addReminder({
        'medicineName': name,
        'time': timeStr,
        'hour': hour,
        'minute': minute,
      });

      // Schedule local notification
      final int id = res['_id'].hashCode; // Simple hash as id
      await NotificationService().scheduleMedicineReminder(id, name, hour, minute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder added!')));
        _medicineNameController.clear();
        setState(() => _selectedTime = null);
        _fetchReminders();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteReminder(dynamic reminder) async {
    final String id = reminder['_id'];
    try {
      await ApiService.deleteReminder(id);
      await NotificationService().cancelReminder(id.hashCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
        _fetchReminders();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _medicineNameController,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Medicine Name',
                              labelStyle: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.medication_rounded, color: _primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _primary, width: 2),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: _primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime == null ? 'Select Alert Time' : 'Time: ${_selectedTime!.format(context)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTime == null ? _textSecondary : _textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addReminder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _reminders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 64, color: _textSecondary.withAlpha(50)),
                            const SizedBox(height: 16),
                            const Text('No reminders set yet', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reminders.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, i) {
                          final r = _reminders[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primary.withAlpha(15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_active_rounded, color: _primary, size: 24),
                              ),
                              title: Text(
                                r['medicineName'],
                                style: const TextStyle(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Daily at ${r['time']}',
                                  style: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                                    onPressed: () async {
                                      await CacheService.logAdherence(r['_id'], true);
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken!')));
                                    },
                                    tooltip: 'Mark as Taken',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                                    onPressed: () => _deleteReminder(r),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
