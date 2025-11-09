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

  factory QuestionnaireQuestion.fromJson(Map<String, dynamic> json) {
    return QuestionnaireQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      type: json['type']?.toString() ?? 'single',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'type': type,
      };
}

class QuestionnaireAnswer {
  final String questionId;
  final List<String> answers;

  QuestionnaireAnswer({required this.questionId, required this.answers});

  factory QuestionnaireAnswer.fromJson(Map<String, dynamic> json) {
    final raw = json['answers'];
    return QuestionnaireAnswer(
      questionId: json['questionId']?.toString() ?? json['question_id']?.toString() ?? '',
      answers: raw is List ? raw.map((e) => e.toString()).toList() : [if (raw != null) raw.toString()],
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'answers': answers,
      };
}
