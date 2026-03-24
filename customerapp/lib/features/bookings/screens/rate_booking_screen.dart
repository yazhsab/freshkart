import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/booking_model.dart';

/// Fetches a single booking by ID for the rating screen.
final _bookingForRatingProvider = FutureProvider.family<BookingModel, String>((
  ref,
  bookingId,
) async {
  final response = await ApiClient().get(ApiEndpoints.bookingById(bookingId));
  final data = response.data as Map<String, dynamic>;
  return BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
});

class RateBookingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RateBookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RateBookingScreen> createState() => _RateBookingScreenState();
}

class _RateBookingScreenState extends ConsumerState<RateBookingScreen> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _wouldRebook = true;
  bool _isSubmitting = false;

  static const _feedbackChips = [
    'Skilled',
    'On time',
    'Polite',
    'Clean work',
    'Reasonable price',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(_bookingForRatingProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Service'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: bookingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) => _buildBody(context, booking),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingModel booking) {
    final worker = booking.worker;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(
          child: Text(
            'How was the service?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),

        // Worker info
        if (worker != null) ...[
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[300],
                  child: worker.profile?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            worker.profile!.avatarUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  worker.profile?.fullName ?? 'Worker',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Star rating
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    size: 44,
                    color: Colors.amber[600],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _ratingLabel,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),

        // Feedback chips
        const Text(
          'What went well?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _feedbackChips.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              selectedColor: Colors.amber[100],
              checkmarkColor: Colors.amber[800],
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.amber[400]! : Colors.grey[300]!,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Comment
        const Text(
          'Additional comments (optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Would you rebook?
        const Text(
          'Would you rebook this worker?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _wouldRebook = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _wouldRebook ? Colors.green[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _wouldRebook
                          ? Colors.green[400]!
                          : Colors.grey[300]!,
                      width: _wouldRebook ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 20,
                          color: _wouldRebook
                              ? Colors.green[600]
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _wouldRebook
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _wouldRebook = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_wouldRebook ? Colors.red[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_wouldRebook
                          ? Colors.red[400]!
                          : Colors.grey[300]!,
                      width: !_wouldRebook ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thumb_down,
                          size: 20,
                          color: !_wouldRebook
                              ? Colors.red[600]
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_wouldRebook
                                ? Colors.red[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_rating > 0 && !_isSubmitting) ? _submitReview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Below Average';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      final tags = _selectedTags.toList();
      final comment = [
        if (tags.isNotEmpty) 'Tags: ${tags.join(', ')}',
        if (_commentController.text.isNotEmpty) _commentController.text,
        'Would rebook: ${_wouldRebook ? 'Yes' : 'No'}',
      ].join('\n');

      await ApiClient().post(
        ApiEndpoints.reviews,
        data: {
          'booking_id': widget.bookingId,
          'rating': _rating,
          'comment': comment,
          'target_type': 'worker',
          'would_rebook': _wouldRebook,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! Thank you.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
