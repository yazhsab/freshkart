class ApiEndpoints {
  ApiEndpoints._();

  // Agent
  static const String registerAgent = '/agent/register';
  static const String agentProfile = '/agent/profile';
  static String agentProfileById(String id) => '/agent/$id/profile';

  // Online status
  static const String toggleOnline = '/agent/toggle-online';

  // Deliveries
  static String acceptDelivery(String orderId) => '/delivery/$orderId/accept';
  static String rejectDelivery(String orderId) => '/delivery/$orderId/reject';
  static String pickupConfirm(String orderId) =>
      '/delivery/$orderId/pickup-confirm';
  static String deliveryConfirm(String orderId) =>
      '/delivery/$orderId/delivery-confirm';
  static const String activeDelivery = '/delivery/active';
  static const String deliveryHistory = '/delivery/history';
  static String deliveryDetails(String orderId) => '/delivery/$orderId';

  // Earnings
  static const String earnings = '/agent/earnings';
  static const String earningsSummary = '/agent/earnings/summary';
  static const String earningsDaily = '/agent/earnings/daily';
  static const String payouts = '/agent/payouts';

  // Support
  static const String supportTicket = '/agent/support/ticket';
  static const String supportTickets = '/agent/support/tickets';

  // Notifications
  static const String registerFcmToken = '/agent/fcm-token';

  // Location
  static const String updateLocation = '/agent/location';
}
