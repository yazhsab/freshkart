import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/address_provider.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Address'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Failed to load addresses'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(addressProvider.notifier).fetchAddresses(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved addresses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add an address for delivery',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/profile/addresses/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected = selectedAddress?.id == address.id;

                    return _AddressCard(
                      address: address,
                      isSelected: isSelected,
                      onSelect: () {
                        ref.read(selectedAddressProvider.notifier).state =
                            address;
                      },
                      onEdit: () => context.push(
                        '/profile/addresses/add',
                        extra: address,
                      ),
                      onDelete: () => _confirmDelete(context, ref, address),
                      onSetDefault: () => ref
                          .read(addressProvider.notifier)
                          .setDefault(address.id),
                    );
                  },
                ),
              ),

              // Add new address button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/profile/addresses/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Address'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
          'Remove "${address.label}" address at ${address.flatNo}, ${address.area}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(addressProvider.notifier).deleteAddress(address.id);
              // Clear selected if this was selected
              if (ref.read(selectedAddressProvider)?.id == address.id) {
                ref.read(selectedAddressProvider.notifier).state = null;
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Radio indicator
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(width: 10),

                  // Label badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _labelColor(address.label).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      address.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _labelColor(address.label),
                      ),
                    ),
                  ),

                  // Default badge
                  if (address.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                        case 'default':
                          onSetDefault();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!address.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set as Default'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  '${address.flatNo}, ${address.area}, ${address.city}, ${address.state} - ${address.pincode}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _labelColor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return AppColors.primaryGreen;
      case 'work':
        return AppColors.info;
      default:
        return AppColors.primaryAmber;
    }
  }
}
