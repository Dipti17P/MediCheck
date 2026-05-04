import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DrugAlternativeScreen extends StatefulWidget {
  const DrugAlternativeScreen({super.key});

  @override
  State<DrugAlternativeScreen> createState() => _DrugAlternativeScreenState();
}

class _DrugAlternativeScreenState extends State<DrugAlternativeScreen> {
  final TextEditingController _drugNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  int _currentPage = 0;

  @override
  void dispose() {
    _drugNameController.dispose();
    _reasonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _findAlternatives() async {
    final drugName = _drugNameController.text.trim();
    if (drugName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _currentPage = 0;
    });

    try {
      final data = await ApiService.findAlternatives(
        drugName,
        reason: _reasonController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _result = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Find Alternatives',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Form
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _drugNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter medicine name (e.g., Paracetamol)',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.medication, color: Color(0xFF2563EB)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: 'Why do you need an alternative? (Optional)',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    prefixIcon: const Icon(Icons.help_outline, color: Color(0xFF2563EB)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _findAlternatives,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2),
                        )
                      : const Text(
                          'Search Alternatives',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),

          // Results Area
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 80, color: Colors.black12),
              SizedBox(height: 16),
              Text(
                'Search for a medicine to see safe alternatives.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    final alternatives = (_result!['alternatives'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (alternatives.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No direct alternatives found. Please consult your doctor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Found ${alternatives.length} alternatives',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: alternatives.length,
            itemBuilder: (context, index) {
              return _buildAlternativeCard(alternatives[index], index);
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            alternatives.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF2563EB) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> alt, int index) {
    // Add scaling effect for current page
    final isCurrentPage = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isCurrentPage ? 0 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isCurrentPage ? 0.1 : 0.05),
            blurRadius: isCurrentPage ? 20 : 10,
            offset: Offset(0, isCurrentPage ? 10 : 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.science, color: Color(0xFF2563EB), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alt['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            alt['drugClass'] ?? 'Unknown Class',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (alt['brandExamples'] != null && (alt['brandExamples'] as List).isNotEmpty) ...[
                const Text(
                  'Common Brands',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (alt['brandExamples'] as List).map((brand) => Chip(
                    label: Text(brand.toString()),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  )).toList(),
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('Why this alternative?'),
              _buildSectionText(alt['advantages'] ?? 'Not specified'),
              const SizedBox(height: 16),
              _buildSectionTitle('Comparison to Original'),
              _buildSectionText(alt['comparisonToOriginal'] ?? 'Not specified'),
              const SizedBox(height: 16),
              _buildSectionTitle('Best For'),
              _buildSectionText(alt['suitableFor'] ?? 'Not specified'),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (alt['requiresPrescription'] == true)
                    _buildBadge(Icons.assignment, 'Prescription Req.', Colors.orange),
                  if (alt['requiresPrescription'] == false)
                    _buildBadge(Icons.shopping_cart, 'Over-the-counter', Colors.green),
                  const SizedBox(width: 8),
                  _buildBadge(Icons.inventory, 'Availability: ${alt['availabilityInIndia']}', Colors.blueGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
