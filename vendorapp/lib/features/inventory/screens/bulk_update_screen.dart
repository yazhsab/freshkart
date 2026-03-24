import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/models/product_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';
import 'package:freshkart_vendor/features/inventory/providers/inventory_provider.dart';

class BulkUpdateScreen extends ConsumerStatefulWidget {
  const BulkUpdateScreen({super.key});

  @override
  ConsumerState<BulkUpdateScreen> createState() => _BulkUpdateScreenState();
}

class _BulkUpdateScreenState extends ConsumerState<BulkUpdateScreen> {
  // Track changes: productId -> {field: value}
  final Map<String, _BulkRowChange> _changes = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    return LoadingOverlay(
      isLoading: _isSaving,
      child: Scaffold(
        backgroundColor: VendorColors.background,
        appBar: AppBar(
          title: const Text(
            'Bulk Update',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VendorColors.textPrimary,
            ),
          ),
          backgroundColor: VendorColors.surface,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: VendorColors.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_changes.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _changes.clear());
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: VendorColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Info bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: VendorColors.primaryBg,
              child: Text(
                '${state.products.length} products | ${_changes.length} changes pending',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.primary,
                ),
              ),
            ),

            // Data table
            Expanded(
              child: state.products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products to update',
                        style: TextStyle(
                          color: VendorColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            VendorColors.fieldBackground,
                          ),
                          headingTextStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textPrimary,
                          ),
                          dataTextStyle: const TextStyle(
                            fontSize: 13,
                            color: VendorColors.textPrimary,
                          ),
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(
                              label: Text('Current\nStock'),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text('New\nStock'),
                              numeric: true,
                            ),
                            DataColumn(label: Text('Price'), numeric: true),
                            DataColumn(label: Text('Available')),
                          ],
                          rows: state.products.map((product) {
                            final change = _changes[product.id];
                            final hasChange = change != null;

                            return DataRow(
                              color: hasChange
                                  ? WidgetStateProperty.all(
                                      const Color(0xFFFFFDE7), // yellow tint
                                    )
                                  : null,
                              cells: [
                                // Product name
                                DataCell(
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Current stock
                                DataCell(
                                  Text(
                                    '${product.stockQuantity}',
                                    style: TextStyle(
                                      color: product.stockQuantity == 0
                                          ? VendorColors.outOfStock
                                          : product.isLowStock
                                          ? VendorColors.lowStock
                                          : VendorColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // New stock (editable)
                                DataCell(
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text:
                                            change?.newStock?.toString() ?? '',
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: '-',
                                        hintStyle: const TextStyle(
                                          color: VendorColors.textHint,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: VendorColors.divider,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final qty = int.tryParse(val);
                                        _updateChange(
                                          product.id,
                                          product,
                                          newStock: qty,
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // Price (editable)
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text:
                                            change?.newPrice?.toStringAsFixed(
                                              2,
                                            ) ??
                                            product.price.toStringAsFixed(2),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        prefixText: '\u20B9',
                                        prefixStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: VendorColors.divider,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final price = double.tryParse(val);
                                        if (price != null &&
                                            price != product.price) {
                                          _updateChange(
                                            product.id,
                                            product,
                                            newPrice: price,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                // Available toggle
                                DataCell(
                                  Switch.adaptive(
                                    value:
                                        change?.newAvailable ??
                                        product.isAvailable,
                                    onChanged: (val) {
                                      _updateChange(
                                        product.id,
                                        product,
                                        newAvailable: val,
                                      );
                                    },
                                    activeColor: VendorColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: VendorColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: AppButton(
                label: _changes.isNotEmpty
                    ? 'Save All Changes (${_changes.length})'
                    : 'No changes',
                isLoading: _isSaving,
                onPressed: _changes.isNotEmpty ? _saveAll : null,
                icon: Icons.save_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateChange(
    String productId,
    ProductModel product, {
    int? newStock,
    double? newPrice,
    bool? newAvailable,
  }) {
    setState(() {
      final existing = _changes[productId] ?? _BulkRowChange();
      final updated = existing.copyWith(
        newStock: newStock,
        newPrice: newPrice,
        newAvailable: newAvailable,
      );

      // Only keep the change if something actually differs from original
      final hasStockChange =
          updated.newStock != null && updated.newStock != product.stockQuantity;
      final hasPriceChange =
          updated.newPrice != null && updated.newPrice != product.price;
      final hasAvailChange =
          updated.newAvailable != null &&
          updated.newAvailable != product.isAvailable;

      if (hasStockChange || hasPriceChange || hasAvailChange) {
        _changes[productId] = updated;
      } else {
        _changes.remove(productId);
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(inventoryProvider.notifier);

    try {
      for (final entry in _changes.entries) {
        final productId = entry.key;
        final change = entry.value;

        if (change.newStock != null) {
          await notifier.updateStock(productId, change.newStock!);
        }

        if (change.newPrice != null) {
          await notifier.updateProduct(productId, {'price': change.newPrice});
        }

        if (change.newAvailable != null) {
          await notifier.toggleAvailability(productId, change.newAvailable!);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_changes.length} products updated'),
            backgroundColor: VendorColors.inStock,
          ),
        );
        setState(() => _changes.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: VendorColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _BulkRowChange {
  final int? newStock;
  final double? newPrice;
  final bool? newAvailable;

  _BulkRowChange({this.newStock, this.newPrice, this.newAvailable});

  _BulkRowChange copyWith({
    int? newStock,
    double? newPrice,
    bool? newAvailable,
  }) {
    return _BulkRowChange(
      newStock: newStock ?? this.newStock,
      newPrice: newPrice ?? this.newPrice,
      newAvailable: newAvailable ?? this.newAvailable,
    );
  }
}
