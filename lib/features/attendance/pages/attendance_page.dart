
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../services/attendance_service.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() =>
      _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
        .format(date);
  }

  void _refresh() {
    final month = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    );

    ref.invalidate(attendanceMonthProvider(month));
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final month = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    );

    final attendanceAsync =
        ref.watch(attendanceMonthProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Absensi Pekerja',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: attendanceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat data absensi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        data: (data) => _buildContent(data),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAttendanceDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Absensi'),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(AttendanceMonthData data) {
    final selectedAttendances = data.attendances
        .where(
          (item) =>
              _sameDate(item.attendanceDate, _selectedDay),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _buildSummary(data),

        const SizedBox(height: 18),

        // CALENDAR
        Card(
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

                // Klik tanggal langsung membuka form.
                _showAttendanceDialog();
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
                defaultBuilder: (context, day, focusedDay) {
                  return _buildColoredDay(day, data);
                },

                selectedBuilder: (context, day, focusedDay) {
                  return _buildColoredDay(
                    day,
                    data,
                    isSelected: true,
                  );
                },

                todayBuilder: (context, day, focusedDay) {
                  return _buildColoredDay(
                    day,
                    data,
                    isToday: true,
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        _buildLegend(),

        const SizedBox(height: 24),

        // SELECTED DATE HEADER
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Kehadiran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_selectedDay),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Tambah absensi',
              onPressed: _showAttendanceDialog,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ATTENDANCE LIST
        if (selectedAttendances.isEmpty)
          _buildEmptyAttendance(),

        ...selectedAttendances.map(_attendanceCard),

        const SizedBox(height: 18),

      ],
    );
  }

  // ============================================================
  // CALENDAR FULL COLOR CIRCLE
  // ============================================================

  Color _getDayColor(
    DateTime day,
    AttendanceMonthData data,
  ) {
    // Tanggal pembayaran memiliki prioritas warna amber.
    final isPaymentDate = data.paymentDates.any(
      (date) => _sameDate(date, day),
    );

    if (isPaymentDate) {
      return Colors.amber;
    }

    // Ambil seluruh catatan absensi pada tanggal tersebut.
    final dayAttendances = data.attendances.where(
      (item) => _sameDate(item.attendanceDate, day),
    ).toList();

    if (dayAttendances.isEmpty) {
      return Colors.transparent;
    }

    final workAttendances = dayAttendances
        .where((item) => item.status == 'work')
        .toList();

    // Jika semua pekerja tidak hadir, tampilkan warna abu-abu.
    if (workAttendances.isEmpty) {
      return dayAttendances.any((item) => item.status == 'absent')
          ? Colors.red
          : Colors.transparent;
    }

    // Jika ada upah belum dibayar, warna biru.
    final hasUnpaid = workAttendances.any((item) => !item.isPaid);

    return hasUnpaid ? Colors.blue : Colors.green;
  }

  Widget _buildColoredDay(
    DateTime day,
    AttendanceMonthData data, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final color = _getDayColor(day, data);
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
  // CALENDAR LEGEND
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
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: item.$1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.$2,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(AttendanceMonthData data) {
    final today = _dateOnly(DateTime.now());

    final todayWorkers = data.attendances.where(
      (item) =>
          _sameDate(item.attendanceDate, today) &&
          item.status == 'work',
    ).length;

    final paid = data.attendances.where(
      (item) => item.status == 'work' && item.isPaid,
    ).length;

    final unpaid = data.attendances.where(
      (item) => item.status == 'work' && !item.isPaid,
    ).length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Hadir Hari Ini',
            value: '$todayWorkers',
            color: Colors.blue,
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            title: 'Sudah Dibayar',
            value: '$paid',
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            title: 'Belum Dibayar',
            value: '$unpaid',
            color: Colors.orange,
            icon: Icons.payments_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 9),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyAttendance() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 42,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum Ada Absensi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Belum ada data kehadiran pada tanggal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: _showAttendanceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Absensi'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _attendanceCard(AttendanceModel item) {
    final isWork = item.status == 'work';

    final color = !isWork
        ? Colors.grey
        : item.isPaid
            ? Colors.green
            : Colors.blue;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),

        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isWork
                ? Icons.person_rounded
                : Icons.person_off_rounded,
            color: color,
          ),
        ),

        title: Text(
          item.workerName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isWork
                ? item.isPaid
                    ? 'Hadir • Upah sudah dibayar'
                    : 'Hadir • Upah belum dibayar'
                : 'Tidak hadir',
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              try {
                await ref
                    .read(attendanceServiceProvider)
                    .deleteAttendance(item.id);

                _refresh();
              } catch (error) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menghapus absensi: $error',
                    ),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text('Hapus Absensi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE FORM - MODERN BOTTOM SHEET
  // ============================================================

  Future<void> _showAttendanceDialog() async {
    try {
      final workers = await ref
          .read(activeWorkersForAttendanceProvider.future);

      if (!mounted) return;

      if (workers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada pekerja aktif.'),
          ),
        );
        return;
      }

      String? workerId = workers.first['id'].toString();
      String status = 'work';
      bool isSaving = false;

      final noteController = TextEditingController();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,

        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomInset =
                  MediaQuery.of(context).viewInsets.bottom;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: bottomInset,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20, 12, 20, 24,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HANDLE
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // HEADER
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catat Kehadiran',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Masukkan data kehadiran pekerja',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // DATE
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tanggal Absensi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(_selectedDay),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // WORKER
                        const Text(
                          'Pilih Pekerja',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 9),

                        DropdownButtonFormField<String>(
                          value: workerId,
                          isExpanded: true,

                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                            hintText: 'Pilih pekerja',
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),

                          items: workers.map((worker) {
                            final position =
                                worker['position']?.toString() ?? '';

                            return DropdownMenuItem<String>(
                              value: worker['id'].toString(),
                              child: Text(
                                '${worker['name']}'
                                '${position.isNotEmpty ? ' • ${_positionLabel(position)}' : ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    workerId = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 22),

                        // STATUS
                        const Text(
                          'Status Kehadiran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _attendanceStatusOption(
                                title: 'Hadir',
                                subtitle: 'Masuk bekerja',
                                icon: Icons.person_pin_circle_rounded,
                                color: Colors.green,
                                selected: status == 'work',
                                onTap: isSaving
                                    ? () {}
                                    : () {
                                        setSheetState(() {
                                          status = 'work';
                                        });
                                      },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _attendanceStatusOption(
                                title: 'Tidak Hadir',
                                subtitle: 'Tidak bekerja',
                                icon: Icons.person_off_rounded,
                                color: Colors.red,
                                selected: status == 'absent',
                                onTap: isSaving
                                    ? () {}
                                    : () {
                                        setSheetState(() {
                                          status = 'absent';
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // NOTE
                        const Text(
                          'Keterangan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          enabled: !isSaving,

                          decoration: InputDecoration(
                            hintText:
                                'Tambahkan keterangan (opsional)...',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 45),
                              child: Icon(Icons.notes_rounded),
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (workerId == null) return;

                                    setSheetState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await ref
                                          .read(
                                            attendanceServiceProvider,
                                          )
                                          .saveAttendance(
                                            workerId: workerId!,
                                            date: _selectedDay,
                                            status: status,
                                            note: noteController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : noteController.text
                                                    .trim(),
                                          );

                                      if (!sheetContext.mounted) {
                                        return;
                                      }

                                      Navigator.pop(sheetContext);

                                      _refresh();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kehadiran berhasil disimpan.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      if (!sheetContext.mounted) {
                                        return;
                                      }

                                      setSheetState(() {
                                        isSaving = false;
                                      });

                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
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
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),

                            label: Text(
                              isSaving
                                  ? 'Menyimpan...'
                                  : 'Simpan Kehadiran',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
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
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat data pekerja: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ATTENDANCE STATUS OPTION
  // ============================================================

  Widget _attendanceStatusOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surface,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : null,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),

            if (selected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POSITION LABEL
  // ============================================================

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
}
