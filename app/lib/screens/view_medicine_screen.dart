import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViewMedicineScreen extends StatefulWidget {
  const ViewMedicineScreen({super.key});

  @override
  State<ViewMedicineScreen> createState() => _ViewMedicineScreenState();
}

class _ViewMedicineScreenState extends State<ViewMedicineScreen> {
  List<dynamic> _medicines = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Dosage tracking
  final Map<String, bool> _dosageLoading = {};
  final Map<String, Map<String, dynamic>> _dosageData = {};
  final Map<String, String> _dosageError = {};

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryDark  = Color(0xFF1E40AF);
  static const Color _primaryLight = Color(0xFF60A5FA);
  static const Color _bg           = Color(0xFFF8FAFC);
  static const Color _surface      = Colors.white;
  static const Color _textPrimary  = Color(0xFF0F172A);
  static const Color _textSecondary= Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getMedicines();
      setState(() {
        _medicines = data;
        _isLoading = false;
        // Clear dosage state on refresh
        _dosageLoading.clear();
        _dosageData.clear();
        _dosageError.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDosage(String medId, String medName) async {
    setState(() {
      _dosageLoading[medId] = true;
      _dosageError.remove(medId);
    });

    try {
      final data = await ApiService.getDosageRecommendation(medName);
      setState(() {
        _dosageData[medId] = data;
        _dosageLoading[medId] = false;
      });
    } catch (e) {
      setState(() {
        _dosageError[medId] = e.toString().replaceFirst('Exception: ', '');
        _dosageLoading[medId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'My Medicines',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchMedicines,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderDecoration(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-medicine').then((_) => _fetchMedicines()),
        backgroundColor: _primary,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeaderDecoration() {
    return Container(
      width: double.infinity,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchMedicines,
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No medicines added yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first medicine',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth;
              if (constraints.maxWidth > 900) cardWidth = (constraints.maxWidth - 32) / 3;
              else if (constraints.maxWidth > 600) cardWidth = (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _medicines.map((med) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildMedicineCard(med),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medData) {
    // Cast to Map safely
    final Map<String, dynamic> med = medData is Map ? Map<String, dynamic>.from(medData) : {};
    
    // Safely parse fields that might be Lists or Strings
    String parseField(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is List) return value.join(', ');
      return value.toString();
    }

    final String name = parseField(med['name'], 'Unknown Medicine');
    final String uses = parseField(med['uses'], 'No description provided');
    final String sideEffects = parseField(med['sideEffects'], 'None listed');
    final String medId = med['_id'] ?? name; // Use ID or name as key

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _primary.withAlpha(10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_rounded, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: _primary),
                  tooltip: 'Find Alternatives',
                  onPressed: () {
                    // We can pass the drug name as an argument if we update routing, 
                    // but standard pushNamed works fine, the user can just type it in. 
                    // Let's use push to pass arguments, or just go to the screen.
                    Navigator.pushNamed(context, '/find-alternatives');
                  },
                ),
              ],
            ),
          ),
          
          // Body of card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  icon: Icons.healing_outlined,
                  title: 'Uses',
                  content: uses,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  icon: Icons.warning_amber_outlined,
                  title: 'Side Effects',
                  content: sideEffects,
                  isWarning: true,
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                _buildDosageSection(medId, name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isWarning = false,
  }) {
    final Color color = isWarning ? const Color(0xFFF59E0B) : _primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDosageSection(String medId, String medName) {
    if (_dosageLoading[medId] == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2)),
      );
    }

    if (_dosageError[medId] != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Error: ${_dosageError[medId]}', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
      );
    }

    final data = _dosageData[medId];
    if (data == null) {
      return SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _fetchDosage(medId, medName),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Get Personalized Dosage AI', style: TextStyle(fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1), // Indigo
            backgroundColor: const Color(0xFF6366F1).withAlpha(15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final bool consultDoc = data['consultDoctorRequired'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withAlpha(10), // Indigo tinted
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 8),
              const Text('Personalized Dosage AI', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
              if (data['isPersonalized'] == true) ...[
                const Spacer(),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                const Text('Vitals Applied', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          const SizedBox(height: 12),
          _buildDosageRow('Recommended', data['recommendedDosage'] ?? 'Consult Doctor'),
          const SizedBox(height: 8),
          _buildDosageRow('Max Daily Limit', data['maxDailyDose'] ?? 'Unknown'),
          if (data['adjustmentsMade'] != null && data['adjustmentsMade'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['adjustmentsMade'], style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4))),
                ],
              ),
            ),
          ],
          if (data['specialInstructions'] != null && data['specialInstructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Instructions: ${data['specialInstructions']}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: consultDoc ? Colors.orange.shade50 : Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: consultDoc ? Colors.orange.shade200 : Colors.blueGrey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(consultDoc ? Icons.warning_rounded : Icons.info_rounded, size: 18, color: consultDoc ? Colors.orange.shade800 : Colors.blueGrey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['disclaimer'] ?? 'AI estimates are not medical advice. ALWAYS consult your prescribing doctor.',
                    style: TextStyle(fontSize: 12, color: consultDoc ? Colors.orange.shade900 : Colors.blueGrey.shade800, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold))),
      ],
    );
  }
}
