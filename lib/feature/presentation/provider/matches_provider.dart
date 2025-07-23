import 'package:camp_nest/core/model/roomate_matching.dart';
import 'package:camp_nest/core/service/matching_service.dart';
import 'package:camp_nest/feature/presentation/provider/questionnaire_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchesState {
  final List<RoommateMatchModel> matches;
  final bool isLoading;
  final String? error;

  MatchesState({this.matches = const [], this.isLoading = false, this.error});

  MatchesState copyWith({
    List<RoommateMatchModel>? matches,
    bool? isLoading,
    String? error,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final MatchingService _matchingService;

  MatchesNotifier(this._matchingService) : super(MatchesState());

  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _matchingService.getMatches();
      state = state.copyWith(matches: matches, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final matchesProvider = StateNotifierProvider<MatchesNotifier, MatchesState>((
  ref,
) {
  return MatchesNotifier(ref.read(matchingServiceProvider));
});
