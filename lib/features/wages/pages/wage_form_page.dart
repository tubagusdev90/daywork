import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../workers/models/worker_model.dart';
import '../../workers/providers/worker_provider.dart';
import '../models/wage_rate_model.dart';
import '../providers/wage_provider.dart';

class WageFormPage extends ConsumerStatefulWidget {
  const WageFormPage({super.key});

  @override
  ConsumerState<WageFormPage> createState() => _WageFormPageState();
}

class _WageFormPageState extends ConsumerState<WageFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _wageController = TextEditingController();
  final _noteController = TextEditingController();

  String? _workerId;
  DateTime _effectiveDate = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _wageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _effectiveDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pekerja terlebih dahulu')),
      );
      return;
    }

    final amount = double.tryParse(
      _wageController.text.replaceAll('.', '').replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal upah tidak valid')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final wage = WageRate(
        id: '',
        workerId: _workerId!,
        workerName: '',
        dailyWage: amount,
        effectiveDate: _effectiveDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await ref.read(wageServiceProvider).addWageRate(wage);

      ref.invalidate(wageRatesProvider);
      ref.invalidate(workerWageHistoryProvider(_workerId!));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif upah berhasil disimpan')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tarif: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Tambah Tarif Upah'),
        backgroundColor: Colors.white,
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Gagal mengambil data pekerja: $error'),
        ),
        data: (workers) {
          final activeWorkers = workers
              .where((worker) => worker.isActive)
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Pilih Pekerja',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _workerId,
                  isExpanded: true,
                  decoration: _decoration('Pilih pekerja'),
                  items: activeWorkers.map((Worker worker) {
                    return DropdownMenuItem(
                      value: worker.id,
                      child: Text(
                        worker.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _workerId = value);
                  },
                  validator: (value) =>
                      value == null ? 'Pekerja wajib dipilih' : null,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Upah Harian (Rp)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _wageController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Contoh: 150000'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nominal upah wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Tanggal Efektif',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: _decoration('Tanggal efektif'),
                    child: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID')
                          .format(_effectiveDate),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Catatan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: _decoration(
                    'Contoh: Kenaikan upah berdasarkan kesepakatan',
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Simpan Tarif Upah'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}