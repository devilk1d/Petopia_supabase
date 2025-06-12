import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/promo_model.dart';
import '../services/promo_service.dart';

class PromosOffersScreen extends StatefulWidget {
  const PromosOffersScreen({super.key});

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
    try {
      final result = await PromoService.getActivePromos();
      if (mounted) {
        setState(() {
          promos = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat promo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> backgroundColors = [
      const Color(0xFFFF5D39),
      const Color(0xFFFF7043),
      const Color(0xFFFF8A65),
      const Color(0xFFFFA726),
      const Color(0xFFFFCA28),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Promos & Offers',
          // [TIPOGRAFI] Ukuran dan ketebalan font disesuaikan
          style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : promos.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada promo yang tersedia saat ini.',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: promos.length,
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      final bgColor =
                          backgroundColors[index % backgroundColors.length];
                      final discountText = promo.discountType == 'percentage'
                          ? '${promo.discountValue.toInt()}% OFF'
                          : 'Rp ${promo.discountValue.toInt()} OFF';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              bgColor.withOpacity(0.9),
                              bgColor.withOpacity(0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promo.title,
                                  // [TIPOGRAFI] Ukuran diperbesar, tebal=semi-bold
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  discountText,
                                  // [TIPOGRAFI] Paling menonjol: besar dan extra-bold
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  promo.description ?? '',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: promo.code));
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Kode promo di copy!',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            Colors.black.withOpacity(0.85),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.copy,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          promo.code,
                                          // [TIPOGRAFI] Font lebih besar dan tebal
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Min. Rp ${promo.minPurchase ~/ 1000}rb\n${_formatDate(promo.startDate ?? DateTime.now())} - ${_formatDate(promo.endDate ?? DateTime.now())}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${monthNames[date.month - 1]}';
  }
}