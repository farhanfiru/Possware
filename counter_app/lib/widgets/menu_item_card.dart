import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int inCartCount;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.inCartCount,
    required this.onAdd,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final hasInCart = inCartCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasInCart ? AppTheme.primaryBurgundy : AppTheme.cardBorder,
              width: hasInCart ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasInCart
                    ? AppTheme.primaryBurgundy.withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Item Name & In-Cart Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (hasInCart)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBurgundy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$inCartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              // Middle: Category tag and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              // Bottom Action: Full-width Stepper / Add button
              if (hasInCart)
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildStepperBtn(
                        icon: Icons.remove,
                        onTap: onDecrement ?? () {},
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        iconColor: AppTheme.errorRed,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$inCartCount',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                      _buildStepperBtn(
                        icon: Icons.add,
                        onTap: onIncrement ?? () {},
                        color: AppTheme.primaryBurgundy,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBurgundy.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.primaryBurgundy,
                          size: 19,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ADD',
                          style: TextStyle(
                            color: AppTheme.primaryBurgundy,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
