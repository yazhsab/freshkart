import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/service_category_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/storage/local_storage.dart';

class HomeState {
  final Position? userLocation;
  final String? city;
  final List<VendorModel> nearbyVendors;
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts;
  final List<ServiceCategoryModel> serviceCategories;
  final bool isLoadingLocation;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.userLocation,
    this.city,
    this.nearbyVendors = const [],
    this.categories = const [],
    this.featuredProducts = const [],
    this.serviceCategories = const [],
    this.isLoadingLocation = false,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    Position? userLocation,
    String? city,
    List<VendorModel>? nearbyVendors,
    List<CategoryModel>? categories,
    List<ProductModel>? featuredProducts,
    List<ServiceCategoryModel>? serviceCategories,
    bool? isLoadingLocation,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      userLocation: userLocation ?? this.userLocation,
      city: city ?? this.city,
      nearbyVendors: nearbyVendors ?? this.nearbyVendors,
      categories: categories ?? this.categories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  final _api = ApiClient();

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, isLoadingLocation: true);

    // Try to restore saved location first
    final savedLat = LocalStorage.getDouble(LocalStorage.kSavedLat);
    final savedLng = LocalStorage.getDouble(LocalStorage.kSavedLng);
    final savedCity = LocalStorage.getString(LocalStorage.kSavedCity);

    double lat = savedLat ?? AppConfig.defaultLatitude;
    double lng = savedLng ?? AppConfig.defaultLongitude;
    String city = savedCity ?? AppConfig.defaultCity;

    // Attempt GPS location
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;

        // Save location
        await LocalStorage.setDouble(LocalStorage.kSavedLat, lat);
        await LocalStorage.setDouble(LocalStorage.kSavedLng, lng);

        state = state.copyWith(
          userLocation: position,
          isLoadingLocation: false,
        );

        // Reverse geocode for city name
        try {
          final address = await LocationService.getAddressFromCoords(lat, lng);
          city = _extractCity(address);
          await LocalStorage.setString(LocalStorage.kSavedCity, city);
        } catch (e) {
          debugPrint('HomeNotifier: Reverse geocode failed – $e');
        }
      }
    } catch (e) {
      debugPrint('HomeNotifier: Location fetch failed – $e');
    }

    state = state.copyWith(city: city, isLoadingLocation: false);

    // Fetch data in parallel
    await Future.wait([
      _fetchNearbyVendors(lat, lng),
      _fetchCategories(),
      _fetchFeaturedProducts(lat, lng),
      _fetchServiceCategories(),
    ]);

    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshLocation() async {
    state = state.copyWith(isLoadingLocation: true);

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final lat = position.latitude;
        final lng = position.longitude;

        await LocalStorage.setDouble(LocalStorage.kSavedLat, lat);
        await LocalStorage.setDouble(LocalStorage.kSavedLng, lng);

        state = state.copyWith(
          userLocation: position,
          isLoadingLocation: false,
        );

        // Reverse geocode
        try {
          final address = await LocationService.getAddressFromCoords(lat, lng);
          final city = _extractCity(address);
          await LocalStorage.setString(LocalStorage.kSavedCity, city);
          state = state.copyWith(city: city);
        } catch (_) {}

        // Re-fetch vendors with new location
        await _fetchNearbyVendors(lat, lng);
        await _fetchFeaturedProducts(lat, lng);
      } else {
        state = state.copyWith(isLoadingLocation: false);
      }
    } catch (e) {
      debugPrint('HomeNotifier: refreshLocation failed – $e');
      state = state.copyWith(isLoadingLocation: false);
    }
  }

  Future<void> _fetchNearbyVendors(double lat, double lng) async {
    try {
      final response = await _api.get(
        ApiEndpoints.nearbyVendors,
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': AppConfig.defaultDeliveryRadiusKm,
        },
      );

      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['vendors'] as List?) ?? [];
      final vendors = list
          .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(nearbyVendors: vendors);
    } catch (e) {
      debugPrint('HomeNotifier: Failed to fetch nearby vendors – $e');
      state = state.copyWith(error: 'Failed to load nearby stores');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _api.get(ApiEndpoints.groceryCategories);

      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['categories'] as List?) ?? [];
      final categories = list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(categories: categories);
    } catch (e) {
      debugPrint('HomeNotifier: Failed to fetch categories – $e');
    }
  }

  Future<void> _fetchFeaturedProducts(double lat, double lng) async {
    try {
      final response = await _api.get(
        ApiEndpoints.searchProducts,
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'featured': true,
          'limit': 20,
        },
      );

      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['products'] as List?) ?? [];
      final products = list
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(featuredProducts: products);
    } catch (e) {
      debugPrint('HomeNotifier: Failed to fetch featured products – $e');
    }
  }

  Future<void> _fetchServiceCategories() async {
    try {
      final response = await _api.get(ApiEndpoints.serviceCategories);

      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['services'] as List?) ?? [];
      final services = list
          .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(serviceCategories: services);
    } catch (e) {
      debugPrint('HomeNotifier: Failed to fetch service categories – $e');
    }
  }

  String _extractCity(String address) {
    // Try to extract city from comma-separated address
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return parts.isNotEmpty ? parts.first : AppConfig.defaultCity;
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
