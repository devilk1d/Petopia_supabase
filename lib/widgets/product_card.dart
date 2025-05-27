import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final double price;
  final double? originalPrice;
  final double discountPercentage;
  final double rating;
  final int reviewCount;
  final String storeName;
  final String storeLogoPath;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final String id;

  const ProductCard({
    Key? key,
    required this.imagePath,
    required this.name,
    required this.price,
    this.originalPrice,
    this.discountPercentage = 0,
    required this.rating,
    required this.reviewCount,
    required this.storeName,
    required this.storeLogoPath,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    required this.id,
  }) : super(key: key);

  // Format price with dots as thousand separators
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toInt()).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with consistent aspect ratio
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Discount tag with improved styling
                if (discountPercentage > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE02144),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${discountPercentage.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),

                // Favorite button with animation
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey<bool>(isFavorite),
                            size: 18,
                            color: isFavorite ? AppColors.primaryColor : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product details with improved spacing
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store info with consistent styling
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          storeLogoPath,
                          width: 16,
                          height: 16,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 16,
                              height: 16,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.store,
                                size: 10,
                                color: Colors.grey[700],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          storeName,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 1),

                  // Product name with consistent styling
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Rating stars with improved styling
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < rating.floor()
                                ? Icons.star
                                : (index < rating && index >= rating.floor()
                                ? Icons.star_half
                                : Icons.star_border),
                            color: const Color(0xFFFFA000),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${reviewCount})',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price section with improved layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current price with consistent styling
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (originalPrice != null)
                              Text(
                                'Rp${_formatPrice(originalPrice!)}',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                ),
                              ),
                            Text(
                              'Rp${_formatPrice(price)}',
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF108F6A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add to cart mini button
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(  // Change from Icon to IconButton
                          icon: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero, // Removes default padding
                          onPressed: () async {
                            try {
                              await CartService.addToCart(
                                productId: id,
                                quantity: 1,
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Added to cart',
                                        style: TextStyle(fontFamily: 'SF Pro Display'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF108F6A),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(10),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to cart: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(10),
                                ),
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}