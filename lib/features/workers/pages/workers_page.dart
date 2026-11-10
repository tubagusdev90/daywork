import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_model.dart';
import '../providers/worker_provider.dart';
import 'worker_form_page.dart';

class WorkersPage extends ConsumerStatefulWidget {
  const WorkersPage({super.key});

  @override
  ConsumerState<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends ConsumerState<WorkersPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String positionLabel(String position) {
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

  Future<void> openForm({Worker? worker}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerFormPage(worker: worker),
      ),
    );

    ref.invalidate(workersProvider);
  }

  Future<void> deleteWorker(Worker worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pekerja'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${worker.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(workerServiceProvider).deleteWorker(worker);

      ref.invalidate(workersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pekerja berhasil dihapus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pekerja: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pekerja'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workersProvider);
            await ref.read(workersProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Data Pekerja',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Kelola informasi seluruh pekerja proyek.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _search = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama pekerja...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              workersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 45,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text('Gagal mengambil data: $error'),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(workersProvider);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
                data: (workers) {
                  final filteredWorkers = workers.where((worker) {
                    return worker.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filteredWorkers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('Data pekerja belum tersedia.'),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filteredWorkers.length} Pekerja',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...filteredWorkers.map(
                        (worker) => _workerCard(worker),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workerCard(Worker worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFFE8F0FE),
              backgroundImage: worker.photoUrl != null
                  ? NetworkImage(worker.photoUrl!)
                  : null,
              child: worker.photoUrl == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF2563EB),
                    )
                  : null,
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    positionLabel(worker.position),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    worker.whatsapp ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    worker.isActive ? 'Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      color: worker.isActive
                          ? Colors.green
                          : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  openForm(worker: worker);
                } else if (value == 'delete') {
                  deleteWorker(worker);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 
}