
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../services/attendance_service.dart';

class WorkerAttendancePage extends ConsumerStatefulWidget {
  const WorkerAttendancePage({super.key});

  @override
  ConsumerState<WorkerAttendancePage> createState() =>
      _WorkerAttendancePageState();
}

class _WorkerAttendancePageState
    extends ConsumerState<WorkerAttendancePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String? _selectedWorkerId;

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  String _positionLabel(String position) {
    switch (position) {
      case 'kepala_petukang':
        return 'Kepala Petukang';
      case 'petukang':
        return 'Petukang';
      case 'kenek':
        return 'Kenek';
      default:
        return position;
    }
  }

  void _refresh() {
    final month = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    );

    ref.invalidate(attendanceMonthProvider(month));
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync =
        ref.watch(activeWorkersForAttendanceProvider);

    final month = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    );

    final attendanceAsync =
        ref.watch(attendanceMonthProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Absensi Pekerja',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),

      body: workersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Gagal memuat pekerja: $error'),
        ),
        data: (workers) {
          if (workers.isEmpty) {
            return const Center(
              child: Text('Belum ada pekerja aktif.'),
            );
          }

          // Pilih pekerja pertama secara otomatis.
          _selectedWorkerId ??= workers.first['id'].toString();

          final selectedWorker = workers.firstWhere(
            (worker) =>
                worker['id'].toString() == _selectedWorkerId,
            orElse: () => workers.first,
          );

          return attendanceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gagal memuat absensi:\n$error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) => _buildContent(
              workers: workers,
              selectedWorker: selectedWorker,
              data: data,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent({
    required List<Map<String, dynamic>> workers,
    required Map<String, dynamic> selectedWorker,
    required AttendanceMonthData data,
  }) {
    final workerId = selectedWorker['id'].toString();

    final workerAttendances = data.attendances
        .where((item) => item.workerId == workerId)
        .toList();

    final selectedAttendance = workerAttendances.where(
      (item) => _sameDate(
        item.attendanceDate,
        _selectedDay,
      ),
    );

    final attendance = selectedAttendance.isEmpty
        ? null
        : selectedAttendance.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // WORKER SELECTOR
        _buildWorkerSelector(
          workers,
          selectedWorker,
        ),

        const SizedBox(height: 16),

        // SUMMARY
        _buildSummary(workerAttendances),

        const SizedBox(height: 18),

        // CALENDAR
        _buildCalendar(
          data,
          workerAttendances,
        ),

        const SizedBox(height: 14),

        _buildLegend(),

        const SizedBox(height: 24),

        // SELECTED DATE DETAIL
        _buildSelectedDateDetail(attendance),
      ],
    );
  }

  // ============================================================
  // WORKER SELECTOR
  // ============================================================

  Widget _buildWorkerSelector(
    List<Map<String, dynamic>> workers,
    Map<String, dynamic> selectedWorker,
  ) {
    final position =
        selectedWorker['position']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor
              .withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Pekerja',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedWorkerId,
              isExpanded: true,

              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),

              items: workers.map((worker) {
                return DropdownMenuItem<String>(
                  value: worker['id'].toString(),
                  child: Text(
                    worker['name'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedWorkerId = value;
                });
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.engineering_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedWorker['name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _positionLabel(position),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    List<AttendanceModel> attendances,
  ) {
    final work = attendances.where(
      (item) => item.status == 'work',
    ).length;

    final absent = attendances.where(
      (item) => item.status == 'absent',
    ).length;

    final paid = attendances.where(
      (item) =>
          item.status == 'work' && item.isPaid,
    ).length;

    final unpaid = attendances.where(
      (item) =>
          item.status == 'work' && !item.isPaid,
    ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Bulan Ini',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Hadir',
                work,
                Colors.blue,
                Icons.person_pin_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryCard(
                'Tidak Hadir',
                absent,
                Colors.red,
                Icons.person_off_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Sudah Dibayar',
                paid,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryCard(
                'Belum Dibayar',
                unpaid,
                Colors.orange,
                Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    int value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _buildCalendar(
    AttendanceMonthData data,
    List<AttendanceModel> attendances,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor
              .withValues(alpha: 0.3),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar<String>(
          locale: 'id_ID',

          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2035, 12, 31),

          focusedDay: _focusedDay,

          selectedDayPredicate: (day) {
            return _sameDate(day, _selectedDay);
          },

          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });

            final existing = _findAttendance(
              attendances,
              selected,
            );

            // Jika tanggal sudah memiliki absensi,
            // tampilkan detailnya.
            if (existing != null) {
              _showAttendanceDetail(existing);
            } else {
              // Jika belum ada absensi, langsung buka form.
              _showAttendanceForm();
            }
          },

          onPageChanged: (focused) {
            setState(() {
              _focusedDay = focused;
            });
          },

          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.all(3),
            cellPadding: EdgeInsets.zero,
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) {
              return _buildColoredDay(
                day,
                data,
                attendances,
              );
            },

            selectedBuilder: (context, day, focused) {
              return _buildColoredDay(
                day,
                data,
                attendances,
                isSelected: true,
              );
            },

            todayBuilder: (context, day, focused) {
              return _buildColoredDay(
                day,
                data,
                attendances,
                isToday: true,
              );
            },
          ),
        ),
      ),
    );
  }

  AttendanceModel? _findAttendance(
    List<AttendanceModel> attendances,
    DateTime date,
  ) {
    for (final item in attendances) {
      if (_sameDate(item.attendanceDate, date)) {
        return item;
      }
    }

    return null;
  }

  Color _getDayColor(
    DateTime day,
    AttendanceMonthData data,
    List<AttendanceModel> attendances,
  ) {
    // Tanggal pembayaran
    final payment = data.paymentDates.any(
      (date) => _sameDate(date, day),
    );

    if (payment) return Colors.amber;

    // Absensi pekerja terpilih
    final attendance = _findAttendance(
      attendances,
      day,
    );

    if (attendance == null) {
      return Colors.transparent;
    }

    if (attendance.status == 'absent') {
      return Colors.red;
    }

    return attendance.isPaid
        ? Colors.green
        : Colors.blue;
  }

  Widget _buildColoredDay(
    DateTime day,
    AttendanceMonthData data,
    List<AttendanceModel> attendances, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final color = _getDayColor(
      day,
      data,
      attendances,
    );

    final hasColor = color != Colors.transparent;

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : isToday
            ? Theme.of(context).colorScheme.secondary
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: hasColor ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: hasColor
              ? (color == Colors.amber
                  ? Colors.black
                  : Colors.white)
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend() {
    final items = [
      (Colors.blue, 'Hadir, belum dibayar'),
      (Colors.green, 'Hadir, sudah dibayar'),
      (Colors.amber, 'Tanggal pembayaran'),
      (Colors.grey, 'Tidak hadir'),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.$1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.$2,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ============================================================
  // SELECTED DATE DETAIL
  // ============================================================

  Widget _buildSelectedDateDetail(
    AttendanceModel? attendance,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Kehadiran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _formatDate(_selectedDay),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const Divider(height: 24),

            if (attendance == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada data absensi.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showAttendanceForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Absensi'),
                ),
              ),
            ] else ...[
              _detailRow(
                'Status Kehadiran',
                attendance.status == 'work'
                    ? 'Hadir'
                    : 'Tidak Hadir',
              ),

              const SizedBox(height: 12),

              _detailRow(
                'Status Pembayaran',
                attendance.status != 'work'
                    ? '-'
                    : attendance.isPaid
                        ? 'Sudah Dibayar'
                        : 'Belum Dibayar',
              ),

              const SizedBox(height: 12),

              _detailRow(
                'Keterangan',
                attendance.note?.isNotEmpty == true
                    ? attendance.note!
                    : '-',
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _showAttendanceForm(
                      existing: attendance,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Ubah Absensi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE DETAIL BOTTOM SHEET
  // ============================================================

  Future<void> _showAttendanceDetail(
    AttendanceModel attendance,
  ) async {
    final isWork = attendance.status == 'work';

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Absensi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                attendance.workerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _formatDate(attendance.attendanceDate),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),

              const Divider(height: 28),

              _detailRow(
                'Kehadiran',
                isWork ? 'Hadir' : 'Tidak Hadir',
              ),

              const SizedBox(height: 12),

              _detailRow(
                'Pembayaran',
                !isWork
                    ? '-'
                    : attendance.isPaid
                        ? 'Sudah Dibayar'
                        : 'Belum Dibayar',
              ),

              const SizedBox(height: 12),

              _detailRow(
                'Keterangan',
                attendance.note?.isNotEmpty == true
                    ? attendance.note!
                    : '-',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    _showAttendanceForm(
                      existing: attendance,
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Ubah Absensi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ATTENDANCE FORM
  // ============================================================

  Future<void> _showAttendanceForm({
    AttendanceModel? existing,
  }) async {
    if (_selectedWorkerId == null) return;

    String status = existing?.status ?? 'work';
    bool isSaving = false;

    final noteController = TextEditingController(
      text: existing?.note ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null
                            ? 'Catat Kehadiran'
                            : 'Ubah Kehadiran',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _formatDate(_selectedDay),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Status Kehadiran',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _statusOption(
                              title: 'Hadir',
                              icon: Icons.person_pin_rounded,
                              color: Colors.green,
                              selected: status == 'work',
                              onTap: () {
                                setSheetState(() {
                                  status = 'work';
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _statusOption(
                              title: 'Tidak Hadir',
                              icon: Icons.person_off_rounded,
                              color: Colors.red,
                              selected: status == 'absent',
                              onTap: () {
                                setSheetState(() {
                                  status = 'absent';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Keterangan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Keterangan (opsional)',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setSheetState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    if (status != 'work' &&
                                        status != 'absent') {
                                      throw Exception(
                                        'Status absensi tidak valid.',
                                      );
                                    }

                                    await ref
                                        .read(attendanceServiceProvider)
                                        .saveAttendance(
                                          workerId:
                                              _selectedWorkerId!,
                                          date: _selectedDay,
                                          status: status,
                                          note: noteController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : noteController.text
                                                  .trim(),
                                        );

                                    if (!sheetContext.mounted) return;

                                    Navigator.pop(sheetContext);

                                    _refresh();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Absensi berhasil disimpan.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    if (!sheetContext.mounted) return;

                                    setSheetState(() {
                                      isSaving = false;
                                    });

                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal menyimpan: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },

                          icon: isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),

                          label: Text(
                            isSaving
                                ? 'Menyimpan...'
                                : 'Simpan Absensi',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    noteController.dispose();
  }

  // ============================================================
  // STATUS OPTION
  // ============================================================

  Widget _statusOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : null,
                fontSize: 12,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Icon(
                Icons.check_circle,
                color: color,
                size: 17,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
