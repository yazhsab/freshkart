import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../core/constants/colors.dart';
import 'loading_shimmer.dart';
import 'empty_state.dart';

class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.onSort,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChange,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'No data found',
    this.emptySubtitle,
    this.minWidth = 900,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  final List<DataColumn2> columns;
  final List<DataRow2> rows;
  final bool isLoading;
  final Function(int, bool)? onSort;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChange;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final double minWidth;
  final int? sortColumnIndex;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingShimmer(height: 400);
    }

    if (rows.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columnSpacing: 16,
            horizontalMargin: 16,
            minWidth: minWidth,
            headingRowHeight: 44,
            dataRowHeight: 52,
            headingRowColor:
                WidgetStateProperty.all(AppColors.background),
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            columns: columns,
            rows: rows,
            empty: EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
            ),
          ),
        ),
        if (totalPages > 1)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: currentPage > 1
                      ? () => onPageChange?.call(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  totalPages > 5 ? 5 : totalPages,
                  (i) {
                    final page = totalPages > 5
                        ? _getVisiblePage(i)
                        : i + 1;
                    final isActive = page == currentPage;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => onPageChange?.call(page),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$page',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: currentPage < totalPages
                      ? () => onPageChange?.call(currentPage + 1)
                      : null,
                  icon: const Text('Next'),
                  label: const Icon(Icons.chevron_right, size: 18),
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _getVisiblePage(int index) {
    if (currentPage <= 3) return index + 1;
    if (currentPage >= totalPages - 2) {
      return totalPages - 4 + index;
    }
    return currentPage - 2 + index;
  }
}
