import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_state.dart';
import 'package:cms/features/approvals/presentation/pages/approvals_page.dart';
import 'home_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const PulsePage(),
      const AlertsPage(),
      const ApprovalsPage(),
      const DailyTaskPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BlocBuilder<ApprovalsBloc, ApprovalsState>(
        builder: (context, approvalsState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    _buildNavItem(
                      1,
                      Icons.show_chart_outlined,
                      Icons.show_chart,
                      'Pulse',
                    ),
                    _buildNavItem(
                      2,
                      Icons.warning_amber_rounded,
                      Icons.warning_rounded,
                      'Alerts',
                      badgeCount: 2,
                    ),
                    _buildNavItem(
                      3,
                      Icons.verified_outlined,
                      Icons.verified,
                      'Approvals',
                      badgeCount: approvalsState.pendingCount,
                    ),
                    _buildNavItem(
                      4,
                      Icons.assignment_outlined,
                      Icons.assignment,
                      'Tasks',
                      badgeCount: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final themeColor = const Color(0xFF319F77); // High-fidelity deep teal

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? solidIcon : outlineIcon,
                color: isSelected ? themeColor : Colors.grey.shade500,
                size: 24,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? themeColor : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// Pulse Page (Daily Site Pulse dashboard)
/// ==========================================
class PulsePage extends StatefulWidget {
  const PulsePage({super.key});

  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> {
  int _activeTab = 0; // 0: Site Pulse, 1: PTW, 2: Tasks (3)

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF319F77);

    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'NTPC Vindhyachal FGD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 10, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text(
                  'Vindhya Nagar, MP',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const Drawer(),
      body: Column(
        children: [
          // Inline Tab Selection Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabButton(0, 'Site Pulse')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton(1, 'PTW')),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton(2, 'Tasks (3)')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _activeTab == 0
                  ? _buildSitePulseTab()
                  : _activeTab == 1
                  ? _buildPtwTab()
                  : _buildTasksTab(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pulse_fab',
        onPressed: () {},
        backgroundColor: activeColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTab == index;
    const activeColor = Color(0xFF319F77);

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFCDE0D5),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSitePulseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today target achieved card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F2E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCDE0D5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TODAY — 22 JUL 2026',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '34°C ⇌ Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '63%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Day 89 / 120',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF319F77),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Daily target achieved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.63,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF319F77)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPulseMiniBox('49', 'On site'),
                  _buildPulseMiniBox('3', 'Blockers'),
                  _buildPulseMiniBox('4', 'PTWs active'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Today's activities
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's activities",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              "Target vs done",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildActivityRow(
          'FGD Absorber erection',
          0.50,
          '2 panels done of 4 panels target',
        ),
        _buildActivityRow(
          'Sump civil works',
          0.61,
          '11 m³ done of 18 m³ target',
        ),
        _buildActivityRow(
          'Piping — FD fan circuit',
          0.63,
          '38 mtrs done of 60 mtrs target',
        ),

        const SizedBox(height: 20),
        // Manpower today
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Manpower today",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              "49 / 58 planned",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildManpowerCard(
              'Structural fitters',
              '14',
              'of 18 planned',
              14 / 18,
              Colors.orange,
            ),
            _buildManpowerCard(
              'Welders',
              '12',
              'of 12 planned',
              12 / 12,
              const Color(0xFF319F77),
            ),
            _buildManpowerCard(
              'Civil workers',
              '19',
              'of 24 planned',
              19 / 24,
              Colors.orange,
            ),
            _buildManpowerCard(
              'Supervisors',
              '4',
              'of 4 planned',
              4 / 4,
              const Color(0xFF319F77),
            ),
          ],
        ),

        const SizedBox(height: 24),
        // Open blockers
        Row(
          children: [
            const Text(
              "Open blockers",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildBlockerCard(
          'Material',
          'ERW Pipe 4" (120 Nos)',
          'FGD Absorber piping blocked',
          Colors.red,
        ),
        _buildBlockerCard(
          'Equipment',
          'Liebherr LTM 1200',
          'Absorber shell lifting halted',
          Colors.red,
        ),
        _buildBlockerCard(
          'Drawing',
          'IFC Rev C — Sump detail',
          'Sump shuttering cannot start',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPulseMiniBox(String value, String label) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String name, double val, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(val * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildManpowerCard(
    String title,
    String count,
    String sub,
    double val,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val,
              minHeight: 4,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockerCard(String tag, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPtwTab() {
    return Column(
      children: [
        _buildPtwCard(
          'PTW-00219',
          'Confined Space Entry',
          'Active',
          'Valid till: 22 Jul 2026 18:00',
          'NTPC Vindhyachal',
        ),
        _buildPtwCard(
          'PTW-00220',
          'Hot Work Permit',
          'Active',
          'Valid till: 22 Jul 2026 20:00',
          'Balrampur Chini',
        ),
        _buildPtwCard(
          'PTW-00221',
          'Height Work Permit',
          'Pending Approval',
          'Submitted: 22 Jul 2026 14:15',
          'NTPC Vindhyachal',
        ),
      ],
    );
  }

  Widget _buildPtwCard(
    String id,
    String type,
    String status,
    String time,
    String site,
  ) {
    final isActive = status == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF319F77),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE1F2E9)
                      : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF319F77)
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            type,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            site,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const Divider(height: 20),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return const DailyTaskView();
  }
}

/// ==========================================
/// Alerts Page (Portfolio Snapshot Alerts)
/// ==========================================
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF319F77),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Column(
          children: [
            Text(
              'Portfolio Snapshot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Wed 22 Jul 2026 • 08:14',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Subheader line
          Container(
            color: const Color(0xFF319F77),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.close, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'All alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAlertCard(
                  project: 'Balrampur Chini',
                  time: '3d ago',
                  content:
                      'CPI 0.86 — cost overrun confirmed. 12 open NCRs. Immediate intervention required.',
                  owner: 'Owner: M. Tripathi',
                  actionText: 'Call PM',
                  btnColor: Colors.red.shade600,
                  leftColor: Colors.red,
                ),
                _buildAlertCard(
                  project: 'NTPC Vindhyachal',
                  time: '1d ago',
                  content:
                      'Schedule slippage 16%. FGD absorber erection 18 days behind critical path.',
                  owner: 'Owner: S. Patil',
                  actionText: 'Call PM',
                  btnColor: Colors.red.shade600,
                  leftColor: Colors.red,
                ),
                _buildAlertCard(
                  project: 'IFFCO Phulpur',
                  time: '2d ago',
                  content:
                      '3 critical path materials unordered. Ammonia compressor: 14-week lead time.',
                  owner: 'Owner: Procurement',
                  actionText: 'Review PO',
                  btnColor: Colors.orange.shade700,
                  leftColor: Colors.orange,
                ),
                _buildAlertCard(
                  project: 'NTPC Vindhyachal',
                  time: '5d ago',
                  content:
                      'RA Bill ₹8.4 Cr pending certification 34 days. Client escalation needed.',
                  owner: 'Owner: S. Patil',
                  actionText: 'Escalate',
                  btnColor: Colors.orange.shade700,
                  leftColor: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String project,
    required String time,
    required String content,
    required String owner,
    required String actionText,
    required Color btnColor,
    required Color leftColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: leftColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        project,
                        style: TextStyle(
                          color: leftColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        owner,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// Daily Task Page (Checklist Tasks view)
/// ==========================================
class DailyTaskPage extends StatelessWidget {
  const DailyTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {},
          ),
        ),
        title: const Text(
          'Daily Tasks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: DailyTaskView(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'daily_task_fab',
        onPressed: () {},
        backgroundColor: const Color(0xFF319F77),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class DailyTaskView extends StatefulWidget {
  const DailyTaskView({super.key});

  @override
  State<DailyTaskView> createState() => _DailyTaskViewState();
}

class _DailyTaskViewState extends State<DailyTaskView> {
  final List<Map<String, dynamic>> _tasksList = [
    {
      'id': 'NCR-031',
      'title': 'Close SS weld NCR — DM plant area',
      'tag': 'NCR',
      'urgency': 'URGENT',
      'time': 'Today',
      'done': false,
    },
    {
      'id': 'DPR-22Jul',
      'title': 'Complete daily progress report',
      'tag': 'Diary',
      'urgency': 'URGENT',
      'time': 'By 18:00',
      'done': false,
    },
    {
      'id': 'OBS-018',
      'title': 'Safety observation — scaffolding tie-off',
      'tag': 'Observation',
      'urgency': '',
      'time': 'Today',
      'done': true,
    },
    {
      'id': 'ITP-P14',
      'title': 'Witness hydro test — flange joints',
      'tag': 'ITP',
      'urgency': '',
      'time': 'Tomorrow',
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    int dueToday = _tasksList
        .where((t) => t['time'] == 'Today' && !t['done'])
        .length;
    int pending = _tasksList.where((t) => !t['done']).length;
    int done = _tasksList.where((t) => t['done']).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top mini status indicator boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusBox('$dueToday', 'Due today', Colors.red.shade600),
            _buildStatusBox('$pending', 'Pending', Colors.orange.shade700),
            _buildStatusBox('$done', 'Done', const Color(0xFF319F77)),
          ],
        ),
        const SizedBox(height: 20),

        // Tasks Checklist
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tasksList.length,
          itemBuilder: (context, idx) {
            final task = _tasksList[idx];
            final isDone = task['done'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCDE0D5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: const Color(0xFF319F77),
                    onChanged: (val) {
                      setState(() {
                        task['done'] = val;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (task['tag'].toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF9F3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task['tag'].toString(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF319F77),
                                  ),
                                ),
                              ),
                            if (task['urgency'].toString().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                task['urgency'].toString(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              task['time'].toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task['title'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDone ? Colors.grey : Colors.black87,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task['id'].toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBox(String count, String label, Color color) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
