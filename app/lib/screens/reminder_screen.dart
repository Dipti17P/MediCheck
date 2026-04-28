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
  static const Color _primary = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFF0F6FF);

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
        title: const Text('Medicine Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _medicineNameController,
                        decoration: const InputDecoration(labelText: 'Medicine Name', prefixIcon: Icon(Icons.medication)),
                        validator: (v) => v!.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                        onTap: _pickTime,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addReminder,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _primary, foregroundColor: Colors.white),
                        child: const Text('Save Reminder'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, i) {
                    final r = _reminders[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: _primary, child: Icon(Icons.alarm, color: Colors.white)),
                        title: Text(r['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('At ${r['time']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onPressed: () async {
                                await CacheService.logAdherence(r['_id'], true);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken!')));
                              },
                              tooltip: 'Mark as Taken',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
