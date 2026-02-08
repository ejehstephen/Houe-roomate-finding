import 'package:camp_nest/core/model/notification_model.dart';
import 'package:camp_nest/core/service/notification_service.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final service = ref.watch(notificationServiceProvider);
  // Rebuild stream when auth state changes (e.g. login/logout)
  ref.watch(authProvider);
  return service.getNotificationsStream();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationStreamProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
