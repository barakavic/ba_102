import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ba_102_fe/providers/categories_provider.dart';
import 'package:ba_102_fe/services/contact_service.dart';
const Color priColor = Color(0xFF4B0082);

class TransactionDetailsView extends ConsumerStatefulWidget {
  final AsyncValue<List<Transaction>> txAsyncValue;
  const TransactionDetailsView({
    super.key, 
    required this.txAsyncValue,
    });

  @override
  ConsumerState<TransactionDetailsView> createState() => _TransactionDetailsViewState();
}

class _TransactionDetailsViewState extends ConsumerState<TransactionDetailsView> {
  int? _selectedCategoryId; // null for 'All'
  String _selectedType = 'All'; // All, In, Out
  String _sortBy = 'Newest'; // Newest, Oldest, Highest, Lowest
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  _buildSortMenu(),
                  const SizedBox(width: 8),
                  widget.txAsyncValue.when(
                    data: (transactions) => _buildMonthMenu(transactions),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              )
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
        ref.watch(categoriesProvider).when(
          data: (categories) {
            final topLevel = categories.where((c) => c.parentId == null).toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryPill(null, 'All', Icons.grid_view),
                  ...topLevel.map((cat) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildCategoryPill(
                      cat.id, 
                      cat.name, 
                      IconService.getIcon(cat.icon, cat.name),
                      color: cat.color != null ? Color(int.parse(cat.color!)) : null,
                    ),
                  )),
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
              ref.invalidate(txProv);
              await ref.read(txProv.future);
            },
            child: widget.txAsyncValue.when(
              data: (transactions) {
                // 1. Filter by Month
                var filtered = transactions.where((tx) {
                  final date = tx.date ?? DateTime.now();
                  return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
                }).toList();

                // 2. Filter by Type (In/Out)
                filtered = filtered.where((tx) {
                  if (_selectedType == 'All') return true;
                  final isOut = tx.type == 'outbound' || tx.type == 'withdrawal';
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
                    filtered.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
                    break;
                  case 'Oldest':
                    filtered.sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
                    break;
                  case 'Highest':
                    filtered.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
                    break;
                  case 'Lowest':
                    filtered.sort((a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0));
                    break;
                }

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found for these filters in ${_getMonthLabel(_selectedMonth)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final grouped = _groupTransactions(filtered);

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthMenu(List<Transaction> transactions) {
    final availableMonths = _getAvailableMonths(transactions);
    
    // Ensure current month is always available even if no transactions
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    if (!availableMonths.contains(thisMonth)) {
      availableMonths.insert(0, thisMonth);
    }

    return PopupMenuButton<DateTime>(
      initialValue: _selectedMonth,
      onSelected: (date) => setState(() => _selectedMonth = date),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getMonthLabel(_selectedMonth),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
          ],
        ),
      ),
      itemBuilder: (context) => availableMonths.map((date) {
        return PopupMenuItem<DateTime>(
          value: date,
          child: Text(_getMonthLabel(date)),
        );
      }).toList(),
    );
  }

  List<DateTime> _getAvailableMonths(List<Transaction> transactions) {
    final months = transactions
        .map((tx) => tx.date ?? DateTime.now())
        .map((date) => DateTime(date.year, date.month))
        .toSet()
        .toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  String _getMonthLabel(DateTime date) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    if (date.year == thisMonth.year && date.month == thisMonth.month) return 'This Month';
    if (date.year == lastMonth.year && date.month == lastMonth.month) return 'Last Month';
    return DateFormat('MMM yyyy').format(date);
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
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade700),
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

  Widget _buildCategoryPill(int? id, String label, IconData icon, {Color? color}) {
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
            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade700),
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

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;

  const TransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactService = ref.watch(contactServiceProvider);
    
    // Attempt to match contact name
    String displayName = transaction.description ?? transaction.vendor ?? 'Unknown';
    
    // If the display name looks like a number, try to get a contact name
    if (RegExp(r'^\d+$').hasMatch(displayName.replaceAll(RegExp(r'\s+'), ''))) {
       displayName = contactService.getContactName(displayName);
    } else if (displayName.contains('uknown') || displayName.contains('M-Pesa User')) {
      // Sometimes MpesaParser returns these fallbacks if it can't find a sender/recipient
      // its better to check the raw message if we have the number there, 
      
    }
    
    final isExpense = transaction.type == 'outbound' || transaction.type == 'withdrawal';
    final isIncome = transaction.type == 'inbound' || transaction.type == 'deposit';
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
                color: isExpense ? Colors.red.shade700 : (isIncome ? Colors.green.shade700 : Colors.black87),
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.rawSmsMessage ?? "No raw message available for this transaction.",
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
                      const Text("Reference", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(transaction.mpesaReference!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

    IconData _getIcon(){
      switch(transaction.type){
        case 'inbound':
        return Icons.arrow_downward;
        case 'withdrawal':
        return Icons.local_atm;
        case 'deposit':
        return Icons.account_balance;
        case 'outbound':
        default:
          final vendor = (transaction.vendor ?? transaction.description ?? '').toLowerCase();

          if (vendor.contains('food') || vendor.contains('restaurant') || vendor.contains('cafe') || vendor.contains('hotel')){
            return Icons.fastfood;
          }
          if (vendor.contains('shop') || vendor.contains('store') || vendor.contains('market')){
            return Icons.shopping_bag;
          }
          if (vendor.contains('uber') || vendor.contains('bolt') || vendor.contains('taxi') || vendor.contains('transport')){
            return Icons.local_taxi;
          }
          if (vendor.contains('fuel') || vendor.contains('petrol')){
            return Icons.local_gas_station;
          }
          if (vendor.contains('electric') || vendor.contains('kplc') || vendor.contains('water') || vendor.contains('bill')){
            return Icons.receipt;
          }
          return Icons.payments;
      }
    }

    String _formatDate(DateTime? date){

      if (date == null) return 'No date';
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0){
        return 'Today ${date.hour}: ${date.minute.toString().padLeft(2, '0')}';
      }
      else if(difference.inDays ==1){
        return 'Yesterday';
      }
      else if(difference.inDays <7){
        return '${difference.inDays} days ago';
      }
      else{
        return '${date.day}/${date.month}/${date.year}';
      }
    }

}
