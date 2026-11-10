import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/worker_model.dart';

class WorkerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Worker>> getWorkers() async {
    final response = await _supabase
        .from('workers')
        .select()
        .order('name');

    return (response as List)
        .map((item) => Worker.fromJson(item))
        .toList();
  }

  Future<void> addWorker({
    required Worker worker,
    File? photo,
  }) async {
    String? photoUrl;

    if (photo != null) {
      photoUrl = await uploadPhoto(photo);
    }

    final data = worker.toJson();
    data['photo_url'] = photoUrl;

    await _supabase.from('workers').insert(data);
  }

  Future<void> updateWorker({
    required Worker worker,
    File? photo,
  }) async {
    final data = worker.toJson();

    if (photo != null) {
      data['photo_url'] = await uploadPhoto(photo);
    }

    await _supabase
        .from('workers')
        .update(data)
        .eq('id', worker.id);
  }

  Future<void> deleteWorker(Worker worker) async {
    await _supabase
        .from('workers')
        .delete()
        .eq('id', worker.id);
  }

  Future<String> uploadPhoto(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _supabase.storage
        .from('worker-photos')
        .upload(
          fileName,
          file,
          fileOptions: FileOptions(
            upsert: true,
          ),
        );

    return _supabase.storage
        .from('worker-photos')
        .getPublicUrl(fileName);
  }
}