import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/worker_model.dart';
import '../providers/worker_provider.dart';

class WorkerFormPage extends ConsumerStatefulWidget {
  final Worker? worker;

  const WorkerFormPage({
    super.key,
    this.worker,
  });

  @override
  ConsumerState<WorkerFormPage> createState() =>
      _WorkerFormPageState();
}

class _WorkerFormPageState extends ConsumerState<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _whatsappController;

  String _position = 'petukang';
  DateTime _joinDate = DateTime.now();
  bool _isActive = true;
  bool _isLoading = false;

  File? _selectedPhoto;

  bool get isEdit => widget.worker != null;

  @override
  void initState() {
    super.initState();

    final worker = widget.worker;

    _nameController = TextEditingController(
      text: worker?.name ?? '',
    );

    _whatsappController = TextEditingController(
      text: worker?.whatsapp ?? '',
    );

    if (worker != null) {
      _position = worker.position;
      _joinDate = worker.joinDate;
      _isActive = worker.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1000,
    );

    if (image != null) {
      setState(() {
        _selectedPhoto = File(image.path);
      });
    }
  }

  Future<void> selectJoinDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        _joinDate = selected;
      });
    }
  }

  Future<void> saveWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final worker = Worker(
        id: widget.worker?.id ?? '',
        name: _nameController.text.trim(),
        position: _position,
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        photoUrl: widget.worker?.photoUrl,
        joinDate: _joinDate,
        isActive: _isActive,
      );

      final service = ref.read(workerServiceProvider);

      if (isEdit) {
        await service.updateWorker(
          worker: worker,
          photo: _selectedPhoto,
        );
      } else {
        await service.addWorker(
          worker: worker,
          photo: _selectedPhoto,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Data pekerja berhasil diperbarui'
                : 'Pekerja berhasil ditambahkan',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Pekerja' : 'Tambah Pekerja',
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: pickPhoto,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFE8F0FE),
                  backgroundImage: _selectedPhoto != null
                      ? FileImage(_selectedPhoto!)
                      : worker?.photoUrl != null
                          ? NetworkImage(worker!.photoUrl!)
                          : null,
                  child: _selectedPhoto == null &&
                          worker?.photoUrl == null
                      ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Pilih Foto Pekerja',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Nama Lengkap',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                'Masukkan nama pekerja',
                Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pekerja wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Posisi Pekerjaan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _position,
              decoration: _inputDecoration(
                'Pilih posisi',
                Icons.work_outline,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'kepala_petukang',
                  child: Text('Kepala Petukang'),
                ),
                DropdownMenuItem(
                  value: 'petukang',
                  child: Text('Petukang'),
                ),
                DropdownMenuItem(
                  value: 'kenek',
                  child: Text('Kenek'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _position = value);
                }
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Nomor WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                'Contoh: 081234567890',
                Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Tanggal Bergabung',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: selectJoinDate,
              child: InputDecorator(
                decoration: _inputDecoration(
                  'Tanggal bergabung',
                  Icons.calendar_today_outlined,
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID')
                      .format(_joinDate),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Status Pekerja',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_isActive ? 'Aktif' : 'Tidak Aktif'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : saveWorker,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan Pekerja',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}