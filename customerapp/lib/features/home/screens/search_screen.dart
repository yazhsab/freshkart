import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/vendor_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  late TabController _tabController;

  bool _isSearching = false;
  List<ProductModel> _productResults = [];
  List<VendorModel> _vendorResults = [];
  List<String> _recentSearches = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode.requestFocus();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    final raw = LocalStorage.getString(LocalStorage.kRecentSearches);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _recentSearches = decoded.cast<String>();
        });
      } catch (_) {}
    }
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    final encoded = jsonEncode(_recentSearches);
    LocalStorage.setString(LocalStorage.kRecentSearches, encoded);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: AppConfig.searchDebounceMs), () {
      if (value.trim().isNotEmpty) {
        _performSearch(value.trim());
      } else {
        setState(() {
          _query = '';
          _productResults = [];
          _vendorResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _query = query;
    });

    _saveRecentSearch(query);

    final homeState = ref.read(homeProvider);
    final lat = homeState.userLocation?.latitude ?? AppConfig.defaultLatitude;
    final lng = homeState.userLocation?.longitude ?? AppConfig.defaultLongitude;

    try {
      final api = ApiClient();

      // Search products and vendors in parallel
      final results = await Future.wait([
        api.get(
          ApiEndpoints.searchProducts,
          queryParameters: {'q': query, 'lat': lat, 'lng': lng},
        ),
        api.get(
          ApiEndpoints.nearbyVendors,
          queryParameters: {
            'q': query,
            'lat': lat,
            'lng': lng,
            'radius': AppConfig.defaultDeliveryRadiusKm,
          },
        ),
      ]);

      // Parse products
      final productData = results[0].data;
      final List<dynamic> productList = productData is List
          ? productData
          : (productData['products'] as List?) ?? [];
      final products = productList
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parse vendors
      final vendorData = results[1].data;
      final List<dynamic> vendorList = vendorData is List
          ? vendorData
          : (vendorData['vendors'] as List?) ?? [];
      final vendors = vendorList
          .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _productResults = products;
          _vendorResults = vendors;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _productResults = [];
      _vendorResults = [];
    });
    _focusNode.requestFocus();
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _performSearch(query);
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    final encoded = jsonEncode(_recentSearches);
    LocalStorage.setString(LocalStorage.kRecentSearches, encoded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: _onSearchChanged,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _performSearch(value.trim());
            }
          },
          decoration: InputDecoration(
            hintText: 'Search vegetables, fruits, services...',
            hintStyle: const TextStyle(fontSize: 15, color: AppColors.textHint),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
      body: _query.isEmpty ? _buildRecentSearches() : _buildSearchResults(),
    );
  }

  // ── Recent Searches ──

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'Search for products, stores or services',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recent searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  size: 20,
                  color: AppColors.textHint,
                ),
                title: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: () => _removeRecentSearch(query),
                ),
                onTap: () => _onRecentSearchTap(query),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Search Results ──

  Widget _buildSearchResults() {
    if (_isSearching) {
      return _buildSearchShimmer();
    }

    final hasProducts = _productResults.isNotEmpty;
    final hasVendors = _vendorResults.isNotEmpty;

    if (!hasProducts && !hasVendors) {
      return _buildNoResults();
    }

    return Column(
      children: [
        // Tabs
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Products (${_productResults.length})'),
              Tab(text: 'Stores (${_vendorResults.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Products tab
              hasProducts
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                      itemCount: _productResults.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: _productResults[index]);
                      },
                    )
                  : _buildTabEmpty('No products found'),

              // Vendors tab
              hasVendors
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vendorResults.length,
                      itemBuilder: (context, index) {
                        final vendor = _vendorResults[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VendorListTile(vendor: vendor),
                        );
                      },
                    )
                  : _buildTabEmpty('No stores found'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$_query"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Suggestions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SuggestionChip(
                label: 'Tomatoes',
                onTap: () => _onRecentSearchTap('Tomatoes'),
              ),
              _SuggestionChip(
                label: 'Rice',
                onTap: () => _onRecentSearchTap('Rice'),
              ),
              _SuggestionChip(
                label: 'Milk',
                onTap: () => _onRecentSearchTap('Milk'),
              ),
              _SuggestionChip(
                label: 'Plumber',
                onTap: () => _onRecentSearchTap('Plumber'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabEmpty(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSearchShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: const Color(0xFFF5F5F5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Vendor List Tile (for search results) ──

class _VendorListTile extends StatelessWidget {
  final VendorModel vendor;

  const _VendorListTile({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendor/${vendor.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Shop icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.textHint,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.shopName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.primaryAmber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${vendor.rating.toStringAsFixed(1)} (${vendor.totalRatings})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${vendor.distance?.toStringAsFixed(1) ?? '--'} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open/Closed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: vendor.isOpen
                    ? AppColors.backgroundGreen
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vendor.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: vendor.isOpen
                      ? AppColors.primaryGreen
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion Chip ──

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
