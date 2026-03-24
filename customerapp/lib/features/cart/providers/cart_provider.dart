import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/models/cart_item_model.dart';
import 'package:freshkart_customer/core/models/product_model.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';

class CartState {
  final Map<String, CartItemModel> items;
  final String? vendorId;
  final String? vendorName;

  const CartState({this.items = const {}, this.vendorId, this.vendorName});

  int get itemCount => items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee =>
      subtotal >= AppConfig.deliveryFeeThreshold ? 0 : AppConfig.deliveryFee;

  double get total => subtotal + deliveryFee;

  List<CartItemModel> get itemsList => items.values.toList();

  // Backward-compatible helpers
  int get totalItems => itemCount;

  int quantityOf(String productId) {
    return items[productId]?.quantity ?? 0;
  }

  bool containsProduct(String productId) => items.containsKey(productId);

  CartState copyWith({
    Map<String, CartItemModel>? items,
    String? vendorId,
    String? vendorName,
    bool clearVendor = false,
  }) {
    return CartState(
      items: items ?? this.items,
      vendorId: clearVendor ? null : (vendorId ?? this.vendorId),
      vendorName: clearVendor ? null : (vendorName ?? this.vendorName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((key, value) => MapEntry(key, value.toJson())),
      'vendor_id': vendorId,
      'vendor_name': vendorName,
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    Map<String, CartItemModel> items = {};

    if (rawItems is Map<String, dynamic>) {
      items = rawItems.map(
        (key, value) => MapEntry(
          key,
          CartItemModel.fromJson(value as Map<String, dynamic>),
        ),
      );
    } else if (rawItems is List) {
      // Backward compat: old format stored items as a list
      for (final e in rawItems) {
        final item = CartItemModel.fromJson(e as Map<String, dynamic>);
        items[item.product.id] = item;
      }
    }

    return CartState(
      items: items,
      vendorId: json['vendor_id'] as String?,
      vendorName: json['vendor_name'] as String?,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState()) {
    loadSavedCart();
  }

  /// Adds a product to cart. Checks for vendor conflict.
  /// Returns false if there is a vendor conflict (cart has items from another vendor).
  bool addItem(ProductModel product, {int qty = 1}) {
    // Check vendor conflict
    if (state.vendorId != null &&
        state.vendorId != product.vendorId &&
        state.items.isNotEmpty) {
      return false;
    }

    final existing = state.items[product.id];
    final newQty = existing != null
        ? (existing.quantity + qty).clamp(1, AppConfig.maxCartItemsPerProduct)
        : qty.clamp(1, AppConfig.maxCartItemsPerProduct);

    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems[product.id] = CartItemModel(
      product: product,
      quantity: newQty,
      vendorId: product.vendorId,
    );

    state = state.copyWith(items: updatedItems, vendorId: product.vendorId);
    _persist();
    return true;
  }

  void removeItem(String productId) {
    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems.remove(productId);

    if (updatedItems.isEmpty) {
      state = state.copyWith(items: updatedItems, clearVendor: true);
    } else {
      state = state.copyWith(items: updatedItems);
    }
    _persist();
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }

    final existing = state.items[productId];
    if (existing == null) return;

    final clampedQty = qty.clamp(1, AppConfig.maxCartItemsPerProduct);
    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems[productId] = existing.copyWith(quantity: clampedQty);

    state = state.copyWith(items: updatedItems);
    _persist();
  }

  void clearCart() {
    state = const CartState();
    _clearPersisted();
  }

  /// Sets vendor name for display in cart.
  void setVendorName(String name) {
    state = state.copyWith(vendorName: name);
    _persist();
  }

  Future<void> loadSavedCart() async {
    final raw = LocalStorage.getString(LocalStorage.kCartData);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          state = CartState.fromJson(decoded);
        } else if (decoded is List) {
          // Backward compat: old format stored items as a list
          final items = <String, CartItemModel>{};
          for (final e in decoded) {
            final item = CartItemModel.fromJson(e as Map<String, dynamic>);
            items[item.product.id] = item;
          }
          final vendorId = items.isNotEmpty
              ? items.values.first.vendorId
              : null;
          state = CartState(items: items, vendorId: vendorId);
        }
      } catch (_) {
        // Corrupted data, start fresh
        _clearPersisted();
      }
    }
  }

  void _persist() {
    final json = jsonEncode(state.toJson());
    LocalStorage.setString(LocalStorage.kCartData, json);
  }

  void _clearPersisted() {
    LocalStorage.remove(LocalStorage.kCartData);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
