import 'package:camp_nest/feature/presentation/provider/matches_provider.dart';
import 'package:camp_nest/feature/presentation/provider/auth_provider.dart';
import 'package:camp_nest/feature/presentation/widget/roomatc_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';

class MatchResultsScreen extends ConsumerStatefulWidget {
  const MatchResultsScreen({super.key});

  @override
  ConsumerState<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends ConsumerState<MatchResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchesProvider.notifier).loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(matchesProvider);
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Matches'), centerTitle: true),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Great news!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  matchesState.isLoading
                      ? 'Finding your matches...'
                      : 'We found ${matchesState.matches.length} compatible roommates for you',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Matches list
          Expanded(
            child:
                matchesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : matchesState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${matchesState.error}'),
                          ElevatedButton(
                            onPressed:
                                () =>
                                    ref
                                        .read(matchesProvider.notifier)
                                        .loadMatches(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : matchesState.matches.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No matches found yet'),
                          // Text('Complete the questionnaire to find matches'),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: matchesState.matches.length,
                      itemBuilder: (context, index) {
                        final match = matchesState.matches[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Builder(
                            builder: (context) {
                              // Debug: Log profile image usage
                              final matchImageUrl = match.profileImage;
                              final currentUserImageUrl =
                                  currentUser?.profileImage;
                              print(
                                '🖼️ DEBUG: Match ${match.name} profileImage: ${matchImageUrl.isNotEmpty ? (matchImageUrl.length > 50 ? '${matchImageUrl.substring(0, 50)}...' : matchImageUrl) : 'empty'}',
                              );
                              print(
                                '👤 DEBUG: Current user profileImage: ${currentUserImageUrl != null ? (currentUserImageUrl.length > 50 ? '${currentUserImageUrl.substring(0, 50)}...' : currentUserImageUrl) : 'null'}',
                              );

                              return RoommateCard(
                                match: match,
                                avatarOverrideUrl:
                                    null, // Don't override - let each match use their own profile image
                                onChatPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatScreen(
                                            roommateId: match.id,
                                            roommateName: match.name,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
