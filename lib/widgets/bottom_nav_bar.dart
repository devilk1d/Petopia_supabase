import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/cart_service.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  void initState() {
    super.initState();
    // Initialize cart subscription
    CartService.initCartSubscription();
  }

  @override
  void dispose() {
    CartService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Total height including the portion of cart button that sticks out
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom navigation bar background with more rounded corners
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 65, // Height of the actual navbar
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Navigation items with improved layout
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, 'assets/images/icons/home_icon.png', 'Home', widget.selectedIndex == 0),
                  _buildNavItem(1, 'assets/images/icons/menu_icon.png', 'Article', widget.selectedIndex == 1),
                  // Empty space for cart
                  const SizedBox(width: 60),
                  _buildNavItem(3, 'assets/images/icons/notification_icon.png', 'Orders', widget.selectedIndex == 3),
                  _buildNavItem(4, 'assets/images/icons/profile_icon.png', 'Profile', widget.selectedIndex == 4),
                ],
              ),
            ),
          ),

          // Centered cart button with improved styling
          Positioned(
            top: 0, // Position at top to make it stick out
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4), // Creates white gap around the circle
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildCartItem(2, widget.selectedIndex == 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: isSelected ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: isSelected ? AppColors.primaryColor : Colors.grey[400],
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icons if asset not found
                      IconData fallbackIcon = Icons.home_outlined;
                      if (iconPath.contains('menu')) fallbackIcon = Icons.article_outlined;
                      if (iconPath.contains('notification')) fallbackIcon = Icons.list_alt_outlined;
                      if (iconPath.contains('profile')) fallbackIcon = Icons.person_outline;

                      return Icon(
                        fallbackIcon,
                        size: 24,
                        color: isSelected ? AppColors.primaryColor : Colors.grey[400],
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryColor : Colors.grey[400],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated container for cart button
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: isSelected ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/icons/cart_icon.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.shopping_cart_outlined,
                              size: 24,
                              color: Colors.white,
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cart',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Cart badge with item count
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: CartService.cartStream,
            builder: (context, snapshot) {
              int totalQuantity = 0;
              if (snapshot.hasData) {
                for (var item in snapshot.data!) {
                  totalQuantity += item['quantity'] as int;
                }
              }
              
              if (totalQuantity == 0) {
                return const SizedBox.shrink();
              }

              return Positioned(
                right: 0,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      totalQuantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}