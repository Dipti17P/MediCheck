import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary      = Color(0xFF2563EB);
  static const Color _primaryDark  = Color(0xFF1E40AF);
  static const Color _primaryLight = Color(0xFF60A5FA);
  static const Color _bg           = Color(0xFFF8FAFC);
  static const Color _surface      = Colors.white;
  static const Color _textPrimary  = Color(0xFF0F172A);
  static const Color _textSecondary= Color(0xFF64748B);

  bool _isLoadingMedicines = true;
  List<dynamic> _savedMedicines = [];
  final List<String> _selectedMedicines = [];

  bool _isChecking = false;
  Map<String, dynamic>? _interactionResult;
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
        _interactionResult = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
      _interactionResult = null;
    });

    try {
      final response = await ApiService.checkInteractions(_selectedMedicines);
      if (mounted) {
        setState(() {
          _interactionResult = response;
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
      _interactionResult = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Safety Check',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
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
            child: const Text(
              'Select medicines from your saved list to check for potential drug interactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
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
                      if (_interactionResult != null) _buildResultCard(),
                    ],
                  ),
                ),
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
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_savedMedicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primary.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_liquid_rounded, size: 40, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No medicines found',
              style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add medicines first to check interactions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: _savedMedicines.map((med) {
        final name = med['name'] as String? ?? 'Unknown';
        final isSelected = _selectedMedicines.contains(name);
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (bool selected) => _toggleMedicine(name),
          selectedColor: _primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : _textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? _primary : const Color(0xFFF1F5F9), width: 1.5),
          ),
          showCheckmark: false,
          elevation: isSelected ? 4 : 0,
          shadowColor: _primary.withAlpha(50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildCheckButton() {
    final bool canCheck = !_isChecking && _selectedMedicines.length >= 2;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: canCheck ? [
          BoxShadow(
            color: _primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ] : null,
      ),
      child: ElevatedButton.icon(
        onPressed: canCheck ? _checkInteraction : null,
        icon: _isChecking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.shield_rounded, size: 24),
        label: Text(
          _isChecking ? 'Analyzing Potential Risks...' : 'Run Safety Analysis',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
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
    if (_interactionResult == null) return const SizedBox.shrink();

    final overallRisk = _interactionResult!['overallRisk'] as String? ?? 'low';
    final interactions = (_interactionResult!['interactions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    // ── Unknown / AI failure state ──────────────────────────────────────────
    if (interactions.isNotEmpty &&
        interactions.every((i) => i['riskLevel'] == 'unknown')) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade100, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  color: Colors.blueGrey.shade400, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis Unavailable',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI could not complete the analysis right now. Please try again in a moment, or consult your pharmacist directly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _checkInteraction,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Analysis'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    // ── Safe to combine state ────────────────────────────────────────────────
    if (interactions.isEmpty || overallRisk == 'low') {
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interaction Results (Gemini AI)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B2A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRiskColor(overallRisk),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Overall: ${overallRisk.toUpperCase()}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...interactions.map((item) {
          final riskLevel = item['riskLevel']?.toString() ?? 'unknown';
          final coReportCount = item['coReportCount'] as int? ?? 0;

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
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item['drug1']} + ${item['drug2']}",
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskLevel),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          riskLevel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Warning box ─────────────────────────────────────────
                  if (item['warning'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getRiskColor(riskLevel).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getRiskColor(riskLevel).withAlpha(80),
                        ),
                      ),
                      child: Text(
                        item['warning'].toString(),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ── Detail rows ─────────────────────────────────────────
                  if (item['mechanism'] != null)
                    _buildInfoRow('Mechanism', item['mechanism'].toString()),

                  if (item['clinicalEffect'] != null)
                    _buildInfoRow('Clinical Effect', item['clinicalEffect'].toString()),

                  if (item['management'] != null)
                    _buildInfoRow('What To Do', item['management'].toString()),

                  if (item['alternatives'] != null &&
                      item['alternatives'].toString() != 'null')
                    _buildInfoRow('Safer Alternatives', item['alternatives'].toString()),

                  const SizedBox(height: 10),

                  // ── Doctor consult badge ────────────────────────────────
                  if (item['requiresDoctorConsult'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_hospital_rounded, color: Colors.red, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Doctor consultation required',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  Text(
                    "Source: ${item['source'] ?? 'Gemini AI + OpenFDA'}"
                    " • Co-reports: $coReportCount",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade700;
      case 'MODERATE':
        return Colors.orange.shade700;
      case 'LOW-MODERATE':
        return Colors.amber.shade600;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}
