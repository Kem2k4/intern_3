class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Video call notification methods removed - feature will be re-implemented
  // Context management can be added later when needed
}
