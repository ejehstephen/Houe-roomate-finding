import 'package:camp_nest/feature/presentation/provider/questionnaire_provider.dart';
import 'package:camp_nest/feature/presentation/screens/match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionnaireState = ref.watch(questionnaireProvider);

    if (questionnaireState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questionnaireState.error != null) {
      return Scaffold(
        body: Center(child: Text('Error: ${questionnaireState.error}')),
      );
    }

    if (questionnaireState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MatchResultsScreen()),
        );
      });
    }

    if (questionnaireState.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion =
        questionnaireState.questions[questionnaireState.currentQuestionIndex];
    final progress =
        (questionnaireState.currentQuestionIndex + 1) /
        questionnaireState.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${questionnaireState.currentQuestionIndex + 1} of ${questionnaireState.questions.length}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Question
            Text(
              currentQuestion.question,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 32),

            // Answer options
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  final option = currentQuestion.options[index];
                  final currentAnswers =
                      questionnaireState.answers[currentQuestion.id]?.answers ??
                      [];
                  final isSelected = currentAnswers.contains(option);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          List<String> newAnswers;
                          if (currentQuestion.type == 'multiple') {
                            newAnswers = List.from(currentAnswers);
                            if (isSelected) {
                              newAnswers.remove(option);
                            } else {
                              newAnswers.add(option);
                            }
                          } else {
                            newAnswers = [option];
                          }

                          ref
                              .read(questionnaireProvider.notifier)
                              .answerQuestion(currentQuestion.id, newAnswers);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Row(
                            children: [
                              if (currentQuestion.type == 'multiple')
                                Checkbox(value: isSelected, onChanged: null)
                              else
                                Radio<bool>(
                                  value: true,
                                  groupValue: isSelected,
                                  onChanged: null,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons
            Row(
              children: [
                if (questionnaireState.currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(questionnaireProvider.notifier)
                            .previousQuestion();
                      },
                      child: const Text('Previous'),
                    ),
                  ),

                if (questionnaireState.currentQuestionIndex > 0)
                  const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        questionnaireState.answers.containsKey(
                              currentQuestion.id,
                            )
                            ? () {
                              ref
                                  .read(questionnaireProvider.notifier)
                                  .nextQuestion();
                            }
                            : null,
                    child: Text(
                      questionnaireState.currentQuestionIndex ==
                              questionnaireState.questions.length - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
