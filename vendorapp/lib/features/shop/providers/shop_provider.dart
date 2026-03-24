import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/models/vendor_model.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ShopNotifier extends StateNotifier<AsyncValue<VendorModel?>> {
  ShopNotifier() : super(const AsyncValue.loading()) {
    fetchShop();
  }

  final _api = ApiClient.instance;

  /// GET /vendors/me
  Future<void> fetchShop() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get(VendorApiEndpoints.vendorMe);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);
      final vendor = VendorModel.fromJson(data);
      await LocalStorage.instance.saveVendorId(vendor.id);
      state = AsyncValue.data(vendor);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// PUT /vendors/me — general update
  Future<void> updateShop(Map<String, dynamic> data) async {
    try {
      final response = await _api.put(VendorApiEndpoints.vendorMe, data: data);
      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);
      final vendor = VendorModel.fromJson(resData);
      state = AsyncValue.data(vendor);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// POST /vendors/me/docs — upload FSSAI/GSTIN documents via FormData
  Future<void> uploadDocs({
    File? fssaiFile,
    File? gstinFile,
    File? cancelledChequeFile,
  }) async {
    final formData = FormData();

    if (fssaiFile != null) {
      formData.files.add(
        MapEntry(
          'fssai_doc',
          await MultipartFile.fromFile(
            fssaiFile.path,
            filename:
                'fssai_${DateTime.now().millisecondsSinceEpoch}.${fssaiFile.path.split('.').last}',
          ),
        ),
      );
    }

    if (gstinFile != null) {
      formData.files.add(
        MapEntry(
          'gstin_doc',
          await MultipartFile.fromFile(
            gstinFile.path,
            filename:
                'gstin_${DateTime.now().millisecondsSinceEpoch}.${gstinFile.path.split('.').last}',
          ),
        ),
      );
    }

    if (cancelledChequeFile != null) {
      formData.files.add(
        MapEntry(
          'cancelled_cheque',
          await MultipartFile.fromFile(
            cancelledChequeFile.path,
            filename:
                'cheque_${DateTime.now().millisecondsSinceEpoch}.${cancelledChequeFile.path.split('.').last}',
          ),
        ),
      );
    }

    try {
      await _api.postFormData(
        VendorApiEndpoints.vendorDocs,
        formData: formData,
      );
      await fetchShop();
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /vendors/me/toggle-open
  Future<void> toggleOpen() async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    // Optimistic update
    state = AsyncValue.data(previous.copyWith(isOpen: !previous.isOpen));

    try {
      await _api.patch(VendorApiEndpoints.vendorToggleOpen);
    } catch (e) {
      // Rollback on failure
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  /// PUT /vendors/me — bank details
  Future<void> updateBankDetails(Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
        VendorApiEndpoints.vendorMe,
        data: {
          'bank_account_holder': data['bank_account_holder'],
          'bank_account_number': data['bank_account_number'],
          'bank_ifsc': data['bank_ifsc'],
          'bank_account_type': data['bank_account_type'],
        },
      );
      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);
      final vendor = VendorModel.fromJson(resData);
      state = AsyncValue.data(vendor);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// PUT /vendors/me — working hours
  Future<void> updateWorkingHours(Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
        VendorApiEndpoints.vendorMe,
        data: {
          'opening_time': data['opening_time'],
          'closing_time': data['closing_time'],
          'working_days': data['working_days'],
        },
      );
      final resData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);
      final vendor = VendorModel.fromJson(resData);
      state = AsyncValue.data(vendor);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final shopProvider =
    StateNotifierProvider<ShopNotifier, AsyncValue<VendorModel?>>((ref) {
      return ShopNotifier();
    });
