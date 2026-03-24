import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/export_button.dart';
import 'wallet_provider.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  final _searchCtrl = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletListProvider);
    final filtered = walletState.filteredWallets;
    final sorted = _sortWallets(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        SectionHeader(
          title: 'Wallets',
          subtitle: '${filtered.length} customer wallets',
          actions: [
            ExportButton(onPressed: () => _exportCSV(filtered)),
          ],
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Summary stats
              _SummaryChip(
                label:
                    'Total Balance: ${formatINR(filtered.fold<double>(0, (s, w) => s + w.balance))}',
                icon: Icons.account_balance_wallet,
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, email...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    ref.read(walletListProvider.notifier).setSearch(v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AdminDataTable(
              isLoading: walletState.isLoading,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              emptyIcon: Icons.account_balance_wallet_outlined,
              emptyTitle: 'No wallets found',
              minWidth: 900,
              columns: [
                DataColumn2(
                  label: const Text('Customer'),
                  size: ColumnSize.L,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Phone'),
                  size: ColumnSize.M,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Balance'),
                  size: ColumnSize.S,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Last Transaction'),
                  size: ColumnSize.M,
                  onSort: _onSort,
                ),
                const DataColumn2(
                  label: Text('Actions'),
                  size: ColumnSize.M,
                  fixedWidth: 240,
                ),
              ],
              rows: sorted.map((w) => _buildRow(w)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  DataRow2 _buildRow(WalletRow w) {
    return DataRow2(
      cells: [
        // Customer
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                w.userName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (w.userEmail != null)
                Text(
                  w.userEmail!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Phone
        DataCell(Text(w.userPhone ?? '-')),
        // Balance
        DataCell(
          Text(
            formatINR(w.balance),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: w.balance > 0
                  ? AppColors.statusDelivered
                  : AppColors.textPrimary,
            ),
          ),
        ),
        // Last Transaction
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (w.lastTransactionAt != null)
                Text(
                  timeAgoStr(w.lastTransactionAt!),
                  style: const TextStyle(fontSize: 12),
                )
              else
                const Text('-', style: TextStyle(fontSize: 12)),
              if (w.lastTransactionType != null &&
                  w.lastTransactionAmount != null)
                Text(
                  '${w.lastTransactionType!.toUpperCase()} ${formatINR(w.lastTransactionAmount!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: w.lastTransactionType == 'credit'
                        ? AppColors.statusDelivered
                        : AppColors.error,
                  ),
                ),
            ],
          ),
        ),
        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                label: 'Credit',
                color: AppColors.statusDelivered,
                onTap: () => _showCreditDebitDialog(w, 'credit'),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                label: 'Debit',
                color: AppColors.error,
                onTap: () => _showCreditDebitDialog(w, 'debit'),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                label: 'History',
                color: AppColors.primary,
                onTap: () => _showTransactionHistory(w),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSort(int colIndex, bool asc) {
    setState(() {
      _sortColumnIndex = colIndex;
      _sortAscending = asc;
    });
  }

  List<WalletRow> _sortWallets(List<WalletRow> wallets) {
    if (_sortColumnIndex == null) return wallets;
    final list = List<WalletRow>.from(wallets);
    final asc = _sortAscending;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.userName.compareTo(b.userName);
        case 1:
          cmp = (a.userPhone ?? '').compareTo(b.userPhone ?? '');
        case 2:
          cmp = a.balance.compareTo(b.balance);
        case 3:
          cmp = (a.lastTransactionAt ?? DateTime(2000))
              .compareTo(b.lastTransactionAt ?? DateTime(2000));
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return list;
  }

  void _showCreditDebitDialog(WalletRow w, String type) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isCredit = type == 'credit';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${isCredit ? "Credit" : "Debit"} Wallet'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${w.userName} - Current Balance: ${formatINR(w.balance)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\u20B9 ',
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description / Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) return;
                final desc = descCtrl.text.trim();
                Navigator.of(ctx).pop();

                try {
                  if (isCredit) {
                    await ref
                        .read(walletListProvider.notifier)
                        .creditWallet(w.userId, amount, desc);
                  } else {
                    await ref
                        .read(walletListProvider.notifier)
                        .debitWallet(w.userId, amount, desc);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${formatINR(amount)} ${isCredit ? "credited to" : "debited from"} ${w.userName}',
                        ),
                        backgroundColor: isCredit
                            ? AppColors.statusDelivered
                            : AppColors.error,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isCredit ? AppColors.statusDelivered : AppColors.error,
              ),
              child: Text(isCredit ? 'Credit' : 'Debit'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionHistory(WalletRow w) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${w.userName} - Transaction History'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Consumer(
              builder: (ctx, ref, _) {
                final asyncTxns =
                    ref.watch(walletTransactionsProvider(w.id));
                return asyncTxns.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (txns) {
                    if (txns.isEmpty) {
                      return const Center(
                        child: Text('No transactions yet'),
                      );
                    }
                    return ListView.separated(
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = txns[i];
                        final isCredit = t.type == 'credit';
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isCredit
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: isCredit
                                ? AppColors.statusDelivered
                                : AppColors.error,
                            size: 20,
                          ),
                          title: Text(
                            '${isCredit ? "+" : "-"}${formatINR(t.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCredit
                                  ? AppColors.statusDelivered
                                  : AppColors.error,
                            ),
                          ),
                          subtitle: t.description != null
                              ? Text(
                                  t.description!,
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          trailing: t.createdAt != null
                              ? Text(
                                  timeAgoStr(t.createdAt!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exportCSV(List<WalletRow> wallets) {
    exportToCSV(
      'wallets_export.csv',
      [
        'Customer',
        'Phone',
        'Email',
        'Balance',
        'Last Transaction',
      ],
      wallets
          .map((w) => [
                w.userName,
                w.userPhone ?? '-',
                w.userEmail ?? '-',
                w.balance,
                w.lastTransactionAt != null
                    ? formatDate(w.lastTransactionAt!)
                    : '-',
              ])
          .toList(),
    );
  }
}

// ── Small reusable widgets ───────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hover
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: widget.color.withValues(alpha: 0.5)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
