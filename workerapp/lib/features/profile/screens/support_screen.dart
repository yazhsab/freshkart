import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/app_text_field.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _issueController = TextEditingController();
  String _selectedIssueType = 'Payment Issue';

  static const _faqs = [
    {
      'q': 'How do I get paid?',
      'a':
          'Earnings are automatically transferred to your bank account every week. You can track your payouts in the Earnings section.',
    },
    {
      'q': 'What is the commission rate?',
      'a':
          'FreshKart charges a 20% commission on each completed job. The remaining 80% is your net earnings.',
    },
    {
      'q': 'How does BGV work?',
      'a':
          'Background Verification includes Aadhaar check, police verification, and address proof. It usually takes 24-48 hours.',
    },
    {
      'q': 'Can I change my service area?',
      'a': 'Yes, contact support to update your service pincodes and city.',
    },
    {
      'q': 'What if a customer cancels?',
      'a':
          'If the customer cancels after you start traveling, you may receive a partial compensation. Check the booking details for specifics.',
    },
    {
      'q': 'How do I handle disputes?',
      'a':
          'Report the issue through the Contact tab. Include the booking ID and describe the problem. Our team will review within 24 hours.',
    },
  ];

  static const _issueTypes = [
    'Payment Issue',
    'Booking Problem',
    'App Bug',
    'Customer Complaint',
    'Document Update',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: WorkerColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: WorkerColors.primary,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_faqTab(), _contactTab(), _reportTab()],
      ),
    );
  }

  Widget _faqTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              _faqs[index]['q']!,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  _faqs[index]['a']!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contactTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _contactCard(
          Icons.phone,
          'Call Support',
          '+91 44 1234 5678',
          () => launchUrl(Uri.parse('tel:+914412345678')),
        ),
        _contactCard(
          Icons.email,
          'Email',
          'worker-support@freshkart.in',
          () => launchUrl(Uri.parse('mailto:worker-support@freshkart.in')),
        ),
        _contactCard(
          Icons.chat,
          'WhatsApp',
          '+91 98765 43210',
          () => launchUrl(Uri.parse('https://wa.me/919876543210')),
        ),
      ],
    );
  }

  Widget _contactCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WorkerColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: WorkerColors.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Issue Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedIssueType,
          items: _issueTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _selectedIssueType = v!),
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Describe your issue',
          hint: 'Please provide details...',
          controller: _issueController,
          maxLines: 5,
          maxLength: 500,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Submit Report',
          icon: Icons.send,
          onPressed: () {
            if (_issueController.text.trim().isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Report submitted. We\'ll get back to you within 24 hours.',
                ),
              ),
            );
            _issueController.clear();
          },
        ),
      ],
    );
  }
}
