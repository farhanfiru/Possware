import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../theme/app_theme.dart';
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
    final isTablet = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.cardBorder, height: 1),
        ),
        title: Row(
          children: [
            // Branded "N" Burgundy Badge (matches Owner Dashboard)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBurgundy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'NEYCO POS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Bluetooth Thermal Printer Status Chip
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: billing.isPrinterConnected ? AppTheme.cashGreenLight : AppTheme.errorRedLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: billing.isPrinterConnected ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      billing.isPrinterConnected ? Icons.print : Icons.print_disabled,
                      size: 14,
                      color: billing.isPrinterConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      billing.isPrinterConnected ? 'Printer Ready' : 'No Printer',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: billing.isPrinterConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Daily Sales Report Navigation
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.textDark, size: 22),
            tooltip: 'Sales Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailySalesScreen()),
              );
            },
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
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
              const SizedBox(height: 10),
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
            padding: EdgeInsets.only(top: 14, right: 14, bottom: 14),
            child: CartPanel(),
          ),
        ),
      ],
    );
  }

  // Mobile Phone Layout with Bottom Sheet Cart
  Widget _buildMobileLayout(BuildContext context, BillingProvider billing) {
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
              color: AppTheme.surfaceWhite,
              border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${billing.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
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
                  icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                  label: const Text('View Bill & Pay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
        decoration: InputDecoration(
          hintText: 'Search dishes, drinks, or items...',
          hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    billing.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: billing.setSearchQuery,
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, BillingProvider billing, {required int crossAxisCount}) {
    if (billing.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBurgundy),
      );
    }

    if (billing.menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu, size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              'No menu items found',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryBurgundy,
      onRefresh: billing.fetchMenu,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.32,
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
