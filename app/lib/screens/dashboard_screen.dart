import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Color palette ──────────────────────────────────────────────────────────
  static const Color _primary    = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _bg         = Color(0xFFF0F6FF);

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Feature card data ──────────────────────────────────────────────────────
  List<_FeatureCard> get _cards => [
    _FeatureCard(
      icon: Icons.add_circle_outline_rounded,
      label: 'Add Medicine',
      subtitle: 'Register a new medicine',
      gradient: const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => Navigator.pushNamed(context, '/add-medicine'),
    ),
    _FeatureCard(
      icon: Icons.medication_rounded,
      label: 'View Medicines',
      subtitle: 'Browse your medicine list',
      gradient: const LinearGradient(
        colors: [Color(0xFF00897B), Color(0xFF26A69A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => Navigator.pushNamed(context, '/view-medicines'),
    ),
    _FeatureCard(
      icon: Icons.warning_amber_rounded,
      label: 'Check Interaction',
      subtitle: 'Detect drug conflicts',
      gradient: const LinearGradient(
        colors: [Color(0xFFE65100), Color(0xFFFF7043)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => Navigator.pushNamed(context, '/check-interaction'),
    ),
    _FeatureCard(
      icon: Icons.alarm_rounded,
      label: 'Medicine Reminder',
      subtitle: 'Never miss a dose',
      gradient: const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => Navigator.pushNamed(context, '/reminder'),
    ),
  ];

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeBanner(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 14),
                    _buildCardGrid(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Recent Activity'),
                    const SizedBox(height: 14),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MediCheck AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  // ── Welcome banner ─────────────────────────────────────────────────────────
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
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
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
                        fontSize: 13,
                        color: Colors.white.withAlpha(210),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Stay safe with\nMediCheck AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🛡️  Your health, protected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
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

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D1B2A),
        letterSpacing: 0.2,
      ),
    );
  }

  // ── 2x2 card grid ─────────────────────────────────────────────────────────
  Widget _buildCardGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        // Staggered entrance animation
        final delay = index * 0.12;
        final animation = CurvedAnimation(
          parent: _animController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: _buildFeatureCard(_cards[index]),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(_FeatureCard card) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: card.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  card.subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent activity placeholder ────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final items = [
      _ActivityItem(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF00897B),
        title: 'Interaction check passed',
        subtitle: 'Paracetamol + Ibuprofen',
        time: '2h ago',
      ),
      _ActivityItem(
        icon: Icons.add_circle_outline_rounded,
        iconColor: const Color(0xFF1E88E5),
        title: 'Medicine added',
        subtitle: 'Amoxicillin 500mg',
        time: 'Yesterday',
      ),
      _ActivityItem(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFE65100),
        title: 'Interaction warning',
        subtitle: 'Warfarin + Aspirin',
        time: '2 days ago',
      ),
    ];

    return Column(
      children: items.map((item) => _buildActivityTile(item)).toList(),
    );
  }

  Widget _buildActivityTile(_ActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8794),
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(fontSize: 11, color: Color(0xFFBCC4CC)),
          ),
        ],
      ),
    );
  }
}

// ── Helper data classes ────────────────────────────────────────────────────
class _FeatureCard {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

class _ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
