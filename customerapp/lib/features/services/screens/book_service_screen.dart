import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/features/services/providers/booking_provider.dart';
import 'package:freshkart_customer/features/services/providers/services_provider.dart';
import 'package:freshkart_customer/features/services/widgets/slot_grid.dart';

/// Provider to fetch user's saved addresses.
final _addressesProvider = FutureProvider<List<AddressModel>>((ref) async {
  final response = await ApiClient().get(ApiEndpoints.addresses);
  final data = response.data as Map<String, dynamic>;
  final list = data['addresses'] as List<dynamic>;
  return list
      .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class BookServiceScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const BookServiceScreen({super.key, required this.categoryId});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  int _currentStep = 0;
  final _notesController = TextEditingController();

  // Step 2 local state
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    // Set the service category on the booking form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bookingFormProvider.notifier)
          .setServiceCategory(widget.categoryId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(bookingFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _currentStep),
          // Step content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _AddressStep(
                  selectedAddress: formState.serviceAddress,
                  onAddressSelected: (address) {
                    ref.read(bookingFormProvider.notifier).setAddress(address);
                  },
                  onNext: () {
                    if (formState.serviceAddress != null) {
                      _nextStep();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an address'),
                        ),
                      );
                    }
                  },
                ),
                _DateTimeStep(
                  categoryId: widget.categoryId,
                  selectedDate: _selectedDate,
                  selectedSlot: _selectedSlot,
                  notesController: _notesController,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null;
                    });
                  },
                  onSlotSelected: (slot) {
                    setState(() => _selectedSlot = slot);
                    // Calculate end time (1 hour slot)
                    final parts = slot.split(':');
                    final hour = int.parse(parts[0]);
                    final endHour = hour + 1;
                    final end =
                        '${endHour.toString().padLeft(2, '0')}:${parts[1]}';
                    ref
                        .read(bookingFormProvider.notifier)
                        .setSlot(date: _selectedDate!, start: slot, end: end);
                  },
                  onNext: () {
                    if (_selectedDate != null && _selectedSlot != null) {
                      ref
                          .read(bookingFormProvider.notifier)
                          .setNotes(_notesController.text);
                      _nextStep();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select date and time slot'),
                        ),
                      );
                    }
                  },
                  onBack: _prevStep,
                ),
                _ReviewStep(
                  categoryId: widget.categoryId,
                  formState: formState,
                  onPaymentMethodChanged: (method) {
                    ref
                        .read(bookingFormProvider.notifier)
                        .setPaymentMethod(method);
                  },
                  onConfirm: () => _submitBooking(context),
                  onBack: _prevStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking(BuildContext context) async {
    final booking = await ref
        .read(bookingFormProvider.notifier)
        .submitBooking();
    if (booking != null && mounted) {
      ref.read(bookingFormProvider.notifier).reset();
      context.go('/services/booking-confirmation/${booking.id}');
    } else {
      final error = ref.read(bookingFormProvider).error;
      if (mounted && error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking failed: $error')));
      }
    }
  }
}

// -- Step Indicator --

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Address', 'Date & Time', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? Colors.amber[700] : Colors.grey[300],
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.amber[700] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: index < currentStep
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? Colors.amber[700] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (index < 2 && index > 0) const SizedBox(),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// -- Step 1: Address --

class _AddressStep extends ConsumerWidget {
  final AddressModel? selectedAddress;
  final ValueChanged<AddressModel> onAddressSelected;
  final VoidCallback onNext;

