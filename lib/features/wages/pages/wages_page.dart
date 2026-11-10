import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../workers/providers/worker_provider.dart';
import '../models/wage_rate_model.dart';
import '../providers/wage_provider.dart';
import 'wage_form_page.dart';
import 'wage_history_page.dart';

class WagesPage extends ConsumerWidget {
  const WagesPage({super.key});

  String currency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersProvider);
    final ratesAsync = ref.watch(wageRatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WageFormPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tarif'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workersProvider);
            ref.invalidate(wageRatesProvider);
            await ref.read(wageRatesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Data Upah',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Kelola tarif harian dan riwayat upah pekerja.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              workersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Text(
                  'Gagal mengambil pekerja: $error',
                ),
                data: (workers) {
                  return ratesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Text(
                      'Gagal mengambil tarif upah: $error',
                    ),
                    data: (rates) {
                      final today = DateTime.now();
                      final todayDate = DateTime(
                        today.year,
                        today.month,
                        today.day,
                      );

                      final currentRates = <String, WageRate>{};

                      for (final rate in rates) {
                        final effectiveDate = DateTime(
                          rate.effectiveDate.year,
                          rate.effectiveDate.month,
                          rate.effectiveDate.day,
                        );

                        if (effectiveDate.isAfter(todayDate)) continue;

                        final existing = currentRates[rate.workerId];

                        if (existing == null ||
                            rate.effectiveDate.isAfter(
                              existing.effectiveDate,
                            )) {
                          currentRates[rate.workerId] = rate;
                        }
                      }

                      final activeWorkers = workers
                          .where((worker) => worker.isActive)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _summaryCard(
                            activeWorkers.length,
                            currentRates.length,
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Tarif Upah Pekerja',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (activeWorkers.isEmpty)
                            const Text('Belum ada pekerja aktif.'),

                          ...activeWorkers.map((worker) {
                            final rate = currentRates[worker.id];

                            return Card(
                              color: Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFFE8F0FE),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                title: Text(
                                  worker.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    rate == null
                                        ? 'Tarif belum ditentukan'
                                        : '${currency(rate.dailyWage)} / hari\n'
                                            'Efektif: ${DateFormat('dd MMM yyyy', 'id_ID').format(rate.effectiveDate)}',
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Riwayat upah',
                                  icon: const Icon(
                                    Icons.history,
                                    color: Color(0xFF2563EB),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WageHistoryPage(
                                          workerId: worker.id,
                                          workerName: worker.name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(int totalWorkers, int workersWithRates) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Pekerja Aktif',
              totalWorkers.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color: Colors.white24,
          ),
          Expanded(
            child: _summaryItem(
              'Sudah Ada Tarif',
              workersWithRates.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}