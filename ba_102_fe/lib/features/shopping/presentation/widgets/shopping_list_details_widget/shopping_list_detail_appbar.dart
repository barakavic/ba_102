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
        // Save Button (visible when changes exist)
        if (hasUnsavedChanges)
          IconButton(
            onPressed: onSave,
            tooltip: 'Save Changes',
            icon: const Icon(Icons.save_outlined, color: Colors.green),
          )
        // Edit Mode Toggle Button (visible in view mode to re-enter edit mode)
        else if (!isEditMode && onToggleEdit != null)
          IconButton(
            onPressed: onToggleEdit,
            tooltip: 'Edit List',
            icon: const Icon(Icons.edit_outlined),
          ),

        IconButton(
          onPressed: onFilter ?? () {},
          icon: const Icon(Icons.filter_list_outlined),
          tooltip: 'Filter',
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
