import 'package:flutter/material.dart';
import '../widgets/promo_card.dart';
import '../services/promo_service.dart';
import '../models/promo_model.dart';

class PromosOffersScreen extends StatefulWidget {
  const PromosOffersScreen({Key? key}) : super(key: key);

  @override
  State<PromosOffersScreen> createState() => _PromosOffersScreenState();
}

class _PromosOffersScreenState extends State<PromosOffersScreen> {
  List<PromoModel> promos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPromos();
  }

  Future<void> loadPromos() async {
    final result = await PromoService.getActivePromos();
    setState(() {
      promos = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> backgroundColors = [
      Color(0xFFFF5D39),
      Color(0xFFFF7043),
      Color(0xFFFF8A65),
      Color(0xFFFFA726),
      Color(0xFFFFCA28),
      Color(0xFFFFD54F),
      Color(0xFFFFB74D),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Promos & Offers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: promos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final promo = promos[index];
                        final color = backgroundColors[index % backgroundColors.length];

                        // Format teks diskon
                        String discountText = '';
                        if (promo.discountType.toLowerCase() == 'percentage') {
                          discountText = 'Up to ${promo.discountValue.toStringAsFixed(0)}% OFF';
                        } else if (promo.discountType.toLowerCase() == 'nominal') {
                          discountText = 'Up to Rp ${promo.discountValue.toStringAsFixed(0)} OFF';
                        }

                        return PromoCard(
                          backgroundColor: color,
                          discountPercentage: discountText,
                          promoCode: promo.code,
                          promoCodeColor: Colors.black,
                          discountIcon: 'assets/images/icons/discount.png',
                          vectorBackground: 'assets/images/icons/vector5.png',
                          iconWidth: 190,
                          iconHeight: 259,
                          iconPosition: const Offset(-20, -27),
                          iconOpacity: 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
