import 'package:camp_nest/feature/admin/provider/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminReportsTab extends ConsumerWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return reportsAsync.when(
      data:
          (reports) => ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ExpansionTile(
                leading: Icon(
                  Icons.report_problem,
                  color: report.status == 'pending' ? Colors.red : Colors.green,
                ),
                title: Text(report.reason),
                subtitle: Text(
                  'Status: ${report.status} • ${DateFormat.yMMMd().format(report.createdAt)}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details: ${report.details ?? "No details provided"}',
                        ),
                        const SizedBox(height: 8),
                        if (report.reporterName != null)
                          Text('Reported by: ${report.reporterName}')
                        else
                          Text('Reporter ID: ${report.reporterId}'),
                        if (report.reportedUserName != null)
                          Text('Reported User: ${report.reportedUserName}')
                        else if (report.reportedUserId != null)
                          Text('Reported User ID: ${report.reportedUserId}'),
                        if (report.reportedListingTitle != null)
                          Text('Listing: ${report.reportedListingTitle}')
                        else if (report.reportedListingId != null)
                          Text(
                            'Reported Listing ID: ${report.reportedListingId}',
                          ),
                        const SizedBox(height: 16),
                        if (report.status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(adminServiceProvider)
                                      .resolveReport(report.id, 'dismissed');
                                  ref.refresh(adminReportsProvider);
                                },
                                child: const Text('Dismiss'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(adminServiceProvider)
                                      .resolveReport(report.id, 'resolved');
                                  ref.refresh(adminReportsProvider);
                                },
                                child: const Text('Resolve'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
