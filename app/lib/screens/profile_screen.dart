import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFF0F6FF);

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
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // If cancelling edit, reset fields
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _primary.withAlpha(30),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: _primary),
                    SizedBox(width: 8),
                    Text('Medical Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 30),
                
                const Text('Known Allergies', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(
                        controller: _allergiesController,
                        decoration: InputDecoration(
                          hintText: 'E.g., Peanuts, Penicillin (comma separated)',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      )
                    : Text(
                        _allergiesController.text.isEmpty ? 'No allergies reported.' : _allergiesController.text,
                        style: const TextStyle(color: Colors.black54),
                      ),
                
                const SizedBox(height: 20),
                
                const Text('Medical History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(
                        controller: _historyController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Brief medical history...',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      )
                    : Text(
                        _historyController.text.isEmpty ? 'No medical history reported.' : _historyController.text,
                        style: const TextStyle(color: Colors.black54),
                      ),

                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Logout
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
