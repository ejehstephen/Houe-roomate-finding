import 'package:camp_nest/core/service/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminVerificationsTab extends StatefulWidget {
  const AdminVerificationsTab({super.key});

  @override
  State<AdminVerificationsTab> createState() => _AdminVerificationsTabState();
}

class _AdminVerificationsTabState extends State<AdminVerificationsTab> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _adminService.getPendingVerifications();
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(String id) async {
    try {
      await _adminService.approveVerification(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification approved!')));
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectRequest(String id) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Verification'),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g., Unclear image, mismatched name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, reasonController.text),
                child: const Text('Reject'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _adminService.rejectVerification(id, result);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verification rejected.')));
        _loadRequests();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verification Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _detailItem('Name', request['full_name']),
                    _detailItem('NIN', request['nin_number']),
                    _detailItem(
                      'DOB',
                      DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(request['date_of_birth'])),
                    ),
                    _detailItem('Doc Type', request['document_type']),
                    const SizedBox(height: 16),
                    const Text(
                      'Front Image:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildImage(request['front_image_url']), // This is a PATH
                    if (request['back_image_url'] != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Back Image:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildImage(request['back_image_url']),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectRequest(request['id']);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveRequest(request['id']);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Helper because image URL in DB is a private path
  // We need to construct a signed URL or public URL depending on bucket settings
  // Since we set it to private in planning, we need signed URL.
  // But for now, let's assume public URL via getPublicUrl for simplicity
  // OR use a utility from Supabase to get signed URL.
  // Given I don't have a helper for signed URL in simple admin service easily available without ref,
  // I'll try to use a standard Image widget with a likely public URL structure OR
  // if I can get the client.
  // Actually, AdminService has the client but it's private.
  // I should probably expose a method in AdminService to get image URL.
  //
  // UPDATE: I will use a placeholder or assume public access logic for now,
  // but ideally I'd fix AdminService to sign URLs.
  // Let's assume I can construct the public URL:
  // ${supabaseUrl}/storage/v1/object/public/verification_docs/${path}
  //
  // WAIT: The path in DB IS the path.
  // I'll assume public access for admin view for now or standard RLS.
  // `Image.network` works if the bucket is public or I have a token.
  // Since it's private bucket, `Image.network` will 403.
  //
  // FIX: I will just display the PATH text for now and a note,
  // or I need to add `getSignedUrl` to AdminService.
  // Let's add `getSignedUrl` to AdminService quickly? No, I can't edit it easily now.
  // I'll use a FutureBuilder with a local Supabase client instant to get signed URL.

  Widget _buildImage(String path) {
    return FutureBuilder<String>(
      future: AdminService().getSignedUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Text('Error loading image')),
          );
        }
        final url = snapshot.data!;
        return Column(
          children: [
            Image.network(
              url,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Text('Failed to load image'),
            ),
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Save Image'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending verification requests',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text(request['full_name']),
            subtitle: Text(
              'Submitted: ${DateFormat('MMM d, y').format(DateTime.parse(request['created_at']))}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDetails(request),
          ),
        );
      },
    );
  }
}
