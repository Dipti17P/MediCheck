import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryDark  = Color(0xFF1E40AF);
  static const Color _primaryLight = Color(0xFF60A5FA);
  static const Color _bg           = Color(0xFFF8FAFC);
  static const Color _surface      = Colors.white;
  static const Color _textPrimary  = Color(0xFF0F172A);
  static const Color _textSecondary= Color(0xFF64748B);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  final _allergiesController = TextEditingController();
  final _historyController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = data;
          
          final allergies = data['allergies'] as List<dynamic>?;
          if (allergies != null && allergies.isNotEmpty) {
            _allergiesController.text = allergies.join(', ');
          }
          
          _historyController.text = data['medicalHistory'] ?? '';
          
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

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final allergiesList = _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updatedProfile = await ApiService.updateProfile(
        allergies: allergiesList,
        medicalHistory: _historyController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _profile = updatedProfile['user'];
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing && _profile != null) {
                  final allergies = _profile!['allergies'] as List<dynamic>?;
                  _allergiesController.text = allergies != null ? allergies.join(', ') : '';
                  _historyController.text = _profile!['medicalHistory'] ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: _primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red.withAlpha(20), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final name = _profile!['name'] ?? 'User';
    final email = _profile!['email'] ?? 'No email';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary.withAlpha(40), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: _primary.withAlpha(20),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 15, color: _textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Medical Information Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _primary.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.medical_services_rounded, color: _primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text('Health Profile', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _textPrimary, letterSpacing: -0.5)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                    ),
                    
                    const Text('Known Allergies', style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 15)),
                    const SizedBox(height: 10),
                    _isEditing
                        ? TextField(
                            controller: _allergiesController,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'E.g., Peanuts, Penicillin (comma separated)',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 2)),
                            ),
                          )
                        : Text(
                            _allergiesController.text.isEmpty ? 'No allergies reported.' : _allergiesController.text,
                            style: const TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                    
                    const SizedBox(height: 24),
                    
                    const Text('Medical History', style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 15)),
                    const SizedBox(height: 10),
                    _isEditing
                        ? TextField(
                            controller: _historyController,
                            maxLines: 4,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Brief medical history...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 2)),
                            ),
                          )
                        : Text(
                            _historyController.text.isEmpty ? 'No medical history reported.' : _historyController.text,
                            style: const TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                          ),

                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Save Health Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Compliance & Security Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _primary.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.security_rounded, color: _primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text('Privacy & Security', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _textPrimary, letterSpacing: -0.5)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.privacy_tip_outlined, size: 20, color: _textSecondary),
                      ),
                      title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: _textSecondary),
                      onTap: () => _showLegalDialog('Privacy Policy', 'Your privacy is our priority. We handle your medicine data with industry-standard encryption and never share it with third parties without your explicit consent.'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.gavel_outlined, size: 20, color: _textSecondary),
                      ),
                      title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: _textSecondary),
                      onTap: () => _showLegalDialog('Terms of Service', 'By using MediCheck AI, you agree to our service terms. This application provides informational content and is not a substitute for professional medical consultation or diagnosis.'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Data Management', style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportData,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Export JSON'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: _textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmDeleteAccount,
                            icon: const Icon(Icons.delete_forever_rounded, size: 18),
                            label: const Text('Delete Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withAlpha(20),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset_rounded, size: 20),
                        label: const Text('Update Security Password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Logout Button
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                  label: const Text('Sign Out of Application', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w900, color: _textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[0-9])').hasMatch(v)) return 'Must contain a letter and a number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w700))),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSaving = true);
                  try {
                    await ApiService.changePassword(
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Update Now', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: _textPrimary)),
        content: SingleChildScrollView(child: Text(content, style: const TextStyle(color: _textSecondary, fontWeight: FontWeight.w500, height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = await ApiService.exportData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Data Export Ready', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('Your health data has been prepared in secure JSON format and is ready for download.', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Permanently Delete Account?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
        content: const Text('This action is irreversible and will delete all your medicine history, reminders, and profile information from our secure servers.', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w800))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteAccount();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
