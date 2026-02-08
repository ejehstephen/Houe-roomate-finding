import 'package:camp_nest/feature/presentation/provider/matches_provider.dart';
import 'package:camp_nest/feature/presentation/widget/roomatc_card.dart';
import 'package:camp_nest/feature/presentation/widgets/fade_in_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchResultsScreen extends ConsumerStatefulWidget {
  const MatchResultsScreen({super.key});

  @override
  ConsumerState<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends ConsumerState<MatchResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Load real matches from the database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchesProvider.notifier).loadMatches();
    });
  }

  Future<void> _refresh() async {
    await ref.read(matchesProvider.notifier).loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchesState = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Your Matches'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.primaryColor,
        child:
            matchesState.isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.primaryColor),
                      const SizedBox(height: 24),
                      Text(
                        'Finding your perfect roommates...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
                : matchesState.error != null
                ? _buildErrorState(theme, matchesState.error!)
                : _buildMatchesList(theme, matchesState),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeInSlide(
          duration: 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList(ThemeData theme, MatchesState matchesState) {
    final matches = matchesState.matches;

    return Column(
      children: [
        // Header
        FadeInSlide(
          duration: 0.6,
          direction: FadeSlideDirection.ttb,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 48,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  matches.isEmpty ? 'No matches yet' : 'Great news!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  matches.isEmpty
                      ? 'Complete your questionnaire and check back soon!'
                      : 'We found ${matches.length} compatible roommate${matches.length > 1 ? 's' : ''} for you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Matches list
        Expanded(
          child:
              matches.isEmpty
                  ? ListView(
                    // Wrap in ListView for RefreshIndicator
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                      ),
                      FadeInSlide(
                        duration: 0.8,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No matches found yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                'We match you with people from your school who have different apartment statuses. Check back later!',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[500],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return FadeInSlide(
                        duration: 0.5,
                        delay: index * 0.1,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RoommateCard(
                            match: match,
                            onChatPressed: () async {
                              final phone = match.phoneNumber;
                              if (phone != null && phone.isNotEmpty) {
                                final sanitized = phone.replaceAll(
                                  RegExp(r'[\s\-()]+'),
                                  '',
                                );
                                final normalized =
                                    sanitized.startsWith('+')
                                        ? sanitized.substring(1)
                                        : sanitized;
                                final url = Uri.parse(
                                  'https://wa.me/$normalized',
                                );

                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open WhatsApp',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No phone number available for this user',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
