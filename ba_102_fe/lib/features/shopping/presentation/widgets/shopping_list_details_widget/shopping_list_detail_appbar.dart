import 'package:flutter/material.dart';

class ShoppingListDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final bool hasUnsavedChanges;
  final bool isEditMode;
  final VoidCallback onSearchToggle;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSave;
  final VoidCallback? onToggleEdit;
  final bool hasActiveFilter;
  final VoidCallback? onFilter;
  final VoidCallback? onMore;
  final VoidCallback? onBack;

  const ShoppingListDetailAppBar({
    super.key,
    required this.title,
    required this.isSearching,
    required this.searchController,
    this.searchFocusNode,
    this.hasUnsavedChanges = false,
    this.isEditMode = true,
    this.hasActiveFilter = false,
    required this.onSearchToggle,
    this.onSearchChanged,
    this.onSave,
    this.onToggleEdit,
    this.onFilter,
    this.onMore,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: isSearching
          ? TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search In $title ... ',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: InputBorder.none,
              ),
            )
          : Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
      actions: [
        if (!isEditMode && onToggleEdit != null)
          IconButton(
            onPressed: onToggleEdit,
            tooltip: 'Edit List',
            icon: const Icon(Icons.edit_outlined),
          ),
        if (isEditMode && (onSave != null || onToggleEdit != null))
          IconButton(
            onPressed: onSave ?? onToggleEdit,
            tooltip: 'Done Editing',
            icon: const Icon(Icons.check),
          ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onFilter ?? () {},
              icon: Icon(
                hasActiveFilter
                    ? Icons.filter_list_rounded
                    : Icons.filter_list_outlined,
              ),
              tooltip: hasActiveFilter ? 'Filter (Active)' : 'Filter',
            ),
            if (hasActiveFilter)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          onPressed: onSearchToggle,
          icon: Icon(isSearching ? Icons.close : Icons.search),
          tooltip: isSearching ? 'Close Search' : 'Search',
        ),
        IconButton(
          onPressed: onMore ?? () {},
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
        ),
      ],
    );
  }
}
