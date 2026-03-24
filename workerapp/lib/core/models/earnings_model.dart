class WorkerEarningsModel {
  final double grossEarnings;
  final double commission;
  final double netEarnings;
  final int totalJobs;
  final double avgPerJob;
  final List<DailyEarning> dailyEarnings;
  final List<ServiceRevenue> topServices;

  const WorkerEarningsModel({
    this.grossEarnings = 0,
    this.commission = 0,
    this.netEarnings = 0,
    this.totalJobs = 0,
    this.avgPerJob = 0,
    this.dailyEarnings = const [],
    this.topServices = const [],
  });
}

class DailyEarning {
  final DateTime date;
  final double amount;
  final int jobs;

  const DailyEarning({
    required this.date,
    required this.amount,
    required this.jobs,
  });
}

class ServiceRevenue {
  final String serviceName;
  final double revenue;
  final int count;

  const ServiceRevenue({
    required this.serviceName,
    required this.revenue,
    required this.count,
  });
}
