import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'question': 'How do I place an order?',
      'answer':
          'Browse products from nearby vendors on the Home tab. Add items to your cart, choose a delivery address, select your preferred payment method, and confirm your order. You will receive real-time updates on your order status.',
    },
    {
      'question': 'How do I track my delivery?',
      'answer':
          'Go to the Orders tab and tap on your active order. You can see the live location of your delivery agent on the map along with the estimated time of arrival.',
    },
    {
      'question': 'How do I book a home service?',
      'answer':
          'Navigate to the Services tab, select the service category you need (e.g., plumbing, electrical, cleaning), choose an available time slot, and confirm your booking. A verified professional will arrive at your location.',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept UPI, credit/debit cards, net banking, and cash on delivery. All online payments are processed securely through our payment partners.',
    },
    {
      'question': 'How do I cancel an order?',
      'answer':
          'You can cancel an order from the Orders tab before it is picked up by the delivery agent. Tap on the order, then tap "Cancel Order". Refunds for prepaid orders are processed within 3-5 business days.',
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'You can reach us via email at support@freshkart.in or call us at +91 44 1234 5678. Our support team is available from 8 AM to 10 PM, 7 days a week.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FAQ Section ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                return ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    Text(
                      faq['answer']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(height: 32),

            // ── Contact Section ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            // Email
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              title: const Text('Email Us'),
              subtitle: const Text('support@freshkart.in'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
              onTap: () => _launchUrl('mailto:support@freshkart.in'),
            ),

            // Phone
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              title: const Text('Call Us'),
              subtitle: const Text('+91 44 1234 5678'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
              onTap: () => _launchUrl('tel:+914412345678'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
