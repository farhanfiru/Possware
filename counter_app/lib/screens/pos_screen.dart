import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_panel.dart';
import 'printer_settings_screen.dart';
import 'settings_screen.dart';
import 'daily_sales_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.point_of_sale, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Neyco POS',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        actions: [
          // Bluetooth Printer Status Indicator
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: billing.isPrinterConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: billing.isPrinterConnected ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    billing.isPrinterConnected ? Icons.print : Icons.print_disabled,
                    size: 16,
                    color: billing.isPrinterConnected ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    billing.isPrinterConnected ? 'Printer Ready' : 'No Printer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: billing.isPrinterConnected ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daily Sales Report
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFF0F172A)),
            tooltip: 'Sales Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailySalesScreen()),
              );
            },
          ),

          // App / Supabase Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(context, billing)
          : _buildMobileLayout(context, billing),
    );
  }

  // Tablet / Landscape Split Layout (2 Columns)
  Widget _buildTabletLayout(BuildContext context, BillingProvider billing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Menu Items & Search
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSearchBar(billing),
              CategorySelector(
                categories: billing.categories,
                selectedCategory: billing.selectedCategory,
                onSelectCategory: billing.selectCategory,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildMenuGrid(context, billing, crossAxisCount: 3),
              ),
            ],
          ),
        ),

        // Right Column: Cart & Checkout
        const SizedBox(
          width: 380,
          child: Padding(
            padding: EdgeInsets.only(top: 12, right: 12, bottom: 12),
            child: CartPanel(),
          ),
        ),
      ],
    );
  }

  // Mobile Phone Layout with Bottom Sheet Cart
  Widget _buildMobileLayout(BuildContext context, BillingProvider billing) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSearchBar(billing),
        CategorySelector(
          categories: billing.categories,
          selectedCategory: billing.selectedCategory,
          onSelectCategory: billing.selectCategory,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildMenuGrid(context, billing, crossAxisCount: 2),
        ),
        // Bottom Mobile Cart Bar
        if (billing.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${billing.totalItemCount} Items',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${billing.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SizedBox(
                        height: 600,
                        child: CartPanel(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('View Bill & Pay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BillingProvider billing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    billing.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        onChanged: billing.setSearchQuery,
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, BillingProvider billing, {required int crossAxisCount}) {
    if (billing.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (billing.menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No menu items found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: billing.fetchMenu,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
        ),
        itemCount: billing.menuItems.length,
        itemBuilder: (context, index) {
          final item = billing.menuItems[index];
          final inCartItems = billing.cart.where((c) => c.menuItem.id == item.id);
          final inCartCount = inCartItems.isNotEmpty ? inCartItems.first.quantity : 0;

          return MenuItemCard(
            item: item,
            inCartCount: inCartCount,
            onAdd: () => billing.addToCart(item),
            onIncrement: () => billing.incrementQuantity(item.id),
            onDecrement: () => billing.decrementQuantity(item.id),
          );
        },
      ),
    );
  }
}
