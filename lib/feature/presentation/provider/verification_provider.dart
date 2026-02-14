import 'package:image_picker/image_picker.dart';
import 'package:camp_nest/core/service/verification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

// Provides the current status of the user's verification
final verificationStatusProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final service = ref.watch(verificationServiceProvider);
      return service.getVerificationStatus();
    });

// Notifier for handling verification actions (submit)
class VerificationNotifier extends StateNotifier<AsyncValue<void>> {
  final VerificationService _service;

  VerificationNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submitVerification({
    required String fullName,
    required DateTime dateOfBirth,
    required String ninNumber,
    required String documentType,
    required XFile frontImage,
    XFile? backImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.submitVerificationRequest(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        ninNumber: ninNumber,
        documentType: documentType,
        frontImage: frontImage,
        backImage: backImage,
      );

      if (result['success'] == true) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          result['error'] ?? 'Submission failed',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final verificationNotifierProvider =
    StateNotifierProvider<VerificationNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(verificationServiceProvider);
      return VerificationNotifier(service);
    });
