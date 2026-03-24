import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/router/route_names.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/orders/providers/orders_provider.dart';
import 'package:freshkart_customer/features/orders/widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(ordersProvider.notifier).fetchOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _ActiveTab(orders: state.activeOrders),
                  _PastTab(orders: state.pastOrders),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active orders tab
// ---------------------------------------------------------------------------

class _ActiveTab extends ConsumerWidget {
  final List orders;
  const _ActiveTab({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No active orders',
        subtitle: 'Your current orders will appear here',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => ref.read(ordersProvider.notifier).fetchOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            isActive: true,
            onTap: () => context.pushNamed(
              RouteNames.orderDetail,
              pathParameters: {'orderId': order.id},
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Past orders tab
// ---------------------------------------------------------------------------

class _PastTab extends ConsumerWidget {
  final List orders;
  const _PastTab({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'No past orders',
        subtitle: 'Your completed orders will appear here',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => ref.read(ordersProvider.notifier).fetchOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            isActive: false,
            onTap: () => context.pushNamed(
              RouteNames.orderDetail,
              pathParameters: {'orderId': order.id},
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
