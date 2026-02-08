import 'package:camp_nest/feature/presentation/provider/questionnaire_provider.dart';
import 'package:camp_nest/feature/presentation/screens/match_screen.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionnaireState = ref.watch(questionnaireProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (questionnaireState.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    if (questionnaireState.error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${questionnaireState.error}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry logic here if available
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Step ${questionnaireState.currentQuestionIndex + 1} of ${questionnaireState.questions.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading:
            questionnaireState.currentQuestionIndex > 0
                ? IconButton(
                  onPressed: () {
                    ref.read(questionnaireProvider.notifier).previousQuestion();
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                )
                : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              FadeInSlide(
                duration: 0.5,
                direction: FadeSlideDirection.ltr,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Question
              FadeInSlide(
                duration: 0.5,
                delay: 0.1,
                child: Text(
                  currentQuestion.question,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Answer options
              Expanded(
                child: ListView.separated(
                  itemCount: currentQuestion.options.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options[index];
                    final currentAnswers =
                        questionnaireState
                            .answers[currentQuestion.id]
                            ?.answers ??
                        [];
                    final isSelected = currentAnswers.contains(option);

                    return FadeInSlide(
                      duration: 0.5,
                      delay: 0.2 + (index * 0.05),
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
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? theme.primaryColor.withOpacity(0.05)
                                    : (isDark
                                        ? Colors.grey[900]
                                        : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? theme.primaryColor
                                      : (isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: theme.primaryColor.withOpacity(
                                          0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? theme.primaryColor
                                            : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (currentQuestion.type == 'multiple')
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? theme.primaryColor
                                              : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color:
                                        isSelected
                                            ? theme.primaryColor
                                            : Colors.transparent,
                                  ),
                                  child:
                                      isSelected
                                          ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                          : null,
                                )
                              else
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? theme.primaryColor
                                              : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child:
                                      isSelected
                                          ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: theme.primaryColor,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Navigation button
              FadeInSlide(
                duration: 0.5,
                delay: 0.3,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation:
                          questionnaireState.answers.containsKey(
                                currentQuestion.id,
                              )
                              ? 4
                              : 0,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                    ),
                    child: Text(
                      questionnaireState.currentQuestionIndex ==
                              questionnaireState.questions.length - 1
                          ? 'Finish'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
