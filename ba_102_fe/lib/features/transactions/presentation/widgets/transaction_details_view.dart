import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/transactions/presentation/providers/transaction_month_provider.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ba_102_fe/providers/categories_provider.dart';
import 'package:ba_102_fe/providers/sms_provider.dart';
import 'package:ba_102_fe/services/contact_service.dart';

const Color priColor = Color(0xFF4B0082);

class TransactionDetailsView extends ConsumerStatefulWidget {
  const TransactionDetailsView({super.key});

  @override
  ConsumerState<TransactionDetailsView> createState() =>
      _TransactionDetailsViewState();
}

class _TransactionDetailsViewState
    extends ConsumerState<TransactionDetailsView> {
  int? _selectedCategoryId;
  String _selectedType = 'All';
  String _sortBy = 'Newest';
  bool _isFetchingHistory = false;
  bool _isSearching = false;
  int? _searchYear;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonthAsync = ref.watch(selectedTransactionMonthProvider);
    final earliestMonthAsync = ref.watch(earliestSmsMonthProvider);
    final selectedMonth = selectedMonthAsync.valueOrNull;
    final monthTransactionsAsync = selectedMonth == null
        ? null
        : ref.watch(transactionsForMonthProvider(selectedMonth));
    final transactionsAsync = _isSearching
        ? ref.watch(allTransactionsProvider)
        : monthTransactionsAsync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _isSearching
                  ? SizedBox(
                      width: 190,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search transactions',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : const Text(
                      'Transaction details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
              Row(
                children: [
                  IconButton(
                    tooltip: _isSearching
                        ? 'Close search'
                        : 'Search transactions',
                    onPressed: _isSearching ? _closeSearch : _openSearch,
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                  ),
                  _buildSortMenu(),
                  const SizedBox(width: 8),
                  if (_isSearching)
                    _buildSearchYearSelector(earliestMonthAsync)
                  else
                    _buildMonthCapsule(selectedMonth, earliestMonthAsync),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // 1. Transaction Type Filter (In/Out)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildTypePill('All', Icons.all_inclusive),
              const SizedBox(width: 8),
              _buildTypePill('Out', Icons.arrow_upward, color: Colors.red),
              const SizedBox(width: 8),
              _buildTypePill('In', Icons.arrow_downward, color: Colors.green),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // 2. Dynamic Category Filter
        ref
            .watch(categoriesProvider)
            .when(
              data: (categories) {
                final topLevel = categories
                    .where((c) => c.parentId == null)
                    .toList();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildCategoryPill(null, 'All', Icons.grid_view),
                      ...topLevel.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildCategoryPill(
                            cat.id,
                            cat.name,
                            IconService.getIcon(cat.icon, cat.name),
                            color: cat.color != null
                                ? Color(int.parse(cat.color!))
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        const SizedBox(height: 8),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_isSearching) {
                ref.invalidate(allTransactionsProvider);
                await ref.read(allTransactionsProvider.future);
                return;
              }
              if (selectedMonth == null) return;
              ref.invalidate(transactionsForMonthProvider(selectedMonth));
              await ref.read(
                transactionsForMonthProvider(selectedMonth).future,
              );
            },
            child: transactionsAsync == null
                ? const Center(child: CircularProgressIndicator())
                : _isFetchingHistory
                ? const Center(child: CircularProgressIndicator())
                : transactionsAsync.when(
                    data: (transactions) {
                      var filtered = transactions;
                      final categories =
                          ref.read(categoriesProvider).valueOrNull ??
                          const <Category>[];
                      final categoryNames = {
                        for (final category in categories)
                          category.id: category.name.toLowerCase(),
                      };

                      if (_isSearching && _searchYear != null) {
                        filtered = filtered.where((tx) {
                          return tx.date?.year == _searchYear;
                        }).toList();
                      }

                      final query = _searchQuery.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        filtered = filtered.where((tx) {
                          final searchable = [
                            tx.description,
                            tx.vendor,
                            tx.mpesaReference,
                            tx.rawSmsMessage,
                            categoryNames[tx.categoryId],
                          ].whereType<String>().join(' ').toLowerCase();
                          return searchable.contains(query);
                        }).toList();
                      }

                      // 2. Filter by Type (In/Out)
                      filtered = filtered.where((tx) {
                        if (_selectedType == 'All') return true;
                        final isOut =
                            tx.type == 'outbound' || tx.type == 'withdrawal';
                        return _selectedType == 'Out' ? isOut : !isOut;
                      }).toList();

                      // 3. Filter by Category
                      filtered = filtered.where((tx) {
                        if (_selectedCategoryId == null) return true;
                        return tx.categoryId == _selectedCategoryId;
                      }).toList();

                      // 3. Sort transactions
                      switch (_sortBy) {
                        case 'Newest':
                          filtered.sort(
                            (a, b) => (b.date ?? DateTime.now()).compareTo(
                              a.date ?? DateTime.now(),
                            ),
                          );
                          break;
                        case 'Oldest':
                          filtered.sort(
                            (a, b) => (a.date ?? DateTime.now()).compareTo(
                              b.date ?? DateTime.now(),
                            ),
                          );
                          break;
                        case 'Highest':
                          filtered.sort(
                            (a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0),
                          );
                          break;
                        case 'Lowest':
                          filtered.sort(
                            (a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0),
                          );
                          break;
                      }

                      if (filtered.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (_isSearching) _buildSearchTotal(0, 0),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getNoResultsLabel(selectedMonth),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final totalSpending = filtered
                          .where(
                            (tx) =>
                                tx.type == 'outbound' ||
                                tx.type == 'withdrawal',
                          )
                          .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
                      final grouped = _groupTransactions(filtered);

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        itemCount: grouped.length + (_isSearching ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isSearching && index == 0) {
                            return _buildSearchTotal(
                              totalSpending,
                              filtered.length,
                            );
                          }
                          if (_isSearching) index--;
                          final item = grouped[index];
                          if (item is String) {
                            return _buildHeader(item);
                          } else if (item is Transaction) {
                            return TransactionItem(transaction: item);
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
          ),
        ),
      ],
    );
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchYear = null;
      _searchController.clear();
    });
  }

  Future<void> _openSearch() async {
    setState(() {
      _isSearching = true;
      _searchYear = null;
    });
    await _loadSearchYear(null);
  }

  Future<void> _loadSearchYear(int? year) async {
    if (_isFetchingHistory) return;
    setState(() => _isFetchingHistory = true);
    try {
      final earliestDate = await ref.read(earliestSmsDateProvider.future);
      final now = DateTime.now();
      final since = year == null ? earliestDate : DateTime(year, 1, 1);
      if (since == null) {
        throw StateError('No matching M-Pesa SMS history is available.');
      }
      final importedCount = await ref
          .read(smsProvider.notifier)
          .syncHistoricalMessages(since: since, until: now);
      ref.invalidate(allTransactionsProvider);
      await ref.read(allTransactionsProvider.future);
      if (mounted) setState(() => _searchYear = year);
      if (importedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importedCount transactions from SMS.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showSmsHistoryError(error);
    } finally {
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  Widget _buildSearchYearSelector(AsyncValue<DateTime?> earliestMonthAsync) {
    final now = DateTime.now();
    final earliestYear = earliestMonthAsync.valueOrNull?.year ?? now.year;
    final years = List.generate(
      now.year - earliestYear + 1,
      (index) => now.year - index,
    );
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
      ),
      child: DropdownButton<int?>(
        value: _searchYear,
        underline: const SizedBox.shrink(),
        isDense: true,
        hint: const Text('All years'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All years')),
          ...years.map(
            (year) => DropdownMenuItem<int?>(
              value: year,
              child: Text(year.toString()),
            ),
          ),
        ],
        onChanged: _isFetchingHistory ? null : _loadSearchYear,
      ),
    );
  }

  Widget _buildSearchTotal(double total, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Matching transactions'),
              Text(
                '$count found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Text(
            'KES ${NumberFormat('#,##0.##').format(total)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCapsule(
    DateTime? selectedMonth,
    AsyncValue<DateTime?> earliestMonthAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canOpen =
        selectedMonth != null &&
        !_isFetchingHistory &&
        (earliestMonthAsync.hasValue || earliestMonthAsync.hasError);

    return ActionChip(
      avatar: _isFetchingHistory || earliestMonthAsync.isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Icon(
              earliestMonthAsync.hasError
                  ? Icons.sms_failed_outlined
                  : Icons.calendar_month,
              size: 18,
              color: colorScheme.primary,
            ),
      label: Text(
        _isFetchingHistory
            ? 'Fetching SMS…'
            : earliestMonthAsync.hasError
            ? 'SMS unavailable'
            : selectedMonth == null
            ? 'Loading month'
            : DateFormat('MMM yyyy').format(selectedMonth),
      ),
      onPressed: canOpen
          ? () => _showMonthPicker(selectedMonth, earliestMonthAsync)
          : null,
      shape: StadiumBorder(side: BorderSide(color: colorScheme.outlineVariant)),
      backgroundColor: colorScheme.surface,
    );
  }

  Future<void> _showMonthPicker(
    DateTime selectedMonth,
    AsyncValue<DateTime?> earliestMonthAsync,
  ) async {
    if (earliestMonthAsync.hasError) {
      ref.invalidate(earliestSmsMonthProvider);
      _showSmsHistoryError(earliestMonthAsync.error);
      return;
    }
    if (!earliestMonthAsync.hasValue) return;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final earliestMonth = earliestMonthAsync.valueOrNull;
    final firstMonth = earliestMonth ?? currentMonth;
    final month = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        selectedMonth: selectedMonth,
        earliestMonth: firstMonth,
        currentMonth: currentMonth,
      ),
    );

    if (!mounted || month == null) return;

    setState(() => _isFetchingHistory = true);
    try {
      final importedCount = await ref
          .read(smsProvider.notifier)
          .syncHistoricalMessages(since: month, until: DateTime.now());

      ref.invalidate(transactionsForMonthProvider(month));
      await ref.read(transactionsForMonthProvider(month).future);

      await ref
          .read(selectedTransactionMonthProvider.notifier)
          .selectMonth(month);

      if (importedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $importedCount transaction${importedCount == 1 ? '' : 's'} from SMS.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSmsHistoryError(error);
    } finally {
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  void _showSmsHistoryError(Object? error) {
    final permissionDenied =
        error is PlatformException && error.code == 'SMS_PERMISSION_DENIED';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          permissionDenied
              ? 'Allow SMS permission to fetch transaction history.'
              : 'Could not fetch SMS history. Check SMS permission and try again.',
        ),
      ),
    );
  }

  String _getMonthLabel(DateTime date) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    if (date.year == thisMonth.year && date.month == thisMonth.month)
      return 'This Month';
    if (date.year == lastMonth.year && date.month == lastMonth.month)
      return 'Last Month';
    return DateFormat('MMM yyyy').format(date);
  }

  String _getNoResultsLabel(DateTime? selectedMonth) {
    if (_isSearching) {
      final period = _searchYear?.toString() ?? 'all years';
      return 'No transactions found for $period';
    }
    return 'No transactions found for these filters in ${selectedMonth == null ? '' : _getMonthLabel(selectedMonth)}';
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Colors.grey.shade700, size: 20),
      onSelected: (value) => setState(() => _sortBy = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Newest', child: Text('Newest First')),
        const PopupMenuItem(value: 'Oldest', child: Text('Oldest First')),
        const PopupMenuItem(value: 'Highest', child: Text('Highest Amount')),
        const PopupMenuItem(value: 'Lowest', child: Text('Lowest Amount')),
      ],
    );
  }

  Widget _buildTypePill(String label, IconData icon, {Color? color}) {
    final isSelected = _selectedType == label;
    final activeColor = color ?? priColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedType = label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(
    int? id,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final isSelected = _selectedCategoryId == id;
    final activeColor = color ?? priColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _groupTransactions(List<Transaction> transactions) {
    final List<dynamic> grouped = [];
    String? lastHeader;

    for (var tx in transactions) {
      final date = tx.date ?? DateTime.now();
      final header = _getDateHeader(date);

      if (header != lastHeader) {
        grouped.add(header);
        lastHeader = header;
      }
      grouped.add(tx);
    }
    return grouped;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({
    required this.selectedMonth,
    required this.earliestMonth,
    required this.currentMonth,
  });

  final DateTime selectedMonth;
  final DateTime earliestMonth;
  final DateTime currentMonth;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedMonth.year;
  }

  bool _isMonthAvailable(int month) {
    final value = DateTime(_selectedYear, month);
    return !value.isBefore(widget.earliestMonth) &&
        !value.isAfter(widget.currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      widget.currentMonth.year - widget.earliestMonth.year + 1,
      (index) => widget.currentMonth.year - index,
    );

    return AlertDialog(
      title: const Text('Select month'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: _selectedYear,
              isExpanded: true,
              items: years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (year) {
                if (year != null) setState(() => _selectedYear = year);
              },
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: List.generate(12, (index) {
                final month = index + 1;
                final value = DateTime(_selectedYear, month);
                final enabled = _isMonthAvailable(month);
                final selected =
                    value.year == widget.selectedMonth.year &&
                    value.month == widget.selectedMonth.month;

                return ChoiceChip(
                  label: Text(DateFormat('MMM').format(value)),
                  selected: selected,
                  onSelected: enabled
                      ? (_) => Navigator.of(context).pop(value)
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactService = ref.watch(contactServiceProvider);

    // Attempt to match contact name
    String displayName =
        transaction.description ?? transaction.vendor ?? 'Unknown';

    // If the display name looks like a number, try to get a contact name
    if (RegExp(r'^\d+$').hasMatch(displayName.replaceAll(RegExp(r'\s+'), ''))) {
      displayName = contactService.getContactName(displayName);
    } else if (displayName.contains('uknown') ||
        displayName.contains('M-Pesa User')) {
      // Sometimes MpesaParser returns these fallbacks if it can't find a sender/recipient
      // its better to check the raw message if we have the number there,
    }

    final isExpense =
        transaction.type == 'outbound' || transaction.type == 'withdrawal';
    final isIncome =
        transaction.type == 'inbound' || transaction.type == 'deposit';
    IconData icon = _getIcon();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: priColor.withOpacity(0.1),
          child: Icon(icon, color: priColor, size: 20),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(transaction.date),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : (isIncome ? '+' : '')}KES ${NumberFormat('#,###').format(transaction.amount ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExpense
                    ? Colors.red.shade700
                    : (isIncome ? Colors.green.shade700 : Colors.black87),
              ),
            ),
            if (transaction.balance != null)
              Text(
                'Bal: ${NumberFormat('#,###').format(transaction.balance)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RAW M-PESA MESSAGE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.rawSmsMessage ??
                      "No raw message available for this transaction.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
                if (transaction.mpesaReference != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reference",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        transaction.mpesaReference!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (transaction.type) {
      case 'inbound':
        return Icons.arrow_downward;
      case 'withdrawal':
        return Icons.local_atm;
      case 'deposit':
        return Icons.account_balance;
      case 'outbound':
      default:
        final vendor = (transaction.vendor ?? transaction.description ?? '')
            .toLowerCase();

        if (vendor.contains('food') ||
            vendor.contains('restaurant') ||
            vendor.contains('cafe') ||
            vendor.contains('hotel')) {
          return Icons.fastfood;
        }
        if (vendor.contains('shop') ||
            vendor.contains('store') ||
            vendor.contains('market')) {
          return Icons.shopping_bag;
        }
        if (vendor.contains('uber') ||
            vendor.contains('bolt') ||
            vendor.contains('taxi') ||
            vendor.contains('transport')) {
          return Icons.local_taxi;
        }
        if (vendor.contains('fuel') || vendor.contains('petrol')) {
          return Icons.local_gas_station;
        }
        if (vendor.contains('electric') ||
            vendor.contains('kplc') ||
            vendor.contains('water') ||
            vendor.contains('bill')) {
          return Icons.receipt;
        }
        return Icons.payments;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}: ${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
