// Web stub — all notification APIs are no-ops on web.
Future<void> initializePlugin() async {}
Future<void> cancelAll() async {}
Future<void> showNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {}
Future<void> scheduleEodReminder({
  required int hour,
  required int minute,
  required String title,
  required String body,
  required int notificationId,
}) async {}
