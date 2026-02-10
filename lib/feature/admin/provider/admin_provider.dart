import 'package:camp_nest/core/model/report_model.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:camp_nest/core/service/admin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getPlatformStats();
});

final adminUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getAllUsers();
});

final adminListingsProvider = FutureProvider<List<RoomListingModel>>((
  ref,
) async {
  final service = ref.watch(adminServiceProvider);
  return service.getAllListings();
});

final adminReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getAllReports();
});
