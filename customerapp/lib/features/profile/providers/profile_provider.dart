import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/user_model.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
      return ProfileNotifier(ApiClient());
    });

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ApiClient _api;

  ProfileNotifier(this._api) : super(const AsyncLoading()) {
    fetchProfile();
  }

  /// Fetches the current user's profile from GET /auth/profile.
  Future<void> fetchProfile() async {
    try {
      state = const AsyncLoading();
      final response = await _api.get(ApiEndpoints.profile);
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates the user's name and email via PUT /auth/profile.
  Future<void> updateProfile({required String name, String? email}) async {
    try {
      final previous = state;
      state = const AsyncLoading();

      final body = <String, dynamic>{'full_name': name};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }

      final response = await _api.put(ApiEndpoints.profile, data: body);
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Uploads a new avatar image via multipart POST to /auth/profile.
  Future<void> uploadAvatar(File imageFile) async {
    try {
      state = const AsyncLoading();

      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _api.postFormData(
        ApiEndpoints.profile,
        formData: formData,
      );
      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
