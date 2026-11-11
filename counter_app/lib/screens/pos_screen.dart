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
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'POSWare',
              style: TextStyle(
                fontSize: 14.5,
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
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                );
                if (context.mounted) {
                  billing.refreshPrinterStatus();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 13, horizontal: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: billing.isPrinterConnected ? AppTheme.cashGreenLight : AppTheme.errorRedLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: billing.isPrinterConnected ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      billing.isPrinterConnected ? Icons.print : Icons.print_disabled,
                      size: 12,
                      color: billing.isPrinterConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      billing.isPrinterConnected
                          ? (billing.activePrinterCount > 1
                              ? 'Printers (${billing.activePrinterCount})'
                              : 'Printer')
                          : 'No Printer',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: billing.isPrinterConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Offline Pending Sync Badge
          if (billing.pendingOfflineCount > 0 || billing.isSyncing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: billing.isSyncing
                    ? null
                    : () async {
                        final count = await billing.syncOfflineOrdersNow();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(count > 0 ? 'Synced $count offline orders to cloud!' : 'Sync attempted. Waiting for connection.'),
                              backgroundColor: count > 0 ? AppTheme.cashGreen : AppTheme.primaryBurgundy,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 13, horizontal: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      billing.isSyncing
                          ? const SizedBox(
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFD97706)),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 11, color: Color(0xFFD97706)),
                      const SizedBox(width: 2.5),
                      Text(
                        billing.isSyncing ? 'Sync' : '${billing.pendingOfflineCount} Offline',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Daily Sales Report Navigation
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.textDark, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
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
          childAspectRatio: crossAxisCount > 2 ? 1.25 : 1.05,
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
