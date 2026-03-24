import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/models/worker_model.dart';
import 'package:freshkart_worker/core/models/profile_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

final workerProfileProvider = FutureProvider<WorkerModel?>((ref) async {
  final workerId = LocalStorage.workerId;
  if (workerId == null) return null;
  final data = await Supabase.instance.client
      .from('workers')
      .select()
      .eq('id', workerId)
      .maybeSingle();
  return data != null ? WorkerModel.fromJson(data) : null;
});

final workerReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final workerId = LocalStorage.workerId;
  if (workerId == null) return [];
  final data = await Supabase.instance.client
      .from('reviews')
      .select()
      .eq('worker_id', workerId)
      .order('created_at', ascending: false);
  return (data as List).map((r) => ReviewModel.fromJson(r)).toList();
});
