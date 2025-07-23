import 'package:camp_nest/core/model/questionnaire.dart';
import 'package:camp_nest/core/service/matching_service.dart';
import 'package:camp_nest/core/service/questionaire_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionnaireState {
  final List<QuestionnaireQuestion> questions;
  final Map<String, QuestionnaireAnswer> answers;
  final int currentQuestionIndex;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  QuestionnaireState({
    this.questions = const [],
    this.answers = const {},
    this.currentQuestionIndex = 0,
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  QuestionnaireState copyWith({
    List<QuestionnaireQuestion>? questions,
    Map<String, QuestionnaireAnswer>? answers,
    int? currentQuestionIndex,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return QuestionnaireState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  final QuestionnaireService _questionnaireService;
  final MatchingService _matchingService;

  QuestionnaireNotifier(this._questionnaireService, this._matchingService)
    : super(QuestionnaireState()) {
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final questions = await _questionnaireService.getQuestions();

      // Check if user has existing answers
      final currentUserId = _questionnaireService.client.auth.currentUser?.id;
      if (currentUserId != null) {
        final existingAnswers = await _questionnaireService.getUserAnswers(
          currentUserId,
        );
        state = state.copyWith(
          questions: questions,
          answers: existingAnswers,
          isLoading: false,
        );
      } else {
        state = state.copyWith(questions: questions, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void answerQuestion(String questionId, List<String> answers) {
    final newAnswers = Map<String, QuestionnaireAnswer>.from(state.answers);
    newAnswers[questionId] = QuestionnaireAnswer(
      questionId: questionId,
      answers: answers,
    );

    state = state.copyWith(answers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    } else {
      _completeQuestionnaire();
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  Future<void> _completeQuestionnaire() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user ID from Supabase auth
      final currentUserId = _questionnaireService.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Save answers to Supabase using upsert
      await _questionnaireService.saveAnswers(state.answers);

      // Calculate matches
      await _matchingService.calculateMatches(currentUserId);

      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      // If upsert fails, try individual saves as fallback
      try {
        final currentUserId = _questionnaireService.client.auth.currentUser?.id;
        if (currentUserId != null) {
          await _questionnaireService.saveAnswersIndividually(state.answers);
          await _matchingService.calculateMatches(currentUserId);
          state = state.copyWith(isCompleted: true, isLoading: false);
        } else {
          throw Exception('User not authenticated');
        }
      } catch (fallbackError) {
        state = state.copyWith(
          error: 'Failed to save questionnaire: ${fallbackError.toString()}',
          isLoading: false,
        );
      }
    }
  }

  void resetQuestionnaire() {
    state = QuestionnaireState();
    loadQuestions();
  }

  // Method to retake questionnaire
  Future<void> retakeQuestionnaire() async {
    state = state.copyWith(
      currentQuestionIndex: 0,
      isCompleted: false,
      answers: {},
      error: null,
    );
  }
}

// Providers
final questionnaireServiceProvider = Provider<QuestionnaireService>(
  (ref) => QuestionnaireService(),
);
final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(),
);

final questionnaireProvider =
    StateNotifierProvider<QuestionnaireNotifier, QuestionnaireState>((ref) {
      return QuestionnaireNotifier(
        ref.read(questionnaireServiceProvider),
        ref.read(matchingServiceProvider),
      );
    });
