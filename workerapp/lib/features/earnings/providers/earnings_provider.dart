import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/config/app_config.dart';
import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/models/earnings_model.dart';
import 'package:freshkart_worker/core/models/payout_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';

enum EarningsPeriod { today, week, month }

final earningsProvider =
    FutureProvider.family<WorkerEarningsModel, EarningsPeriod>((
  ref,
  period,
) async {
  final workerId = LocalStorage.workerId;
  if (workerId == null) return const WorkerEarningsModel();

  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  DateTime startDate;

  switch (period) {
    case EarningsPeriod.today:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case EarningsPeriod.week:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      break;
    case EarningsPeriod.month:
      startDate = DateTime(now.year, now.month, 1);
      break;
  }

  final startStr = startDate.toIso8601String().split('T').first;
  final data = await supabase
      .from('bookings')
      .select()
      .eq('worker_id', workerId)
      .eq('status', 'completed')
      .gte('scheduled_date', startStr)
      .order('scheduled_date');

  final bookings = (data as List).map((b) => BookingModel.fromJson(b)).toList();

  final gross = bookings.fold<double>(0, (sum, b) => sum + b.displayAmount);
  final commission = gross * AppConfig.commissionRate;
  final net = gross - commission;
  final avgPerJob = bookings.isEmpty ? 0.0 : net / bookings.length;

  final Map<String, DailyEarning> dailyMap = {};
  for (final b in bookings) {
    final key = b.scheduledDate.toIso8601String().split('T').first;
    final existing = dailyMap[key];
    if (existing != null) {
      dailyMap[key] = DailyEarning(
        date: b.scheduledDate,
        amount: existing.amount + (b.workerEarnings ?? 0),
        jobs: existing.jobs + 1,
      );
    } else {
      dailyMap[key] = DailyEarning(
        date: b.scheduledDate,
        amount: b.workerEarnings ?? 0,
        jobs: 1,
      );
    }
  }

  final Map<String, ServiceRevenue> serviceMap = {};
  for (final b in bookings) {
    final name = b.serviceName ?? 'Other';
    final existing = serviceMap[name];
    if (existing != null) {
      serviceMap[name] = ServiceRevenue(
        serviceName: name,
        revenue: existing.revenue + (b.workerEarnings ?? 0),
        count: existing.count + 1,
      );
    } else {
      serviceMap[name] = ServiceRevenue(
        serviceName: name,
        revenue: b.workerEarnings ?? 0,
        count: 1,
      );
    }
  }

  final topServices = serviceMap.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  return WorkerEarningsModel(
    grossEarnings: gross,
    commission: commission,
    netEarnings: net,
    totalJobs: bookings.length,
    avgPerJob: avgPerJob,
    dailyEarnings: dailyMap.values.toList(),
    topServices: topServices.take(5).toList(),
  );
});

final payoutsProvider = FutureProvider<List<PayoutModel>>((ref) async {
  final workerId = LocalStorage.workerId;
  if (workerId == null) return [];

  final data = await Supabase.instance.client
      .from('payouts')
      .select()
      .eq('worker_id', workerId)
      .order('period_end', ascending: false);

  return (data as List).map((p) => PayoutModel.fromJson(p)).toList();
});
