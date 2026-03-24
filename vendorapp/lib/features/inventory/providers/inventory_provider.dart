import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/models/product_model.dart';
import 'package:freshkart_vendor/core/models/category_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class InventoryState {
  final List<ProductModel> products;
  final List<ProductModel> filteredProducts;
  final String searchQuery;
  final String? selectedCategoryId;
  final String sortBy; // 'name' | 'stock' | 'price' | 'sales'
  final bool isLoading;
  final String? error;

  const InventoryState({
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.sortBy = 'name',
    this.isLoading = false,
    this.error,
  });

  int get totalCount => products.length;

  int get availableCount =>
      products.where((p) => p.isAvailable && p.isInStock).length;

  int get lowStockCount => products.where((p) => p.isLowStock).length;

  int get outOfStockCount => products.where((p) => p.stockQuantity == 0).length;

  InventoryState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filteredProducts,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategoryFilter = false,
    String? sortBy,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InventoryState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryFilter
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState());

  final _api = ApiClient.instance;

  // ---- Fetch products -----------------------------------------------------

  Future<void> fetchProducts(String vendorId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get(
        VendorApiEndpoints.products,
        queryParameters: {'vendor_id': vendorId},
      );
      final data = response.data['data'] as List? ?? [];
      final products = data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(products: products, isLoading: false);
      _applyFiltersAndSort();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---- Stock update (optimistic) ------------------------------------------

  Future<void> updateStock(String productId, int newQty) async {
    final previousProducts = List<ProductModel>.from(state.products);
    final index = state.products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    // Optimistic update
    final updated = state.products[index].copyWith(stockQuantity: newQty);
    final newProducts = List<ProductModel>.from(state.products);
    newProducts[index] = updated;
    state = state.copyWith(products: newProducts);
    _applyFiltersAndSort();

    try {
      await _api.patch(
        VendorApiEndpoints.productStock(productId),
        data: {'stock_quantity': newQty},
      );
    } catch (e) {
      // Rollback
      state = state.copyWith(products: previousProducts);
      _applyFiltersAndSort();
      state = state.copyWith(error: 'Failed to update stock: $e');
    }
  }

  // ---- Toggle availability (optimistic) -----------------------------------

  Future<void> toggleAvailability(String productId, bool isAvailable) async {
    final previousProducts = List<ProductModel>.from(state.products);
    final index = state.products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    // Optimistic update
    final updated = state.products[index].copyWith(isAvailable: isAvailable);
    final newProducts = List<ProductModel>.from(state.products);
    newProducts[index] = updated;
    state = state.copyWith(products: newProducts);
    _applyFiltersAndSort();

    try {
      await _api.patch(
        VendorApiEndpoints.productAvailability(productId),
        data: {'is_available': isAvailable},
      );
    } catch (e) {
      // Rollback
      state = state.copyWith(products: previousProducts);
      _applyFiltersAndSort();
      state = state.copyWith(error: 'Failed to update availability: $e');
    }
  }

  // ---- Delete product -----------------------------------------------------

  Future<void> deleteProduct(String productId) async {
    final previousProducts = List<ProductModel>.from(state.products);

    final newProducts = state.products.where((p) => p.id != productId).toList();
    state = state.copyWith(products: newProducts);
    _applyFiltersAndSort();

    try {
      await _api.delete(VendorApiEndpoints.productById(productId));
    } catch (e) {
      // Rollback
      state = state.copyWith(products: previousProducts);
      _applyFiltersAndSort();
      state = state.copyWith(error: 'Failed to delete product: $e');
    }
  }

  // ---- Search -------------------------------------------------------------

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSort();
  }

  // ---- Filter by category -------------------------------------------------

  void filterByCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    _applyFiltersAndSort();
  }

  // ---- Sort products ------------------------------------------------------

  void sortProducts(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _applyFiltersAndSort();
  }

  // ---- Add product --------------------------------------------------------

  Future<void> addProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(VendorApiEndpoints.products, data: data);
      final product = ProductModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      final newProducts = [product, ...state.products];
      state = state.copyWith(products: newProducts, isLoading: false);
      _applyFiltersAndSort();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add product: $e',
      );
    }
  }

  // ---- Update product -----------------------------------------------------

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.put(
        VendorApiEndpoints.productById(id),
        data: data,
      );
      final updatedProduct = ProductModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      final newProducts = state.products.map((p) {
        return p.id == id ? updatedProduct : p;
      }).toList();
      state = state.copyWith(products: newProducts, isLoading: false);
      _applyFiltersAndSort();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update product: $e',
      );
    }
  }

  // ---- Filter by stock status (for tappable stat cards) -------------------

  void filterByStockStatus(String? status) {
    // status: null (all), 'available', 'low_stock', 'out_of_stock'
    List<ProductModel> filtered;
    switch (status) {
      case 'available':
        filtered = state.products
            .where((p) => p.isAvailable && p.isInStock)
            .toList();
        break;
      case 'low_stock':
        filtered = state.products.where((p) => p.isLowStock).toList();
        break;
      case 'out_of_stock':
        filtered = state.products.where((p) => p.stockQuantity == 0).toList();
        break;
      default:
        filtered = List<ProductModel>.from(state.products);
    }
    state = state.copyWith(filteredProducts: filtered);
  }

  // ---- Private: apply filters and sort ------------------------------------

  void _applyFiltersAndSort() {
    var filtered = List<ProductModel>.from(state.products);

    // Search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.nameTamil?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Category filter
    if (state.selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p.categoryId == state.selectedCategoryId)
          .toList();
    }

    // Sort
    switch (state.sortBy) {
      case 'name':
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'stock':
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'sales':
        // Sort by name descending as fallback when sales data not in model
        filtered.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
    }

    state = state.copyWith(filteredProducts: filtered);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier();
    });

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final response = await ApiClient.instance.get(
    VendorApiEndpoints.groceryCategories,
  );
  final data = response.data['data'] as List? ?? [];
  return data
      .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
      .toList();
});
