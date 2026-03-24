import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/client.dart';

// ── State ────────────────────────────────────────────────────────

class VendorListState {
  const VendorListState({
    this.vendors = const [],
    this.filter = 'All',
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<VendorRow> vendors;
  final String filter;
  final String searchQuery;
  final bool isLoading;

  VendorListState copyWith({
    List<VendorRow>? vendors,
    String? filter,
    String? searchQuery,
    bool? isLoading,
  }) {
    return VendorListState(
      vendors: vendors ?? this.vendors,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<VendorRow> get filteredVendors {
    var result = vendors;

    // Apply status filter
    switch (filter) {
      case 'Pending':
        result = result.where((v) => v.status == 'pending').toList();
      case 'Active':
        result = result.where((v) => v.status == 'active').toList();
      case 'Suspended':
        result = result.where((v) => v.status == 'suspended').toList();
      default:
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((v) {
        return v.shopName.toLowerCase().contains(q) ||
            (v.ownerName?.toLowerCase().contains(q) ?? false) ||
            (v.ownerPhone?.contains(q) ?? false) ||
            (v.city?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }
}

// ── Vendor row model (flat) ──────────────────────────────────────

class VendorRow {
  const VendorRow({
    required this.id,
    required this.shopName,
    this.shopNameTamil,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.ownerAvatarUrl,
    this.address,
    this.pincode,
    this.city,
    this.fssaiNumber,
    this.gstin,
    this.isOpen = false,
    this.isApproved = false,
    this.isActive = true,
    this.rating = 0,
    this.totalRatings = 0,
    this.deliveryRadiusKm = 5,
    this.createdAt,
    this.ordersCount = 0,
    this.revenue = 0,
    this.fssaiDocUrl,
    this.gstinDocUrl,
    this.description,
    this.openingTime,
    this.closingTime,
    this.workingDays = const [],
    this.lat,
    this.lng,
    this.bankAccountNumber,
    this.bankIfsc,
  });

  final String id;
  final String shopName;
  final String? shopNameTamil;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerAvatarUrl;
  final String? address;
  final String? pincode;
  final String? city;
  final String? fssaiNumber;
  final String? gstin;
  final bool isOpen;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final double deliveryRadiusKm;
  final DateTime? createdAt;
  final int ordersCount;
  final double revenue;
  final String? fssaiDocUrl;
  final String? gstinDocUrl;
  final String? description;
  final String? openingTime;
  final String? closingTime;
  final List<String> workingDays;
  final double? lat;
  final double? lng;
  final String? bankAccountNumber;
  final String? bankIfsc;

  String get status {
    if (!isActive) return 'suspended';
    if (!isApproved) return 'pending';
    return 'active';
  }

  String get statusLabel {
    switch (status) {
      case 'suspended':
        return 'Suspended';
      case 'pending':
        return 'Pending';
      default:
        return 'Active';
    }
  }

  String get maskedBank {
    if (bankAccountNumber == null || bankAccountNumber!.length < 4) return '-';
    return 'XXXX XX${bankAccountNumber!.substring(bankAccountNumber!.length - 4)}';
  }

  factory VendorRow.fromMap(Map<String, dynamic> m, {
    int ordersCount = 0,
    double revenue = 0,
  }) {
    final owner = m['profiles'] as Map<String, dynamic>?;
    return VendorRow(
      id: m['id'] as String,
      shopName: m['shop_name'] as String? ?? '',
      shopNameTamil: m['shop_name_tamil'] as String?,
      ownerId: m['owner_id'] as String?,
      ownerName: owner?['full_name'] as String?,
      ownerPhone: owner?['phone'] as String?,
      ownerEmail: owner?['email'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      address: m['address'] as String?,
      pincode: m['pincode'] as String?,
      city: m['city'] as String? ?? 'Chennai',
      fssaiNumber: m['fssai_number'] as String?,
      fssaiDocUrl: m['fssai_doc_url'] as String?,
      gstin: m['gstin'] as String?,
      gstinDocUrl: m['gstin_doc_url'] as String?,
      isOpen: m['is_open'] as bool? ?? false,
      isApproved: m['is_approved'] as bool? ?? false,
      isActive: m['is_active'] as bool? ?? true,
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      totalRatings: m['total_ratings'] as int? ?? 0,
      deliveryRadiusKm: (m['delivery_radius_km'] as num?)?.toDouble() ?? 5,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : null,
      ordersCount: ordersCount,
      revenue: revenue,
      description: m['description'] as String?,
      openingTime: m['opening_time'] as String?,
      closingTime: m['closing_time'] as String?,
      workingDays: (m['working_days'] as List?)?.cast<String>() ?? [],
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      bankAccountNumber: m['bank_account_number'] as String?,
      bankIfsc: m['bank_ifsc'] as String?,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────

final vendorListProvider =
    NotifierProvider<VendorListNotifier, VendorListState>(
  VendorListNotifier.new,
);

class VendorListNotifier extends Notifier<VendorListState> {
  @override
  VendorListState build() {
    loadVendors();
    return const VendorListState(isLoading: true);
  }

  Future<void> loadVendors() async {
    state = state.copyWith(isLoading: true);
    try {
      final rows = await adminClient
          .from('vendors')
          .select(
            'id, shop_name, shop_name_tamil, owner_id, address, pincode, city, '
            'fssai_number, fssai_doc_url, gstin, gstin_doc_url, is_open, is_approved, is_active, '
            'rating, total_ratings, created_at, delivery_radius_km, description, '
            'opening_time, closing_time, working_days, lat, lng, bank_account_number, bank_ifsc, '
            'profiles!vendors_owner_id_fkey(id, full_name, phone, email, avatar_url)',
          )
          .order('created_at', ascending: false);

      // Fetch order stats in batch
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1))
          .toIso8601String();

      final vendors = <VendorRow>[];
      for (final row in rows) {
        final vendorId = row['id'] as String;

        // Count orders (all time)
        final countResult = await adminClient
            .from('orders')
            .select('id')
            .eq('vendor_id', vendorId);

        // Revenue this week
        final revenueRows = await adminClient
            .from('orders')
            .select('final_amount')
            .eq('vendor_id', vendorId)
            .gte('created_at', weekStart)
            .inFilter('status',
                ['confirmed', 'packing', 'ready', 'picked_up', 'delivered']);

        var revenue = 0.0;
        for (final r in revenueRows) {
          final v = r['final_amount'];
          if (v != null) revenue += (v as num).toDouble();
        }

        vendors.add(VendorRow.fromMap(
          row,
          ordersCount: (countResult as List).length,
          revenue: revenue,
        ));
      }

      state = state.copyWith(vendors: vendors, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> approveVendor(String vendorId) async {
    await adminClient.from('vendors').update({
      'is_approved': true,
      'is_active': true,
    }).eq('id', vendorId);

    final vendor = await adminClient
        .from('vendors')
        .select('owner_id, shop_name')
        .eq('id', vendorId)
        .single();

    await adminClient.from('notifications_log').insert({
      'user_id': vendor['owner_id'],
      'ref_type': 'vendor',
      'ref_id': vendorId,
      'title': 'Shop Approved!',
      'body':
          'Your shop "${vendor['shop_name']}" has been approved! Start adding products.',
      'type': 'vendor',
    });

    await loadVendors();
  }

  Future<void> suspendVendor(String vendorId, String reason) async {
    await adminClient
        .from('vendors')
        .update({'is_active': false}).eq('id', vendorId);

    final vendor = await adminClient
        .from('vendors')
        .select('owner_id')
        .eq('id', vendorId)
        .single();

    await adminClient.from('notifications_log').insert({
      'user_id': vendor['owner_id'],
      'ref_type': 'vendor',
      'ref_id': vendorId,
      'title': 'Shop Suspended',
      'body': 'Your shop has been suspended. Reason: $reason',
      'type': 'alert',
    });

    await loadVendors();
  }

  Future<void> reinstateVendor(String vendorId) async {
    await adminClient.from('vendors').update({
      'is_active': true,
      'is_approved': true,
    }).eq('id', vendorId);

    final vendor = await adminClient
        .from('vendors')
        .select('owner_id')
        .eq('id', vendorId)
        .single();

    await adminClient.from('notifications_log').insert({
      'user_id': vendor['owner_id'],
      'ref_type': 'vendor',
      'ref_id': vendorId,
      'title': 'Shop Reinstated',
      'body': 'Your shop has been reinstated. You can now receive orders.',
      'type': 'vendor',
    });

    await loadVendors();
  }

  Future<void> rejectVendor(String vendorId) async {
    await adminClient
        .from('vendors')
        .update({'is_active': false}).eq('id', vendorId);
    await loadVendors();
  }

  Future<void> toggleProductAvailability(
      String productId, bool available) async {
    await adminClient
        .from('products')
        .update({'is_available': available}).eq('id', productId);
  }
}

// ── Selected vendor ──────────────────────────────────────────────

final selectedVendorProvider =
    NotifierProvider<SelectedVendorNotifier, VendorRow?>(
  SelectedVendorNotifier.new,
);

class SelectedVendorNotifier extends Notifier<VendorRow?> {
  @override
  VendorRow? build() => null;
  void select(VendorRow? vendor) => state = vendor;
  void clear() => state = null;
}

// ── Vendor detail data providers ─────────────────────────────────

final vendorProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, vendorId) async {
    return await adminClient
        .from('products')
        .select('id, name, price, unit, stock_quantity, is_available, image_url')
        .eq('vendor_id', vendorId)
        .order('sort_order');
  },
);

final vendorOrdersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, vendorId) async {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    return await adminClient
        .from('orders')
        .select('id, order_number, final_amount, status, created_at')
        .eq('vendor_id', vendorId)
        .gte('created_at', thirtyDaysAgo)
        .order('created_at', ascending: false);
  },
);

final vendorPayoutsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, vendorId) async {
    final payouts = await adminClient
        .from('payouts')
        .select()
        .eq('payee_type', 'vendor')
        .eq('payee_id', vendorId)
        .order('created_at', ascending: false);

    var totalEarned = 0.0;
    var totalCommission = 0.0;
    var totalPaid = 0.0;
    var pending = 0.0;

    for (final p in payouts) {
      totalEarned += ((p['gross_amount'] as num?) ?? 0).toDouble();
      totalCommission += ((p['commission_amount'] as num?) ?? 0).toDouble();
      if (p['status'] == 'paid') {
        totalPaid += ((p['net_amount'] as num?) ?? 0).toDouble();
      } else if (p['status'] == 'pending') {
        pending += ((p['net_amount'] as num?) ?? 0).toDouble();
      }
    }

    return {
      'totalEarned': totalEarned,
      'totalCommission': totalCommission,
      'totalPaid': totalPaid,
      'pending': pending,
      'records': payouts,
    };
  },
);
