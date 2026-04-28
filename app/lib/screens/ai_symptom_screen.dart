import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AISymptomScreen extends StatefulWidget {
  const AISymptomScreen({super.key});

  @override
  State<AISymptomScreen> createState() => _AISymptomScreenState();
}

class _AISymptomScreenState extends State<AISymptomScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String? _error;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFF0F6FF);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final res = await ApiService.analyzeSymptoms(_controller.text.trim());
      setState(() {
        _result = res['analysis'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('AI Symptom Checker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Describe your symptoms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'The more detail you provide, the better the analysis.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'E.g., I have a sharp pain in my lower back since yesterday...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Analyze with AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              _buildErrorBox(),
            if (_result != null)
              _buildResultBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Text(_error!, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildResultBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: _primary),
              SizedBox(width: 8),
              Text('AI Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Text(_result!, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
