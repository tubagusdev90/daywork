
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../workers/pages/workers_page.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';
import '../../attendance/pages/worker_attendance_page.dart';


// ==========================================
// DASHBOARD PAGE
// ==========================================

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  String get _adminEmail {
    return Supabase.instance.client.auth.currentUser?.email ??
        'Administrator';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal keluar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardOverview(),
      const WorkersPage(),
      const WorkerAttendancePage(
        
      ),
      MoreMenuPage(onLogout: _logout),
      
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TukangPay',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _adminEmail,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        elevation: 4,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Pekerja',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// DASHBOARD OVERVIEW
// ==========================================

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  String _currency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
      child: summaryAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 16),
            Center(child: Text('Memuat data dashboard...')),
          ],
        ),
        error: (error, stack) => ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(dashboardSummaryProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
        data: (summary) => _buildDashboard(context, summary),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    DashboardSummary summary,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        // GREETING
        const Text(
          'Selamat Datang 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(DateTime.now()),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 24),

        // WORKER SUMMARY
        _workerSummary(summary),

        const SizedBox(height: 24),

        const Text(
          'Ringkasan Keuangan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 2 : 1;

            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 2.8 : 2.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _financeCard(
                  title: 'Upah Dibayarkan',
                  amount: _currency(summary.paidWages),
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF16A34A),
                  background: const Color(0xFFDCFCE7),
                ),
                _financeCard(
                  title: 'Upah Belum Dibayar',
                  amount: _currency(summary.unpaidWages),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFD97706),
                  background: const Color(0xFFFEF3C7),
                ),
                _financeCard(
                  title: 'Kasbon Belum Lunas',
                  amount: _currency(summary.advanceUnpaid),
                  icon: Icons.handshake_outlined,
                  color: const Color(0xFFDC2626),
                  background: const Color(0xFFFEE2E2),
                ),
                _financeCard(
                  title: 'Kasbon Sudah Dibayar',
                  amount: _currency(summary.advancePaid),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2563EB),
                  background: const Color(0xFFDBEAFE),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        const Text(
          'Aktivitas Pekerja',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _activityCard(
                icon: Icons.groups_outlined,
                title: 'Total Pekerja',
                value: '${summary.totalWorkers}',
                subtitle: 'Pekerja aktif',
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _activityCard(
                icon: Icons.event_available_outlined,
                title: 'Hadir Hari Ini',
                value: '${summary.todayWorkers}',
                subtitle: 'Pekerja hadir',
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // INFO CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data dashboard diperbarui berdasarkan transaksi, '
                  'pembayaran upah, dan aktivitas pekerja di TukangPay.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WORKER SUMMARY
  // ==========================================

  Widget _workerSummary(DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pekerja Aktif',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Total tenaga kerja',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${summary.totalWorkers}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.people_alt_rounded,
            size: 34,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FINANCE CARD
  // ==========================================

  Widget _financeCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIVITY CARD
  // ==========================================

  Widget _activityCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMING SOON PAGE
// ==========================================

class ComingSoonPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Segera Hadir',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MORE MENU PAGE
// ==========================================


class MoreMenuPage extends StatelessWidget {
  final VoidCallback onLogout;

  const MoreMenuPage({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final menus = [
      {
        'title': 'Detail Absensi Per Pekerja',
        'subtitle': 'Lihat kalender kehadiran setiap pekerja',
        'icon': Icons.person_search_rounded,
      },
      {
        'title': 'Data Upah',
        'subtitle': 'Tarif harian dan riwayat kenaikan',
        'icon': Icons.payments_outlined,
      },
      {
        'title': 'Kasbon',
        'subtitle': 'Pinjaman dan cicilan pekerja',
        'icon': Icons.handshake_outlined,
      },
      {
        'title': 'Periode Pembayaran',
        'subtitle': 'Atur periode penggajian',
        'icon': Icons.date_range_outlined,
      },
      {
        'title': 'Penggajian',
        'subtitle': 'Perhitungan dan pembayaran upah',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'Laporan',
        'subtitle': 'Laporan dan slip gaji',
        'icon': Icons.receipt_long_outlined,
      },
      {
        'title': 'Pengaturan',
        'subtitle': 'Pengaturan aplikasi',
        'icon': Icons.settings_outlined,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Menu Lainnya',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Akses fitur pengelolaan TukangPay.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),

        ...menus.map((menu) {
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  menu['icon'] as IconData,
                  color: const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                menu['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                menu['subtitle'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
              ),
              onTap: () {
                final title = menu['title'] as String;

                if (title == 'Detail Absensi Per Pekerja') {
                  context.push('/attendance/worker');
                  return;
                }

                if (title == 'Data Upah') {
                  context.push('/wages');
                  return;
                }

                if (title == 'Periode Pembayaran') {
                  context.push('/payment-periods');
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$title akan dikembangkan pada tahap berikutnya.',
                    ),
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 12),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            label: const Text(
              'Keluar dari Aplikasi',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFFECACA),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
