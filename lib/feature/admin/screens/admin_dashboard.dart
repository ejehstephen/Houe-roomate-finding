import 'package:camp_nest/feature/admin/screens/listings_tab.dart';
import 'package:camp_nest/feature/admin/screens/overview_tab.dart';
import 'package:camp_nest/feature/admin/screens/reports_tab.dart';
import 'package:camp_nest/feature/admin/screens/support_tab.dart';
import 'package:camp_nest/feature/admin/screens/users_tab.dart';
import 'package:camp_nest/feature/admin/screens/verifications_tab.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Listings'),
              Tab(text: 'Reports'),
              Tab(text: 'Support'),
              Tab(text: 'Verifications'),
            ],
          ),
        ),
        body: TabBarView(
          children: const [
            AdminOverviewTab(),
            AdminUsersTab(),
            AdminListingsTab(),
            AdminReportsTab(),
            AdminSupportTab(),
            AdminVerificationsTab(),
          ],
        ),
      ),
    );
  }
}
