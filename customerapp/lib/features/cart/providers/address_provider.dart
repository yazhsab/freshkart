import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/address_model.dart';

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressNotifier() : super(const AsyncValue.loading()) {
    fetchAddresses();
  }

  final _api = ApiClient();

  Future<void> fetchAddresses() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get(ApiEndpoints.addresses);
      final addresses = (response.data as List<dynamic>)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AddressModel> addAddress(Map<String, dynamic> data) async {
    final response = await _api.post(ApiEndpoints.addresses, data: data);
    final address = AddressModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    state.whenData((addresses) {
      state = AsyncValue.data([...addresses, address]);
    });
    return address;
  }

  Future<AddressModel> updateAddress(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(ApiEndpoints.addressById(id), data: data);
    final updated = AddressModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    state.whenData((addresses) {
      state = AsyncValue.data(
        addresses.map((a) => a.id == id ? updated : a).toList(),
      );
    });
    return updated;
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete(ApiEndpoints.addressById(id));
    state.whenData((addresses) {
      state = AsyncValue.data(addresses.where((a) => a.id != id).toList());
    });
  }

  Future<void> setDefault(String id) async {
    await _api.put(ApiEndpoints.addressById(id), data: {'is_default': true});
    state.whenData((addresses) {
      state = AsyncValue.data(
        addresses.map((a) {
          if (a.id == id) return a.copyWith(isDefault: true);
          if (a.isDefault) return a.copyWith(isDefault: false);
          return a;
        }).toList(),
      );
    });
  }
}

final addressProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((
      ref,
    ) {
      return AddressNotifier();
    });

final selectedAddressProvider = StateProvider<AddressModel?>((ref) {
  // Auto-select default address when addresses load
  final addresses = ref.watch(addressProvider);
  return addresses.whenOrNull(
    data: (list) {
      final defaults = list.where((a) => a.isDefault);
      return defaults.isNotEmpty ? defaults.first : null;
    },
  );
});
