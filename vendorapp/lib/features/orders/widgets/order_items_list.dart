import 'package:flutter/material.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/models/order_item_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/network_image_widget.dart';

class OrderItemsList extends StatefulWidget {
  final List<OrderItemModel> items;
  final bool showCheckboxes;
  final ValueChanged<Set<String>>? onCheckedChanged;

  const OrderItemsList({
    super.key,
    required this.items,
    this.showCheckboxes = false,
    this.onCheckedChanged,
  });

  @override
  State<OrderItemsList> createState() => _OrderItemsListState();
}

class _OrderItemsListState extends State<OrderItemsList> {
  final Set<String> _checkedIds = {};

  bool get allChecked =>
      widget.items.isNotEmpty && _checkedIds.length == widget.items.length;

  void _toggleItem(String itemId) {
    setState(() {
      if (_checkedIds.contains(itemId)) {
        _checkedIds.remove(itemId);
      } else {
        _checkedIds.add(itemId);
      }
    });
    widget.onCheckedChanged?.call(Set.from(_checkedIds));
  }

  void _toggleAll() {
    setState(() {
      if (allChecked) {
        _checkedIds.clear();
      } else {
        _checkedIds.addAll(widget.items.map((i) => i.id));
      }
    });
    widget.onCheckedChanged?.call(Set.from(_checkedIds));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCheckboxes && widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _toggleAll,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: allChecked,
                        onChanged: (_) => _toggleAll(),
                        activeColor: VendorColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      allChecked ? 'All packed' : 'Select all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: allChecked
                            ? VendorColors.primary
                            : VendorColors.textSecondary,
                      ),
                    ),
                    if (allChecked) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: VendorColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ...widget.items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    final isChecked = _checkedIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VendorColors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox for packing mode
          if (widget.showCheckboxes)
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => _toggleItem(item.id),
                activeColor: VendorColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          if (widget.showCheckboxes) const SizedBox(width: 8),

          // Product image
          if (item.productImageUrl != null && item.productImageUrl!.isNotEmpty)
            NetworkImageWidget(
              url: item.productImageUrl!,
              width: 48,
              height: 48,
              radius: 8,
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: VendorColors.fieldBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 24,
                color: VendorColors.textHint,
              ),
            ),
          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: VendorColors.textPrimary,
                    decoration: widget.showCheckboxes && isChecked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VendorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity x price = total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x ${CurrencyUtil.formatPrice(item.unitPrice)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: VendorColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyUtil.formatPrice(item.totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
