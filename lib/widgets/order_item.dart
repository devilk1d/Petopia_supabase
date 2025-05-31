import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/order_service.dart';

class OrderItemWidget extends StatelessWidget {
  final String storeName;
  final List<String> productImages;
  final String productName;
  final String productVariant;
  final String price;
  final int quantity;
  final bool isSmallScreen;
  final VoidCallback onAddNote;
  final Function(Map<String, dynamic>)? onShippingMethodSelected;
  final Function(double)? onShippingCostChanged;

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
    this.onShippingMethodSelected,
    this.onShippingCostChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store name with icon (only show if storeName is not empty)
        if (storeName.isNotEmpty) ...[
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
        ],

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

        // Shipping option card - Now using dynamic data
        GestureDetector(
          onTap: () => _showShippingOptions(context),
          child: _buildShippingOption(),
        ),

        const SizedBox(height: 12),

        // Add note button
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
      builder: (context) => ShippingOptionsBottomSheet(
        onShippingMethodSelected: (method) {
          if (onShippingMethodSelected != null) {
            onShippingMethodSelected!(method);
          }
          if (onShippingCostChanged != null) {
            final cost = (method['base_cost'] as num?)?.toDouble() ?? 0;
            onShippingCostChanged!(cost);
          }
        },
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        productName: productName,
      ),
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
              const Text(
                'Pilih Pengiriman',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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

// Dynamic Shipping Options Bottom Sheet
class ShippingOptionsBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>)? onShippingMethodSelected;

  const ShippingOptionsBottomSheet({
    Key? key,
    this.onShippingMethodSelected,
  }) : super(key: key);

  @override
  _ShippingOptionsBottomSheetState createState() => _ShippingOptionsBottomSheetState();
}

class _ShippingOptionsBottomSheetState extends State<ShippingOptionsBottomSheet> {
  List<Map<String, dynamic>> _shippingMethods = [];
  Map<String, dynamic>? _selectedMethod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShippingMethods();
  }

  Future<void> _loadShippingMethods() async {
    try {
      final methods = await OrderService.getShippingMethods();
      setState(() {
        _shippingMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shipping methods: $e')),
      );
    }
  }

  // Group shipping methods by courier (extract courier name from method name)
  Map<String, List<Map<String, dynamic>>> get _groupedMethods {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var method in _shippingMethods) {
      String methodName = method['name'] ?? '';
      String courierName = '';

      // Extract courier name from method name
      if (methodName.toLowerCase().contains('jne')) {
        courierName = 'JNE';
      } else if (methodName.toLowerCase().contains('sicepat')) {
        courierName = 'SiCepat';
      } else if (methodName.toLowerCase().contains('j&t')) {
        courierName = 'J&T';
      } else if (methodName.toLowerCase().contains('anteraja')) {
        courierName = 'AnterAja';
      } else {
        courierName = 'Lainnya';
      }

      if (!grouped.containsKey(courierName)) {
        grouped[courierName] = [];
      }
      grouped[courierName]!.add(method);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
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

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  ..._groupedMethods.entries.map((courierEntry) {
                    final courierName = courierEntry.key;
                    final methods = courierEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Courier header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _getCourierIcon(courierName),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                courierName,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Methods for this courier
                        ...methods.map((method) {
                          final isSelected = _selectedMethod == method;
                          final serviceName = _extractServiceName(method['name']);
                          final baseCost = (method['base_cost'] as num?)?.toDouble() ?? 0;
                          final hasPromo = baseCost <= 15000; // Free shipping if cost is low

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMethod = method;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? AppColors.primaryColor.withOpacity(0.05)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  // Radio button
                                  Radio<Map<String, dynamic>>(
                                    value: method,
                                    groupValue: _selectedMethod,
                                    activeColor: AppColors.primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMethod = value;
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
                                              serviceName,
                                              style: const TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _getEstimatedDays(method['type']),
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
                                        if (hasPromo)
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
                                              const Text(
                                                'Rp 0',
                                                style: TextStyle(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Rp ${baseCost.toStringAsFixed(0)}',
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
                                            'Rp ${baseCost.toStringAsFixed(0)}',
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

                        const SizedBox(height: 16),
                      ],
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
                  onPressed: _selectedMethod != null
                      ? () {
                    if (widget.onShippingMethodSelected != null) {
                      widget.onShippingMethodSelected!(_selectedMethod!);
                    }
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

  Widget _getCourierIcon(String courierName) {
    IconData icon;
    switch (courierName.toLowerCase()) {
      case 'jne':
        icon = Icons.local_shipping;
        break;
      case 'sicepat':
        icon = Icons.speed;
        break;
      case 'j&t':
        icon = Icons.delivery_dining;
        break;
      case 'anteraja':
        icon = Icons.motorcycle;
        break;
      default:
        icon = Icons.local_shipping;
    }

    return Icon(
      icon,
      color: AppColors.primaryColor,
      size: 20,
    );
  }

  String _extractServiceName(String fullName) {
    // Extract service name from full method name
    // e.g., "JNE Regular" -> "REG (Reguler)"
    // e.g., "JNE YES" -> "YES (Yakin Esok Sampai)"

    if (fullName.toLowerCase().contains('regular') || fullName.toLowerCase().contains('reg')) {
      return 'REG (Reguler)';
    } else if (fullName.toLowerCase().contains('yes')) {
      return 'YES (Yakin Esok Sampai)';
    } else if (fullName.toLowerCase().contains('best')) {
      return 'BEST (Besok Sampai)';
    } else if (fullName.toLowerCase().contains('ekonomi')) {
      return 'Ekonomi';
    } else if (fullName.toLowerCase().contains('express')) {
      return 'Express';
    } else if (fullName.toLowerCase().contains('next day')) {
      return 'Next Day';
    } else {
      // Fallback: use the part after the courier name
      List<String> parts = fullName.split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
      return fullName;
    }
  }

  String _getEstimatedDays(String? type) {
    switch (type?.toLowerCase()) {
      case 'express':
        return 'Estimasi 1 hari';
      case 'standard':
        return 'Estimasi 2-3 hari';
      case 'economy':
        return 'Estimasi 3-4 hari';
      default:
        return 'Estimasi 2-3 hari';
    }
  }
}

// Add Note Dialog (unchanged)
class AddNoteDialog extends StatefulWidget {
  final String productName;

  const AddNoteDialog({
    Key? key,
    required this.productName,
  }) : super(key: key);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambahkan Catatan',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.productName,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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