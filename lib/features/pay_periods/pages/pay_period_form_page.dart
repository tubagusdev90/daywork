import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pay_period_provider.dart';

class PayPeriodFormPage extends ConsumerStatefulWidget {
  const PayPeriodFormPage({super.key});

  @override
  ConsumerState<PayPeriodFormPage> createState() => _PayPeriodFormPageState();
}

class _PayPeriodFormPageState extends ConsumerState<PayPeriodFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _paymentDate;
  bool _loading = false;

  String _format(DateTime date) => DateFormat('dd MMMM yyyy', 'id_ID').format(date);

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _paymentDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Pilih tanggal mulai periode' : 'Pilih tanggal pembayaran',
    );
    if (selected != null) {
      setState(() {
        if (isStart) {
          _startDate = selected;
        } else {
          _paymentDate = selected;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _paymentDate == null) {
      _message('Pilih tanggal mulai dan tanggal pembayaran.');
      return;
    }
    if (_paymentDate!.isBefore(_startDate!)) {
      _message('Tanggal pembayaran harus sama dengan atau setelah tanggal mulai.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(payPeriodServiceProvider).createPeriod(
            name: _nameController.text,
            startDate: _startDate!,
            paymentDate: _paymentDate!,
          );
      ref.invalidate(payPeriodsProvider);
      ref.invalidate(latestPayPeriodProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(latestPayPeriodProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Tambah Periode Pembayaran')),
      body: latestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Gagal memuat periode terakhir: $error'),
        )),
        data: (latest) {
          final suggestedStart = latest == null
              ? null
              : DateTime(latest.paymentDate.year, latest.paymentDate.month, latest.paymentDate.day)
                  .add(const Duration(days: 1));
          if (_startDate == null && suggestedStart != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _startDate == null) setState(() => _startDate = suggestedStart);
            });
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    latest == null
                        ? 'Ini adalah periode pertama. Admin bebas menentukan tanggal mulai periode.'
                        : 'Periode sebelumnya dibayar pada ${_format(latest.paymentDate)}. Periode baru otomatis dimulai ${_format(suggestedStart!)}.',
                    style: const TextStyle(color: Color(0xFF1E40AF), height: 1.5, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Nama Periode', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Contoh: Periode 1 November 2026', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 18),
                const Text('Tanggal Mulai', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: latest == null ? () => _pickDate(isStart: true) : null,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Align(alignment: Alignment.centerLeft, child: Text(_startDate == null ? 'Pilih tanggal mulai' : _format(_startDate!))),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
                ),
                const SizedBox(height: 18),
                const Text('Tanggal Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Align(alignment: Alignment.centerLeft, child: Text(_paymentDate == null ? 'Pilih tanggal pembayaran' : _format(_paymentDate!))),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
                ),
                const SizedBox(height: 10),
                const Text('Tanggal akhir periode otomatis mengikuti tanggal pembayaran.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                    label: Text(_loading ? 'Menyimpan...' : 'Simpan Periode'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
