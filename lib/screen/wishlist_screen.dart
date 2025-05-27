import 'package:flutter/material.dart';
import '../widgets/wishlist_header.dart';
import '../widgets/wishlist_item.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> wishlistItems = [
    {
      'namaProduk': 'Royal Canin Sensible Adult Dry Cat Food',
      'namaToko': 'Cilok Pet Store',
      'harga': 'Rp350.128',
      'storeImageUrl': 'assets/images/icons/cilok.png',
      'productImageUrls': ['assets/images/products/royal_canin.png'],
      'isDoubleImage': false,
    },
    {
      'namaProduk': 'PETKIT YumShare Gemini Dual-hopper with Camera Smart Pet Feeder - Feeder',
      'namaToko': 'PETKIT Indonesia',
      'harga': 'Rp2.580.000',
      'storeImageUrl': 'assets/images/icons/petkit.png',
      'productImageUrls': ['assets/images/products/petkit_feeder.png'],
      'isDoubleImage': false,
    },
    {
      'namaProduk': 'Ceramic Pet Bowl',
      'namaToko': 'Pet-ority',
      'harga': 'Rp250.200',
      'storeImageUrl': 'assets/images/icons/pet-ority.png',
      'productImageUrls': ['assets/images/products/ceramic.png'],
      'isDoubleImage': false,
    },
  ];

  void removeItem(int index) {
    setState(() {
      wishlistItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const WishlistHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  return WishlistItem(
                    namaProduk: item['namaProduk'],
                    namaToko: item['namaToko'],
                    harga: item['harga'],
                    storeImageUrl: item['storeImageUrl'],
                    productImageUrls: item['productImageUrls'],
                    isDoubleImage: item['isDoubleImage'],
                    onRemove: () => removeItem(index),
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
