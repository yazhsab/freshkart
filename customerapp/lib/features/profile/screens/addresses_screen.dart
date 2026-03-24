import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';

// ── Address Provider ──

final addressProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((
      ref,
    ) {
      return AddressNotifier(ApiClient());
    });

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final ApiClient _api;

  AddressNotifier(this._api) : super(const AsyncLoading()) {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    try {
      state = const AsyncLoading();
      final response = await _api.get(ApiEndpoints.addresses);
      final data = response.data as Map<String, dynamic>;
      final list = (data['addresses'] as List<dynamic>)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _api.delete(ApiEndpoints.addressById(id));
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((a) => a.id != id).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ── Addresses Screen ──

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: addressState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load addresses',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved addresses',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add an address to get started',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(address: address);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/addresses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add New Address'),
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final AddressModel address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullAddress =
        '${address.flatNo}, ${address.area}, ${address.city}, ${address.state} - ${address.pincode}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Label badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    address.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Default badge
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                const Spacer(),

                // Edit icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    // Navigate to edit address (reuse add screen with id)
                    context.push('/profile/addresses/add', extra: address);
                  },
                ),

                // Delete icon
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Full address text
            Text(
              fullAddress,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(addressProvider.notifier).deleteAddress(address.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
