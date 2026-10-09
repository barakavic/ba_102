import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_appbar.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_total.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShoppingListDetailsPage extends ConsumerStatefulWidget {
  final ShoppingListModel list;
  const ShoppingListDetailsPage({super.key, required this.list});

  @override
  ConsumerState<ShoppingListDetailsPage> createState() =>
      _ShoppingListDetailsPageState();
}

class _ShoppingListDetailsPageState
    extends ConsumerState<ShoppingListDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  String _searchQuery = '';
  bool _hasUnsavedChanges = false;

  Color get _listColor {
    if (widget.list.colorSwatch != null) {
      return Color(widget.list.colorSwatch!);
    }
    return const Color(0xFF4B0082);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _saveChanges() {
    setState(() {
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      // TODO: Change from a SnackBar to a Dialog
      const SnackBar(
        content: Text('Changes Saved Successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listId = widget.list.id;
    final itemsAsync = listId == null
        ? const AsyncValue<List<ShoppingListItemModel>>.data([])
        : ref.watch(shoppingListItemsProvider(listId));

    return Scaffold(
      appBar: ShoppingListDetailAppBar(
        title: widget.list.title ?? 'Shopping Budget',
        isSearching: _isSearching,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        hasUnsavedChanges: _hasUnsavedChanges,
        onSearchToggle: _toggleSearch,
        onSearchChanged: _onSearchChanged,
        onSave: _saveChanges,
      ),
      body: itemsAsync.when(
        data: (items) {
          final filteredItems = _searchQuery.isEmpty
              ? items
              : items.where((item) {
                  final nameMatches =
                      item.name.toLowerCase().contains(_searchQuery);
                  final catMatches = item.category != null &&
                      item.category!.toLowerCase().contains(_searchQuery);
                  return nameMatches || catMatches;
                }).toList();

          final currentTotal = items.fold<double>(
            0.0,
            (sum, item)=> sum + (item.estimatedPrice * item.quantity),
          );

          return Column(
            children: [
              ShoppingListDetailTotal(
                total: currentTotal, 
                budgetLimit: widget.list.budgetLimit,
                accentColor: _listColor, 
                onAddCategory: (){
                  // Category Add Action Placeholder
                },),


                Expanded(child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: _listColor,
                          size: 48,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          _isSearching ? 'Searching: $_searchQuery' : 
                          'Clean Slate Ready',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700
                          ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            _isSearching ? '${filteredItems.length} matching items found' : 
                            '${items.length} item(s) loaded from storage',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                            ),
                            
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          OutlinedButton.icon(
                          onPressed: (){
                            setState(() {
                              _hasUnsavedChanges = !_hasUnsavedChanges;
                            });

                          },
                          icon: Icon(
                            _hasUnsavedChanges ? Icons.check_circle_outline:
                            Icons.edit_outlined
                          ),
                          label: Text(
                            _hasUnsavedChanges ?
                            'Simulate Has Changes (Save Button Visible)': // Placeholder
                            'Simulate: Clean (Save Button Hidden)',
                          ),
                          )

                      ],
                    ),
                    ),

                    
                ))
            ],

          );
          
           },
        error: (err, st) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}