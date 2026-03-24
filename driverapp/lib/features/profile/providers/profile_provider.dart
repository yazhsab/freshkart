import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_delivery/core/api/api_client.dart';
import 'package:freshkart_delivery/core/api/api_endpoints.dart';
import 'package:freshkart_delivery/core/models/agent_model.dart';

class ProfileState {
  final AgentModel? agent;
  final bool isLoading;
  final String? error;

  const ProfileState({this.agent, this.isLoading = false, this.error});

  ProfileState copyWith({
    AgentModel? agent,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAgent = false,
  }) {
    return ProfileState(
      agent: clearAgent ? null : (agent ?? this.agent),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;

  ProfileNotifier(this._apiClient) : super(const ProfileState());

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.get(ApiEndpoints.agentProfile);
      final data = response.data;
      final agentJson = data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>? ?? data)
          : data as Map<String, dynamic>;
      final agent = AgentModel.fromJson(agentJson);
      state = state.copyWith(agent: agent, isLoading: false);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to fetch profile';
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.agentProfile,
        data: data,
      );
      final responseData = response.data;
      final agentJson = responseData is Map<String, dynamic>
          ? (responseData['data'] as Map<String, dynamic>? ?? responseData)
          : responseData as Map<String, dynamic>;
      final agent = AgentModel.fromJson(agentJson);
      state = state.copyWith(agent: agent, isLoading: false);
      return true;
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to update profile';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadDocument(String type, String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final formData = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '${type}_doc.jpg',
        ),
      });
      final response = await _apiClient.upload(
        '${ApiEndpoints.agentProfile}/documents',
        formData: formData,
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final agent = AgentModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        state = state.copyWith(agent: agent, isLoading: false);
      } else {
        await fetchProfile();
      }
      return true;
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to upload document';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitSupportTicket({
    required String category,
    required String description,
    String? screenshotPath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (screenshotPath != null) {
        final formData = FormData.fromMap({
          'category': category,
          'description': description,
          'screenshot': await MultipartFile.fromFile(
            screenshotPath,
            filename: 'screenshot.jpg',
          ),
        });
        await _apiClient.upload(ApiEndpoints.supportTicket, formData: formData);
      } else {
        await _apiClient.post(
          ApiEndpoints.supportTicket,
          data: {'category': category, 'description': description},
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to submit ticket';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ApiClient.instance);
});
