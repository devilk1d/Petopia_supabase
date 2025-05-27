import 'package:flutter/material.dart';
import '../utils/colors.dart';

class OrderItemWidget extends StatelessWidget {
  final String storeName;
  final List<String> productImages;
  final String productName;
  final String productVariant;
  final String price;
  final int quantity;
  final bool isSmallScreen;
  final VoidCallback onAddNote;

  const OrderItemWidget({
    Key? key,
    required this.storeName,
    required this.productImages,
    required this.productName,
    required this.productVariant,
    required this.price,
    required this.quantity,
    required this.isSmallScreen,
    required this.onAddNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store name with icon
        Row(
          children: [
            Icon(Icons.store_rounded, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              storeName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Product details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                productImages.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Product information column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Product variant if available
                  if (productVariant.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        productVariant,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Price and quantity row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),

                      // Quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Qty: $quantity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Shipping option card - Now clickable
        GestureDetector(
          onTap: () => _showShippingOptions(context),
          child: _buildShippingOption(),
        ),

        const SizedBox(height: 12),

        // Add note button - Now using the context for the pop-up
        GestureDetector(
          onTap: () => _showAddNoteDialog(context),
          child: _buildAddNoteButton(),
        ),
      ],
    );
  }

  void _showShippingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShippingOptionsBottomSheet(),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(),
    );
  }

  Widget _buildShippingOption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Free shipping tag and standard shipping text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E7C48).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GRATIS ONGKIR',
                  style: TextStyle(
                    color: Color(0xFF1E7C48),
                    fontFamily: 'SF Pro Display',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: 'Standard (Rp.0 '),
                    TextSpan(
                      text: 'Rp 11.000',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xFF909090),
                      ),
                    ),
                    TextSpan(text: ')'),
                  ],
                ),
              ),
            ],
          ),

          // Arrow icon
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[600],
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildAddNoteButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notes, color: Colors.grey[700], size: 16),
          const SizedBox(width: 8),
          const Text(
            'Tambahkan Catatan',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Shipping Options Bottom Sheet
class ShippingOptionsBottomSheet extends StatefulWidget {
  @override
  _ShippingOptionsBottomSheetState createState() => _ShippingOptionsBottomSheetState();
}

class _ShippingOptionsBottomSheetState extends State<ShippingOptionsBottomSheet> {
  int selectedCourierIndex = 0;

  // Sample courier data
  final List<CourierOption> couriers = [
    CourierOption(
      name: 'JNE',
      imageAsset: 'assets/images/kurir/jne.png',
      services: [
        ShippingService(
          name: 'REG (Reguler)',
          price: 11000,
          estimatedDays: '2-3',
          hasPromo: true,
        ),
        ShippingService(
          name: 'YES (Yakin Esok Sampai)',
          price: 18000,
          estimatedDays: '1',
          hasPromo: false,
        ),
      ],
    ),
    CourierOption(
      name: 'SiCepat',
      imageAsset: 'assets/images/kurir/sicepat.png',
      services: [
        ShippingService(
          name: 'REG (Reguler)',
          price: 10000,
          estimatedDays: '2-3',
          hasPromo: true,
        ),
        ShippingService(
          name: 'BEST (Besok Sampai)',
          price: 17000,
          estimatedDays: '1',
          hasPromo: false,
        ),
      ],
    ),
    CourierOption(
      name: 'J&T',
      imageAsset: 'assets/images/kurir/jnt.png',
      services: [
        ShippingService(
          name: 'Ekonomi',
          price: 9000,
          estimatedDays: '3-4',
          hasPromo: true,
        ),
        ShippingService(
          name: 'Express',
          price: 15000,
          estimatedDays: '1-2',
          hasPromo: false,
        ),
      ],
    ),
    CourierOption(
      name: 'AnterAja',
      imageAsset: 'assets/images/kurir/anteraja.jpg',
      services: [
        ShippingService(
          name: 'Reguler',
          price: 10500,
          estimatedDays: '2-3',
          hasPromo: true,
        ),
        ShippingService(
          name: 'Next Day',
          price: 16500,
          estimatedDays: '1',
          hasPromo: false,
        ),
      ],
    ),
  ];

  int? selectedServiceIndex;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Pengiriman',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Courier tabs
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: couriers.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCourierIndex = index;
                              selectedServiceIndex = null;
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedCourierIndex == index
                                    ? AppColors.primaryColor
                                    : Colors.grey[300]!,
                                width: selectedCourierIndex == index ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: selectedCourierIndex == index
                                  ? AppColors.primaryColor.withOpacity(0.05)
                                  : Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Using icons instead of images for this example
                                Image.asset(
                                  couriers[index].imageAsset,
                                  width: 30,
                                  height: 30,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.local_shipping,
                                      color: selectedCourierIndex == index
                                          ? AppColors.primaryColor
                                          : Colors.grey[600],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  couriers[index].name,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selectedCourierIndex == index
                                        ? AppColors.primaryColor
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Shipping services for selected courier
                  ...couriers[selectedCourierIndex].services.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final service = entry.value;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedServiceIndex = idx;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedServiceIndex == idx
                                ? AppColors.primaryColor
                                : Colors.grey[200]!,
                            width: selectedServiceIndex == idx ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: selectedServiceIndex == idx
                              ? AppColors.primaryColor.withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Radio button
                            Radio<int>(
                              value: idx,
                              groupValue: selectedServiceIndex,
                              activeColor: AppColors.primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  selectedServiceIndex = value;
                                });
                              },
                            ),

                            // Service details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Service name and estimated days
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        service.name,
                                        style: const TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Estimasi ${service.estimatedDays} hari',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // Price with promo if available
                                  if (service.hasPromo)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E7C48).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'GRATIS ONGKIR',
                                            style: TextStyle(
                                              color: Color(0xFF1E7C48),
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Rp 0',
                                          style: const TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Rp ${service.price}',
                                          style: const TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                            color: Color(0xFF909090),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Rp ${service.price}',
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedServiceIndex != null
                      ? () {
                    // Here you would typically save the selected shipping option
                    Navigator.of(context).pop();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Add Note Dialog
class AddNoteDialog extends StatefulWidget {
  @override
  _AddNoteDialogState createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambahkan Catatan',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Note text field
            TextField(
              controller: _noteController,
              maxLines: 5,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tuliskan catatan untuk penjual...',
                hintStyle: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Here you would typically save the note
                  Navigator.of(context).pop(_noteController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

// Data Models
class CourierOption {
  final String name;
  final String imageAsset;
  final List<ShippingService> services;

  CourierOption({
    required this.name,
    required this.imageAsset,
    required this.services,
  });
}

class ShippingService {
  final String name;
  final int price;
  final String estimatedDays;
  final bool hasPromo;

  ShippingService({
    required this.name,
    required this.price,
    required this.estimatedDays,
    required this.hasPromo,
  });
}