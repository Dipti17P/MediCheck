import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF0F6FF);

  bool _isLoadingMedicines = true;
  List<dynamic> _savedMedicines = [];
  final List<String> _selectedMedicines = [];

  bool _isChecking = false;
  List<Map<String, dynamic>>? _interactions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSavedMedicines();
  }

  Future<void> _fetchSavedMedicines() async {
    setState(() => _isLoadingMedicines = true);
    try {
      final meds = await ApiService.getMedicines();
      if (mounted) {
        setState(() {
          _savedMedicines = meds;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medicines: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMedicines = false);
    }
  }

  Future<void> _checkInteraction() async {
    if (_selectedMedicines.length < 2) {
      setState(() {
        _error = 'Please select at least two medicines to check interactions.';
        _interactions = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
      _interactions = null;
    });

    try {
      final response = await ApiService.checkInteractions(_selectedMedicines);
      if (mounted) {
        setState(() {
          _interactions = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _toggleMedicine(String name) {
    setState(() {
      if (_selectedMedicines.contains(name)) {
        _selectedMedicines.remove(name);
      } else {
        _selectedMedicines.add(name);
      }
      // Reset results when selection changes
      _interactions = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Interaction Checker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Text(
              'Select medicines from your saved list to check for potential drug interactions.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your Medicines',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMedicineSelector(),
                  const SizedBox(height: 24),
                  _buildCheckButton(),
                  const SizedBox(height: 24),
                  if (_error != null) _buildErrorBanner(),
                  if (_interactions != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineSelector() {
    if (_isLoadingMedicines) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_savedMedicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.medication_liquid_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No medicines found',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add medicines first to check interactions.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _savedMedicines.map((med) {
        final name = med['name'] as String? ?? 'Unknown';
        final isSelected = _selectedMedicines.contains(name);
        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (bool selected) => _toggleMedicine(name),
        );
      }).toList(),
    );
  }

  Widget _buildCheckButton() {
    return ElevatedButton.icon(
      onPressed: _isChecking || _selectedMedicines.length < 2 ? null : _checkInteraction,
      icon: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.shield_rounded),
      label: Text(
        _isChecking ? 'Analyzing...' : 'Check Interactions',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: _primary.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_interactions == null || _interactions!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.green.shade100, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Safe to Combine',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              'No significant interactions were found. However, always consult with your doctor or pharmacist.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interaction Results (OpenFDA)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 16),
        ..._interactions!.map((item) {
          final riskLevel = item['riskLevel']?.toString() ?? 'UNKNOWN';
          final warnings = (item['warnings'] as List<dynamic>?)?.cast<String>() ?? [];
          
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item['drug1']} + ${item['drug2']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskLevel),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          riskLevel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  
                  if (riskLevel.toUpperCase() == "HIGH") ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Consult your doctor before taking these medicines together.",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Warnings:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("• ${warning.trim()}"),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Text(
                    "Source: ${item['source'] ?? 'OpenFDA'}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade700;
      case 'MEDIUM':
        return Colors.orange.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}
