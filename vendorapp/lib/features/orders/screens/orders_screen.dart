import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/config/supabase_config.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/models/order_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/vendor_bottom_nav.dart';
import 'package:freshkart_vendor/features/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_vendor/features/orders/providers/orders_provider.dart';
import 'package:freshkart_vendor/features/orders/providers/new_order_provider.dart';
import 'package:freshkart_vendor/features/orders/widgets/order_card.dart';
import 'package:freshkart_vendor/features/orders/screens/order_detail_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId != null) {
      ref.read(ordersProvider.notifier).fetchOrders(vendorId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDetail(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
    );
  }

  Future<void> _showRejectDialog(String orderId) async {
    final reasons = [
      'Items out of stock',
      'Shop closing soon',
      'Too many orders',
      'Customer request',
      'Other',
    ];
    String? selectedReason;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Reject Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a reason:',
                style: TextStyle(
                  fontSize: 14,
                  color: VendorColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: VendorColors.primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => selectedReason = val);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, selectedReason)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorColors.cancelledOrder,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      ref.read(newOrderProvider.notifier).rejectOrder(orderId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final newOrderState = ref.watch(newOrderProvider);

    // Listen to realtime updates
    final vendorId = SupabaseConfig.currentUser?.id;
    if (vendorId != null) {
      final realtimeAsync = ref.watch(ordersRealtimeProvider(vendorId));
      realtimeAsync.whenData((data) {
        ref.read(ordersProvider.notifier).updateFromRealtime(data);

        // Update new order provider with current pending orders
        final allOrders = data.map((e) => OrderModel.fromJson(e)).toList();
        ref.read(newOrderProvider.notifier).handleNewOrders(allOrders);
      });
    }

    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: VendorColors.surface,
        foregroundColor: VendorColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Search functionality placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              _showFilterSheet();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: VendorColors.primary,
            unselectedLabelColor: VendorColors.textSecondary,
            indicatorColor: VendorColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'New (${ordersState.pendingCount})'),
              Tab(text: 'Active (${ordersState.activeCount})'),
              Tab(text: 'Ready (${ordersState.readyCount})'),
              Tab(text: 'Done (${ordersState.doneCount})'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Sticky new order banner
          if (newOrderState.isAlertActive &&
              newOrderState.pendingOrders.isNotEmpty)
            _buildNewOrderBanner(newOrderState),

          // Tab content
          Expanded(
            child: ordersState.isLoading && ordersState.orders.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        VendorColors.primary,
                      ),
                    ),
                  )
                : ordersState.error != null && ordersState.orders.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      title: 'Failed to load orders',
                      subtitle: ordersState.error,
                      actionLabel: 'Retry',
                      onAction: _loadOrders,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(ordersState.pendingOrders, 'pending'),
                      _buildOrderList(ordersState.activeOrders, 'active'),
                      _buildOrderList(ordersState.readyOrders, 'ready'),
                      _buildDoneTab(ordersState.doneOrders),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: VendorBottomNav(
        currentIndex: 1,
        pendingOrderCount: ordersState.pendingCount,
        onTap: (index) {
          if (index != 1) {
            // Navigate to other tabs
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed('/dashboard');
                break;
              case 2:
                Navigator.of(context).pushReplacementNamed('/inventory');
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/shop');
                break;
            }
          }
        },
      ),
    );
  }

  Widget _buildNewOrderBanner(NewOrderState newOrderState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: VendorColors.newOrder,
        boxShadow: [
          BoxShadow(
            color: VendorColors.newOrder.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${newOrderState.pendingOrders.length} new order${newOrderState.pendingOrders.length != 1 ? 's' : ''} waiting!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(newOrderProvider.notifier).dismissAlert();
            },
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String type) {
    if (orders.isEmpty) {
      return EmptyStateWidget(
        icon: _emptyIcon(type),
        title: _emptyTitle(type),
        subtitle: _emptySubtitle(type),
      );
    }

    return RefreshIndicator(
      color: VendorColors.primary,
      onRefresh: () async {
        await ref.read(ordersProvider.notifier).refreshOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onTap: () => _navigateToDetail(order),
            onAccept: order.isPending
                ? () {
                    ref.read(newOrderProvider.notifier).acceptOrder(order.id);
                  }
                : null,
            onReject: order.isPending
                ? () => _showRejectDialog(order.id)
                : null,
            onUpdateStatus: (newStatus) {
              ref
                  .read(ordersProvider.notifier)
                  .updateOrderStatus(order.id, newStatus);
            },
          );
        },
      ),
    );
  }

  Widget _buildDoneTab(List<OrderModel> orders) {
    final deliveredToday = orders.where((o) => o.isDelivered).toList();
    final cancelledToday = orders.where((o) => o.isCancelled).toList();
    final totalEarnings = deliveredToday.fold<double>(
      0,
      (sum, o) => sum + o.vendorEarnings,
    );

    return RefreshIndicator(
      color: VendorColors.primary,
      onRefresh: () async {
        await ref.read(ordersProvider.notifier).refreshOrders();
      },
      child: orders.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'No completed orders yet',
                  subtitle: 'Completed and cancelled orders will appear here',
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VendorColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VendorColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 13,
                                color: VendorColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${deliveredToday.length} delivered',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: VendorColors.primary,
                              ),
                            ),
                            if (cancelledToday.isNotEmpty)
                              Text(
                                '${cancelledToday.length} cancelled',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: VendorColors.cancelledOrder,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: VendorColors.divider,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Earned',
                              style: TextStyle(
                                fontSize: 13,
                                color: VendorColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyUtil.formatPrice(totalEarnings),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: VendorColors.earningsGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Order list
                ...orders.map(
                  (order) => OrderCard(
                    order: order,
                    onTap: () => _navigateToDetail(order),
                  ),
                ),
              ],
            ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final currentFilter = ref.read(ordersProvider).filter;
        final filters = [
          {'value': 'all', 'label': 'All Orders', 'icon': Icons.list_rounded},
          {
            'value': 'pending',
            'label': 'Pending',
            'icon': Icons.access_time_rounded,
          },
          {
            'value': 'active',
            'label': 'Active',
            'icon': Icons.local_fire_department_rounded,
          },
          {
            'value': 'ready',
            'label': 'Ready',
            'icon': Icons.check_circle_outline_rounded,
          },
          {
            'value': 'completed',
            'label': 'Completed',
            'icon': Icons.done_all_rounded,
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VendorColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...filters.map(
                (f) => ListTile(
                  leading: Icon(
                    f['icon'] as IconData,
                    color: f['value'] == currentFilter
                        ? VendorColors.primary
                        : VendorColors.textSecondary,
                  ),
                  title: Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontWeight: f['value'] == currentFilter
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: f['value'] == currentFilter
                          ? VendorColors.primary
                          : VendorColors.textPrimary,
                    ),
                  ),
                  trailing: f['value'] == currentFilter
                      ? const Icon(
                          Icons.check_rounded,
                          color: VendorColors.primary,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(ordersProvider.notifier)
                        .setFilter(f['value'] as String);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _emptyIcon(String type) {
    switch (type) {
      case 'pending':
        return Icons.notifications_none_rounded;
      case 'active':
        return Icons.inventory_2_outlined;
      case 'ready':
        return Icons.local_shipping_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _emptyTitle(String type) {
    switch (type) {
      case 'pending':
        return 'No new orders';
      case 'active':
        return 'No active orders';
      case 'ready':
        return 'No orders ready';
      default:
        return 'No orders';
    }
  }

  String _emptySubtitle(String type) {
    switch (type) {
      case 'pending':
        return 'New orders will appear here when customers place them';
      case 'active':
        return 'Orders being prepared will appear here';
      case 'ready':
        return 'Orders waiting for pickup will appear here';
      default:
        return 'Your orders will appear here';
    }
  }
}
