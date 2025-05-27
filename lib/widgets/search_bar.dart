// search_bar.dart - Adjusted to match sizes with promo and wishlist buttons - FIX #6
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46, // Adjusted height to match promo and wishlist buttons - FIX #6
      decoration: BoxDecoration(
        color: AppColors.greyColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text(
            'Cari Barang di Petopia',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const Spacer(),
          Container(
            width: 46, // Match height for circular appearance - FIX #6
            height: 46,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/icons/search_icon.png',
                width: 20,
                height: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}