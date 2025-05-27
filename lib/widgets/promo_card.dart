import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromoCard extends StatelessWidget {
  final Color backgroundColor;
  final String discountPercentage;
  final String promoCode;
  final Color promoCodeColor;
  final String discountIcon;
  final String vectorBackground;

  // Customization parameters
  final double? iconWidth;
  final double? iconHeight;
  final Offset? iconPosition;
  final double? iconOpacity;

  const PromoCard({
    Key? key,
    required this.backgroundColor,
    required this.discountPercentage,
    required this.promoCode,
    required this.promoCodeColor,
    required this.discountIcon,
    required this.vectorBackground,
    this.iconWidth,
    this.iconHeight,
    this.iconPosition,
    this.iconOpacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Vector background
          Positioned(
            right: -80,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                vectorBackground,
                width: 520,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 17.0, 120.0, 17.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Discount text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Up to',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          Text(
                            '$discountPercentage OFF',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          const Text(
                            'Package discount coupon',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Promo code button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: promoCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Promo code $promoCode copied to clipboard',
                              style: const TextStyle(fontFamily: 'SF Pro Display'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF108F6A), // Warna sukses
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(10),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 33,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons/tabler_copy5.png',
                          width: 20,
                          height: 20,
                          color: promoCodeColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          promoCode,
                          style: TextStyle(
                            color: promoCodeColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating icon - completely separate from content layout
          Positioned(
            top: iconPosition?.dy ?? 0,
            right: iconPosition?.dx ?? 0,
            child: Opacity(
              opacity: iconOpacity ?? 0.8,
              child: Image.asset(
                discountIcon,
                width: iconWidth ?? 150,
                height: iconHeight ?? 120,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}