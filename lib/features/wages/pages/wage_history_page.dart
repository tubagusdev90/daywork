import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/wage_provider.dart';

class WageHistoryPage extends ConsumerWidget {
  final String workerId;
  final String workerName;

  const WageHistoryPage({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workerWageHistoryProvider(workerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Riwayat Upah'),
        backgroundColor: Colors.white,
      ),
      body: history.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Gagal mengambil riwayat: $error'),
        ),
        data: (rates) {
          if (rates.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat upah.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                workerName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Riwayat perubahan tarif upah harian',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              ...rates.map((rate) {
                final isLatest = rates.first.id == rate.id;

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: isLatest
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE8F0FE),
                      child: Icon(
                        isLatest
                            ? Icons.check_circle
                            : Icons.history,
                        color: isLatest ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(
                      formatCurrency(rate.dailyWage),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Text(
                      'Berlaku: ${DateFormat('dd MMMM yyyy', 'id_ID').format(rate.effectiveDate)}\n'
                      '${rate.note ?? 'Tidak ada catatan'}',
                    ),
                    trailing: isLatest
                        ? const Chip(label: Text('Terbaru'))
                        : null,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}