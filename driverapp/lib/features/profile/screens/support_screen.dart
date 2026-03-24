import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/profile/providers/profile_provider.dart';
import 'package:freshkart_delivery/features/shared/widgets/app_button.dart';
import 'package:freshkart_delivery/features/shared/widgets/app_text_field.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Payment issue';
  String? _screenshotPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Payment issue',
    'App bug',
    'Customer complaint',
    'Other',
  ];

  final List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'How are deliveries assigned?',
      answer:
          'Deliveries are assigned based on your proximity to the pickup location, your current availability status, and your delivery performance rating. When you are online, the system automatically finds the nearest available agent for each order. You will receive a notification with order details and have a limited time to accept or reject the delivery.',
    ),
    _FaqItem(
      question: 'When will I get paid?',
      answer:
          'Earnings are calculated daily and settlements are processed weekly, every Monday. The amount is transferred directly to your registered bank account. You can view your earnings breakdown in the Earnings section. For any discrepancies, please raise a support ticket under the "Payment issue" category.',
    ),
    _FaqItem(
      question: 'What if customer is not available?',
      answer:
          'If the customer is not available at the delivery location, try calling them using the in-app call button. Wait for 5 minutes at the location. If the customer is still unreachable, mark the delivery as "Customer unavailable" in the app. The order will be returned and you will receive the delivery fee for the trip. Do not leave the order unattended.',
    ),
    _FaqItem(
      question: 'How to improve my rating?',
      answer:
          'To improve your rating: 1) Always be polite and professional with customers. 2) Deliver orders on time or before the estimated time. 3) Handle food and grocery items carefully to avoid damage. 4) Keep your vehicle clean. 5) Follow the delivery instructions provided by the customer. 6) Communicate proactively if there are any delays.',
    ),
    _FaqItem(
      question: 'How to update bank account?',
      answer:
          'For security reasons, bank account details can only be updated by contacting our support team. Please call support during working hours (9 AM - 9 PM) or raise a support ticket with the category "Payment issue". You will need to verify your identity before the change is processed. Bank account changes typically take 2-3 business days to reflect.',
    ),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickScreenshot() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _screenshotPath = image.path;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(profileProvider.notifier)
        .submitSupportTicket(
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          screenshotPath: _screenshotPath,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Support ticket submitted successfully',
              style: GoogleFonts.notoSans(),
            ),
            backgroundColor: DeliveryColors.online,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _descriptionController.clear();
        setState(() {
          _screenshotPath = null;
          _selectedCategory = 'Payment issue';
        });
      } else {
        final error = ref.read(profileProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Failed to submit ticket',
              style: GoogleFonts.notoSans(),
            ),
            backgroundColor: DeliveryColors.newOrder,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: DeliveryColors.surface,
        foregroundColor: DeliveryColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('FREQUENTLY ASKED QUESTIONS'),
          const SizedBox(height: 8),
          _buildFaqSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('CONTACT US'),
          const SizedBox(height: 8),
          _buildContactOptions(),
          const SizedBox(height: 24),
          _buildSectionHeader('REPORT AN ISSUE'),
          const SizedBox(height: 8),
          _buildIssueForm(state.isLoading),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DeliveryColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        children: _faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return Column(
            children: [
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: DeliveryColors.primary,
                ),
                title: Text(
                  faq.question,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                children: [
                  Text(
                    faq.answer,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              if (index < _faqItems.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactOptions() {
    return Container(
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DeliveryColors.online.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.phone,
                size: 20,
                color: DeliveryColors.online,
              ),
            ),
            title: Text(
              'Call Support',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: DeliveryColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '9 AM - 9 PM, Mon-Sat',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: DeliveryColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: DeliveryColors.textSecondary,
              size: 20,
            ),
            onTap: () => _launchUrl('tel:+911800123456'),
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat, size: 20, color: Color(0xFF25D366)),
            ),
            title: Text(
              'WhatsApp',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: DeliveryColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Quick responses, 24/7',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: DeliveryColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: DeliveryColors.textSecondary,
              size: 20,
            ),
            onTap: () => _launchUrl(
              'https://wa.me/911800123456?text=Hi,%20I%20need%20help%20with%20FreshKart%20Delivery',
            ),
          ),
          const Divider(height: 1, indent: 72, endIndent: 16),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DeliveryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 20,
                color: DeliveryColors.primary,
              ),
            ),
            title: Text(
              'Email',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: DeliveryColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'delivery-support@freshkart.in',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: DeliveryColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: DeliveryColors.textSecondary,
              size: 20,
            ),
            onTap: () => _launchUrl('mailto:delivery-support@freshkart.in'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: DeliveryColors.divider),
                borderRadius: BorderRadius.circular(12),
                color: DeliveryColors.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: DeliveryColors.textSecondary,
                  ),
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    color: DeliveryColors.textPrimary,
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your issue in detail...',
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your issue';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Screenshot (optional)',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: DeliveryColors.divider,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: DeliveryColors.background,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _screenshotPath != null
                          ? Icons.check_circle
                          : Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: _screenshotPath != null
                          ? DeliveryColors.online
                          : DeliveryColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _screenshotPath != null
                          ? 'Screenshot attached'
                          : 'Attach screenshot',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: _screenshotPath != null
                            ? DeliveryColors.online
                            : DeliveryColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_screenshotPath != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _screenshotPath = null),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: DeliveryColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Submit',
              onPressed: _submitTicket,
              isLoading: isLoading,
              fullWidth: true,
              color: DeliveryColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
