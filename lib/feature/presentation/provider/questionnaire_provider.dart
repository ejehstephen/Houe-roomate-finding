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
      // 1) Load questions from API
      final questions = await _questionnaireService.getQuestions();
      print('Questionnaire: loaded ${questions.length} questions');

      // 2) Try to load existing answers and completion status (user inferred from token)
      Map<String, QuestionnaireAnswer> existingAnswers = {};
      bool completed = false;
      try {
        existingAnswers = await _questionnaireService.getUserAnswers('current');
        print('Questionnaire: fetched ${existingAnswers.length} existing answers');
      } catch (e) {
        print('Questionnaire: getUserAnswers error: $e');
      }
      try {
        completed = await _questionnaireService.hasUserCompletedQuestionnaire('current');
        print('Questionnaire: completion status = $completed');
      } catch (e) {
        print('Questionnaire: status error: $e');
      }

      // 3) Determine current index: first unanswered question
      final idx = _firstUnansweredIndex(questions, existingAnswers);

      state = state.copyWith(
        questions: questions,
        answers: existingAnswers,
        isCompleted: completed,
        currentQuestionIndex: idx,
        isLoading: false,
      );
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

  int _firstUnansweredIndex(
    List<QuestionnaireQuestion> questions,
    Map<String, QuestionnaireAnswer> answers,
  ) {
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final a = answers[q.id];
      if (a == null || a.answers.isEmpty) return i;
    }
    return 0;
  }

  Future<void> refreshFromServer() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final answers = await _questionnaireService.getUserAnswers('current');
      final completed = await _questionnaireService.hasUserCompletedQuestionnaire('current');
      final idx = _firstUnansweredIndex(state.questions, answers);
      state = state.copyWith(
        answers: answers,
        isCompleted: completed,
        currentQuestionIndex: idx,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> _completeQuestionnaire() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save answers to backend
      await _questionnaireService.saveAnswers(state.answers);

      // Optionally trigger match recalculation (backend can infer user from token)
      try {
        await _matchingService.calculateMatches('current_user_id');
      } catch (e) {
        print('Questionnaire: calculateMatches error (non-fatal): $e');
      }

      // Refresh status and answers after saving
      await refreshFromServer();
      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      // Fallback: try individual save
      try {
        await _questionnaireService.saveAnswersIndividually(state.answers);
        try {
          await _matchingService.calculateMatches('current_user_id');
        } catch (e) {
          print('Questionnaire: calculateMatches error after fallback (non-fatal): $e');
        }
        await refreshFromServer();
        state = state.copyWith(isCompleted: true, isLoading: false);
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
