class QuestionnaireQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String type; // 'single', 'multiple', 'range'

  QuestionnaireQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.type,
  });
}

class QuestionnaireAnswer {
  final String questionId;
  final List<String> answers;

  QuestionnaireAnswer({required this.questionId, required this.answers});
}
