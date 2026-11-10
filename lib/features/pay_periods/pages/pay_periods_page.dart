import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/pay_period_model.dart';
import '../providers/pay_period_provider.dart';
import 'pay_period_form_page.dart';

class PayPeriodsPage extends ConsumerWidget {
  const PayPeriodsPage({super.key});

  String _date(DateTime value) => DateFormat('dd MMM yyyy', 'id_ID').format(value);

  String _periodStatus(PayPeriodModel period) {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final start = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
    final end = DateTime(period.endDate.year, period.endDate.month, period.endDate.day);
    if (date.isBefore(start)) return 'Akan datang';
    if (date.isAfter(end)) return 'Selesai';
    return 'Berjalan';
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PayPeriodFormPage()));
    if (result == true) {
      ref.invalidate(payPeriodsProvider);
      ref.invalidate(latestPayPeriodProvider);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PayPeriodModel period) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus periode?'),
        content: Text('Periode ${period.displayName} akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(payPeriodServiceProvider).deletePeriod(period.id);
      ref.invalidate(payPeriodsProvider);
      ref.invalidate(latestPayPeriodProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(payPeriodsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Periode Pembayaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Periode'),
      ),
      body: periodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text('Gagal memuat periode pembayaran\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => ref.invalidate(payPeriodsProvider), icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
          ]),
        )),
        data: (periods) {
          if (periods.isEmpty) {
            return ListView(padding: const EdgeInsets.all(24), children: const [
              SizedBox(height: 100),
              Icon(Icons.date_range_outlined, size: 60, color: Color(0xFF94A3B8)),
              SizedBox(height: 16),
              Text('Belum ada periode pembayaran', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              SizedBox(height: 8),
              Text('Buat periode pertama dengan menentukan tanggal mulai dan tanggal pembayaran.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
            ]);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(payPeriodsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text('${periods.length} periode terdaftar', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 12),
                ...periods.map((period) {
                  final status = _periodStatus(period);
                  final color = status == 'Berjalan' ? const Color(0xFF16A34A) : status == 'Akan datang' ? const Color(0xFFD97706) : const Color(0xFF64748B);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(period.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          PopupMenuButton<String>(
                            onSelected: (value) { if (value == 'delete') _delete(context, ref, period); },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Hapus periode'))],
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [const Icon(Icons.date_range_outlined, size: 17, color: Color(0xFF64748B)), const SizedBox(width: 8), Expanded(child: Text('${_date(period.startDate)} – ${_date(period.endDate)}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))))]),
                        const SizedBox(height: 7),
                        Row(children: [const Icon(Icons.payments_outlined, size: 17, color: Color(0xFF64748B)), const SizedBox(width: 8), Text('Pembayaran: ${_date(period.paymentDate)}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))]),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                        )),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
