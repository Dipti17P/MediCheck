import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF0F6FF);

  bool _isLoading = true;
  String? _error;
  List<dynamic> _reminders = [];
  
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  TimeOfDay? _selectedTime;
  String _selectedFrequency = 'daily';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    final formattedTime = _selectedTime!.format(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.addReminder(
        medicineName: _medicineNameController.text.trim(),
        time: formattedTime,
        frequency: _selectedFrequency,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      _medicineNameController.clear();
      setState(() {
        _selectedTime = null;
        _selectedFrequency = 'daily';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder set successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchReminders();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleReminderStatus(String id, bool currentStatus) async {
    try {
      // Optimistic UI update
      setState(() {
        final index = _reminders.indexWhere((r) => r['_id'] == id);
        if (index != -1) {
          _reminders[index]['isTaken'] = !currentStatus;
        }
      });

      await ApiService.updateReminderStatus(id, !currentStatus);
    } catch (e) {
      // Revert on failure
      setState(() {
        final index = _reminders.indexWhere((r) => r['_id'] == id);
        if (index != -1) {
          _reminders[index]['isTaken'] = currentStatus;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReminders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAddReminderCard(),
              const SizedBox(height: 30),
              const Text(
                'Your Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 16),
              _buildRemindersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddReminderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryLight.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.alarm_add_rounded, color: _primaryLight, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Reminder',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A)),
                    ),
                    Text(
                      'Never miss a dose',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _medicineNameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                prefixIcon: const Icon(Icons.medication, color: _primaryLight),
                filled: true,
                fillColor: const Color(0xFFF5F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: _primaryLight),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedTime != null ? Colors.black87 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFrequency,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryLight),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'once', child: Text('Once')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFrequency = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Set Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Oops, something went wrong!', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _fetchReminders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_reminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.black26),
            SizedBox(height: 16),
            Text('No reminders yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Your scheduled medicines will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return Column(
      children: _reminders.map((reminder) {
        final isTaken = reminder['isTaken'] ?? false;
        final freq = reminder['frequency'] ?? 'daily';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isTaken ? Colors.green.shade200 : Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTaken ? Colors.green.shade50 : _primaryLight.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
                color: isTaken ? Colors.green : _primaryLight,
              ),
            ),
            title: Text(
              reminder['medicineName'] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isTaken ? TextDecoration.lineThrough : null,
                color: isTaken ? Colors.black54 : Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: isTaken ? Colors.black38 : Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    reminder['time'] ?? '--:--',
                    style: TextStyle(color: isTaken ? Colors.black38 : Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      freq.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
            trailing: isTaken 
              ? IconButton(
                  icon: const Icon(Icons.undo, color: Colors.grey),
                  onPressed: () => _toggleReminderStatus(reminder['_id'], true),
                  tooltip: 'Mark as un-taken',
                )
              : ElevatedButton(
                  onPressed: () => _toggleReminderStatus(reminder['_id'], false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Mark Taken'),
                ),
          ),
        );
      }).toList(),
    );
  }
}
