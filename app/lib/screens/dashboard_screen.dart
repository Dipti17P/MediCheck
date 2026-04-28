import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/report_service.dart';
import '../services/cache_service.dart';
import 'view_medicine_screen.dart';
import 'reminder_screen.dart';
import 'interaction_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _DashboardHome(),
      const ViewMedicineScreen(),
      const InteractionScreen(),
      const ReminderScreen(),
      const ProfileScreen(),
    ];
    _initFcm();
  }

  Future<void> _initFcm() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      // Request permission for iOS
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await ApiService.saveFcmToken(token);
        debugPrint("FCM Token saved: $token");
      }
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_rounded),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Interactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> with SingleTickerProviderStateMixin {
  // Color palette
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF0F6FF);

  late AnimationController _animController;

  // Data summaries
  int _medicineCount = 0;
  int _reminderCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fetchSummaryData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummaryData() async {
    setState(() => _isLoading = true);
    try {
      final meds = await ApiService.getMedicines();
      final rems = await ApiService.getReminders();
      if (mounted) {
        setState(() {
          _medicineCount = meds.length;
          _reminderCount = rems.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    if (!kIsWeb) {
      await FirebaseAnalytics.instance.logEvent(name: 'user_logout');
    }
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSummaryData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeBanner(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Overview'),
                      const SizedBox(height: 12),
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildAdherenceStreak(),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Quick Actions'),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/add-medicine').then((_) => _fetchSummaryData()),
                            child: const Text('+ Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActions(),
                      const SizedBox(height: 12),
                      _buildAIRow(),
                      const SizedBox(height: 28),
                      _buildSectionTitle('Upcoming Reminders'),
                      const SizedBox(height: 14),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: _primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MediCheck AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primary,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              if (!kIsWeb) {
                await FirebaseAnalytics.instance.logEvent(name: 'export_pdf_report');
              }
              final meds = await ApiService.getMedicines();
              await ReportService.generateAndPrintMedicineReport(meds);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, color: _primary),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: _primary),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _animController,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back! 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your Health\nDashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Medicines',
            count: _medicineCount.toString(),
            icon: Icons.medication,
            color: const Color(0xFF00897B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Reminders Set',
            count: _reminderCount.toString(),
            icon: Icons.alarm,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceStreak() {
    // Mock streak for now
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withAlpha(50), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adherence Streak', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('5 Days', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7B8794),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0D1B2A),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            icon: Icons.add_circle_outline,
            label: 'Add Medicine',
            onTap: () => Navigator.pushNamed(context, '/add-medicine').then((_) => _fetchSummaryData()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.warning_amber_rounded,
            label: 'Check Conflicts',
            onTap: () => Navigator.pushNamed(context, '/check-interaction'),
          ),
        ),
      ],
    );
  }

  Widget _buildAIRow() {
    return _buildActionBtn(
      icon: Icons.auto_awesome,
      label: 'AI Symptom Checker',
      onTap: () => Navigator.pushNamed(context, '/symptom-checker'),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E88E5)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on track',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check your Reminders tab to see your schedule for today.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7B8794),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