  const _AddressStep({
    required this.selectedAddress,
    required this.onAddressSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(_addressesProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select service address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Use current location button
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Get current location and create address
                },
                icon: Icon(Icons.my_location, color: Colors.amber[700]),
                label: Text(
                  'Use current location',
                  style: TextStyle(color: Colors.amber[700]),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amber[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Saved addresses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              addressesAsync.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Text('Error loading addresses: $e'),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('No saved addresses. Add one below.'),
                      ),
                    );
                  }
                  return Column(
                    children: addresses.map((addr) {
                      final isSelected = selectedAddress?.id == addr.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => onAddressSelected(addr),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber[50]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amber[700]!
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  addr.label.toLowerCase() == 'home'
                                      ? Icons.home
                                      : addr.label.toLowerCase() == 'work'
                                      ? Icons.work
                                      : Icons.location_on,
                                  color: isSelected
                                      ? Colors.amber[700]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.amber[800]
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${addr.flatNo}, ${addr.area}, ${addr.city} - ${addr.pincode}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.amber[700],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Add new address
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to add address screen
                },
                icon: const Icon(Icons.add),
                label: const Text('Add new address'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Next button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -- Step 2: Date & Time --

class _DateTimeStep extends ConsumerWidget {
  final String categoryId;
  final DateTime? selectedDate;
  final String? selectedSlot;
  final TextEditingController notesController;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onSlotSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _DateTimeStep({
    required this.categoryId,
    required this.selectedDate,
    required this.selectedSlot,
    required this.notesController,
    required this.onDateSelected,
    required this.onSlotSelected,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final next7Days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Horizontal date chips
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: next7Days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final date = next7Days[index];
                    final isSelected =
                        selectedDate != null &&
                        selectedDate!.year == date.year &&
                        selectedDate!.month == date.month &&
                        selectedDate!.day == date.day;
                    final isToday = index == 0;
                    return GestureDetector(
                      onTap: () => onDateSelected(date),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber[700] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isToday
                                  ? 'Today'
                                  : DateFormat('EEE').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Time slots
              if (selectedDate != null) ...[
                const Text(
                  'Select time slot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSlotsSection(ref),
              ],
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes for the worker (optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., Ring the doorbell, bring specific tools...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsSection(WidgetRef ref) {
    if (selectedDate == null) return const SizedBox.shrink();

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final slotsAsync = ref.watch(
      availableSlotsProvider((categoryId: categoryId, date: dateStr)),
    );

    return slotsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading slots: $e'),
      ),
      data: (slotData) => SlotGrid(
        availableSlots: slotData.availableSlots,
        bookedSlots: slotData.bookedSlots,
        selectedSlot: selectedSlot,
        onSelect: onSlotSelected,
      ),
    );
  }
}

// -- Step 3: Review --

class _ReviewStep extends ConsumerWidget {
  final String categoryId;
  final BookingFormState formState;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const _ReviewStep({
    required this.categoryId,
    required this.formState,
    required this.onPaymentMethodChanged,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Review your booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Summary card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service name
                      categoriesAsync.when(
                        data: (cats) {
                          final cat = cats.firstWhere(
                            (c) => c.id == categoryId,
                            orElse: () => cats.first,
                          );
                          return Row(
                            children: [
                              Icon(Icons.build, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const Divider(height: 24),

                      // Date & Time
                      _SummaryRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: formState.slotDate != null
                            ? DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(formState.slotDate!)
                            : '-',
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.schedule,
                        label: 'Time',
                        value: formState.slotStart != null
                            ? '${formState.slotStart} - ${formState.slotEnd}'
                            : '-',
                      ),
                      const SizedBox(height: 12),

                      // Address
                      _SummaryRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: formState.serviceAddress != null
                            ? '${formState.serviceAddress!.flatNo}, ${formState.serviceAddress!.area}'
                            : '-',
                      ),

                      if (formState.customerNotes != null &&
                          formState.customerNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.notes,
                          label: 'Notes',
                          value: formState.customerNotes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pricing card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        data: (cats) {
                          final cat = cats.firstWhere(
                            (c) => c.id == categoryId,
                            orElse: () => cats.first,
                          );
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Service fee (estimated)'),
                                  Text(
                                    '\u20B9${cat.basePrice.toStringAsFixed(0)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Booking fee'),
                                  Text('\u20B999'),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pay now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '\u20B999',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pay after service',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '\u20B9${cat.basePrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment method
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentOption(
                        icon: Icons.money,
                        label: 'Cash on service',
                        value: 'cash',
                        groupValue: formState.paymentMethod,
                        onChanged: onPaymentMethodChanged,
                      ),
                      _PaymentOption(
                        icon: Icons.account_balance,
                        label: 'UPI',
                        value: 'upi',
                        groupValue: formState.paymentMethod,
                        onChanged: onPaymentMethodChanged,
                      ),
                      _PaymentOption(
                        icon: Icons.credit_card,
                        label: 'Card',
                        value: 'card',
                        groupValue: formState.paymentMethod,
                        onChanged: onPaymentMethodChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Confirm buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: formState.isSubmitting ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.amber[200],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: formState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.amber[700]),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      activeColor: Colors.amber[700],
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
