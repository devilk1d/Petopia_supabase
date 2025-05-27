import 'package:flutter/material.dart';
import '../widgets/promo_card.dart';

class PromosOffersScreen extends StatelessWidget {
  const PromosOffersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and title in the same row
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/icons/black_back_icon.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Title centered relative to the remaining space
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Promos & Offers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),
            // Scrollable list of promo cards
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 40, left: 16, right: 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PromoCard(
                        backgroundColor: Color(0xFFFF5D39),
                        discountPercentage: '25%',
                        promoCode: 'ST-V2587',
                        promoCodeColor: Color(0xFFFF5E3A),
                        discountIcon: 'assets/images/icons/discount.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 190,
                        iconHeight: 259,
                        iconPosition: Offset(-20, -27),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 16),
                      PromoCard(
                        backgroundColor: Color(0xFF121C22),
                        discountPercentage: '40%',
                        promoCode: 'HS-23908',
                        promoCodeColor: Color(0xFF121C22),
                        discountIcon: 'assets/images/icons/kupon2.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 178,
                        iconHeight: 200,
                        iconPosition: Offset(-3, -20),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 16),
                      PromoCard(
                        backgroundColor: Color(0xFF15326A),
                        discountPercentage: '15%',
                        promoCode: 'PP-34JFO',
                        promoCodeColor: Color(0xFF15326A),
                        discountIcon: 'assets/images/icons/discount.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 190,
                        iconHeight: 259,
                        iconPosition: Offset(-20, -27),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 16),
                      PromoCard(
                        backgroundColor: Color(0xFF176B28),
                        discountPercentage: '5%',
                        promoCode: 'VM-LSDF0',
                        promoCodeColor: Color(0xFF176B28),
                        discountIcon: 'assets/images/icons/kupon2.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 178,
                        iconHeight: 200,
                        iconPosition: Offset(-3, -20),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 16),
                      PromoCard(
                        backgroundColor: Color(0xFF10332C),
                        discountPercentage: '65%',
                        promoCode: 'IS-MKF99',
                        promoCodeColor: Color(0xFF10332C),
                        discountIcon: 'assets/images/icons/discount.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 190,
                        iconHeight: 259,
                        iconPosition: Offset(-20, -27),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 16),
                      PromoCard(
                        backgroundColor: Color(0xFFB60051),
                        discountPercentage: '25%',
                        promoCode: 'LK-KS090',
                        promoCodeColor: Color(0xFFB60051),
                        discountIcon: 'assets/images/icons/kupon2.png',
                        vectorBackground: 'assets/images/icons/vector5.png',
                        // Customize icon independently
                        iconWidth: 178,
                        iconHeight: 200,
                        iconPosition: Offset(-3, -20),
                        iconOpacity: 1,
                      ),
                      SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}