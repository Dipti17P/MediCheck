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

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary      = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg           = Color(0xFFF0F6FF);

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
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
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
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-medicine').then((_) => _fetchMedicines()),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderDecoration() {
    return Container(
      width: double.infinity,
      height: 20,
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final med = _medicines[index];
        return _buildMedicineCard(med);
      },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: _primaryLight.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medication_rounded, color: _primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: isWarning ? Colors.orange[700] : Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.orange[800] : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
