import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({Key? key}) : super(key: key);

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  int selectedAddressIndex = 1; // misal: default awal di index 1 (Rumah)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Daftar Alamat',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Tambah Lokasi Baru Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD30065),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/pointer_map.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                title: const Text(
                  'Tambah Lokasi Baru',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.of(context).pushNamed('/address-edit');
                },
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari Alamat...',
                  hintStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // List of Addresses
          _buildAddressCard(
            context,
            index: 0,
            title: 'Kantor',
            name: 'Abim',
            address: 'Jl. Mohammad Kahfi II Gg.Jambu No.123\nRT 09 / RW 01, Jagakarsa, Jakarta Selatan',
            phone: '+62 811-1014-502',
            icon: Icons.work_rounded,
            mapAsset: 'assets/images/map.png',
          ),
          _buildAddressCard(
            context,
            index: 1,
            title: 'Rumah',
            name: 'Asan',
            address: 'Jl. Pengadegan Selatan No.5, RT.1/RW.4,\nPengadegan, Kec. Pancoran, Kota Jakarta Selatan',
            phone: '+62 877-7120-4269',
            icon: Icons.home_rounded,
            mapAsset: 'assets/images/map.png',
          ),
          _buildAddressCard(
            context,
            index: 2,
            title: 'Rumah Nenek',
            name: 'Aufa',
            address: 'KP Sabi No. 2-3 002/002 Kel.Bencongan\nKec.Kelapa Dua Kab.Tangerang',
            phone: '+62 851-8301-3469',
            icon: Icons.home_rounded,
            mapAsset: 'assets/images/map.png',
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
      BuildContext context, {
        required int index,
        required String title,
        required String name,
        required String address,
        required String phone,
        required IconData icon,
        required String mapAsset,
      }) {
    final isDefault = selectedAddressIndex == index;
    final iconColor = isDefault ? const Color(0xFFD30065) : const Color(0xFFAEAEAE);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDefault ? const Color(0xFFD30065) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                if (isDefault)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD30065),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: iconColor,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  icon,
                                  color: iconColor,
                                ),
                              ),
                              if (isDefault)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: iconColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 120,
                          child: Stack(
                            children: [
                              Image.asset(
                                mapAsset,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              const Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: Color(0xFFD30065),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDefault ? const Color(0xFFD30065) : Colors.grey.shade300,
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      selectedAddressIndex = index;
                    });
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  child: Text(
                    'Ubah Alamat',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDefault ? const Color(0xFFD30065) : Colors.black,
                    ),
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