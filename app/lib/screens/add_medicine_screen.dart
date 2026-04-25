import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usesController = TextEditingController();
  final _sideEffectsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF0F6FF);

  // ── Mock Database for Smart Auto-Fill ──────────────────────────────────────
  static const Map<String, Map<String, String>> _medicineDb = {
    'Paracetamol 500mg': {
      'uses': 'Relieves mild to moderate pain and fever.',
      'sideEffects': 'Rarely allergic reactions, liver damage in high doses.',
    },
    'Ibuprofen 400mg': {
      'uses': 'Reduces inflammation, pain, and fever.',
      'sideEffects': 'Stomach upset, heartburn, increased risk of bleeding.',
    },
    'Amoxicillin 500mg': {
      'uses': 'Treats bacterial infections.',
      'sideEffects': 'Nausea, vomiting, diarrhea, rash.',
    },
    'Aspirin 81mg': {
      'uses': 'Pain relief, fever reduction, blood thinner.',
      'sideEffects': 'Stomach pain, heartburn, easily bleeding.',
    },
    'Lisinopril 10mg': {
      'uses': 'Treats high blood pressure and heart failure.',
      'sideEffects': 'Dry cough, dizziness, headache.',
    },
    'Metformin 500mg': {
      'uses': 'Controls high blood sugar in type 2 diabetes.',
      'sideEffects': 'Nausea, stomach pain, diarrhea.',
    },
    'Omeprazole 20mg': {
      'uses': 'Treats GERD and stomach ulcers.',
      'sideEffects': 'Headache, stomach pain, nausea.',
    },
    'Atorvastatin 20mg': {
      'uses': 'Lowers high cholesterol and triglyceride levels.',
      'sideEffects': 'Muscle pain, liver problems, diarrhea.',
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _usesController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  void _onMedicineSelected(String name) {
    _nameController.text = name;
    final data = _medicineDb[name];
    if (data != null) {
      setState(() {
        _usesController.text = data['uses']!;
        _sideEffectsController.text = data['sideEffects']!;
        _successMessage = 'Medicine details auto-filled!';
        _errorMessage = null;
      });
      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _handleAddMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ApiService.addMedicine(
        name: _nameController.text.trim(),
        uses: _usesController.text.trim(),
        sideEffects: _sideEffectsController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _successMessage = 'Medicine added successfully!';
      });
      _formKey.currentState!.reset();
      _nameController.clear();
      _usesController.clear();
      _sideEffectsController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Medicine',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Smart auto-fill available',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ───────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primary.withAlpha(22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryLight.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: _primaryLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      Text(
                        'Search to auto-fill or enter manually',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF7B8794)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Medicine Autocomplete
              _buildAutocompleteField(),
              const SizedBox(height: 20),

              // Uses (multi-line)
              _buildField(
                controller: _usesController,
                label: 'Uses',
                hint: 'e.g. Used to relieve fever, headache...',
                icon: Icons.healing_outlined,
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please describe the uses';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Side Effects (multi-line)
              _buildField(
                controller: _sideEffectsController,
                label: 'Side Effects',
                hint: 'e.g. Nausea, dizziness...',
                icon: Icons.warning_amber_outlined,
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please list known side effects';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Feedback messages
              if (_errorMessage != null) ...[
                _buildBanner(
                  message: _errorMessage!,
                  bgColor: const Color(0xFFFDECEC),
                  borderColor: const Color(0xFFE53935),
                  iconColor: const Color(0xFFE53935),
                  textColor: const Color(0xFFC62828),
                  icon: Icons.error_outline,
                ),
                const SizedBox(height: 16),
              ],
              if (_successMessage != null) ...[
                _buildBanner(
                  message: _successMessage!,
                  bgColor: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFF43A047),
                  iconColor: const Color(0xFF2E7D32),
                  textColor: const Color(0xFF2E7D32),
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Autocomplete Field ──────────────────────────────────────────────────────
  Widget _buildAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicine Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D4F5C),
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _medicineDb.keys.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _onMedicineSelected(selection);
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            
            // Sync controllers
            fieldTextEditingController.addListener(() {
              _nameController.text = fieldTextEditingController.text;
            });
            // Update autocomplete when name is set from code
            _nameController.addListener(() {
              if (fieldTextEditingController.text != _nameController.text) {
                fieldTextEditingController.text = _nameController.text;
              }
            });

            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              },
              style: const TextStyle(fontSize: 15, color: Color(0xFF0D1B2A)),
              decoration: InputDecoration(
                hintText: 'Start typing to search...',
                hintStyle:
                    const TextStyle(color: Color(0xFFBCC4CC), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _primaryLight, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F8FC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primaryLight, width: 1.8),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 96,
                  height: 200,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.medication, color: _primaryLight),
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Reusable text field ─────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D4F5C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0D1B2A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFBCC4CC), fontSize: 13),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: _primaryLight, size: 20)
                : Padding(
                    padding: const EdgeInsets.only(left: 12, top: 12),
                    child: Icon(icon, color: _primaryLight, size: 20),
                  ),
            prefixIconConstraints: maxLines > 1
                ? const BoxConstraints(minWidth: 48, minHeight: 48)
                : null,
            alignLabelWithHint: maxLines > 1,
            filled: true,
            fillColor: const Color(0xFFF5F8FC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _primaryLight, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit button ───────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleAddMedicine,
        icon: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: Text(
          _isLoading ? 'Saving...' : 'Save Medicine',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withAlpha(120),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Generic banner ──────────────────────────────────────────────────────────
  Widget _buildBanner({
    required String message,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
