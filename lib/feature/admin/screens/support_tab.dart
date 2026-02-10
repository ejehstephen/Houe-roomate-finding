import 'package:flutter/material.dart';

class AdminSupportTab extends StatelessWidget {
  const AdminSupportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.headset_mic, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Support Tickets',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Support ticket management system is coming soon.'),
        ],
      ),
    );
  }
}
