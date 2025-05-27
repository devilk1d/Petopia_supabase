import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'package:dotted_border/dotted_border.dart';
import 'user_profile.dart';
import 'store_management_screen.dart';
import 'dart:async';  // Add this import for StreamSubscription

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _householdProfiles = [];
  List<Map<String, dynamic>> _storeProfiles = [];
  Map<String, dynamic>? _currentUser;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _subscribeToUserProfile();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToUserProfile() {
    try {
      _userSubscription = UserService.subscribeToUserProfile().listen(
        (userData) {
          if (mounted) {
            setState(() {
              _currentUser = userData;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          print('Error in user subscription: $error');
        },
      );
    } catch (e) {
      print('Error setting up user subscription: $e');
    }
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user first
      final currentUser = await UserService.getCurrentUserProfile();
      final storeProfiles = await UserService.getUserStores();

      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _storeProfiles = storeProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profiles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await UserService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal keluar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoginCard({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade100,
            ),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(20),
              color: Colors.grey.shade300,
              strokeWidth: 2,
              dashPattern: const [6, 4],
              child: Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Login',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isStore = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade100,
            ),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(20),
              color: Colors.grey.shade300,
              strokeWidth: 2,
              dashPattern: const [6, 4],
              child: Center(
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.getCurrentUserId() != null;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isLoggedIn)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: _handleSignOut,
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFBF0055),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // User Profiles Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB60051).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFFB60051),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'User Profiles',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User profiles grid
                      if (isLoggedIn && _currentUser != null)
                        GestureDetector(
                          onTap: () async {
                            final wasUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfile(),
                              ),
                            );
                            // Refresh data if profile was updated
                            if (wasUpdated == true) {
                              _loadProfiles();
                            }
                          },
                          child: _buildProfileCard(
                            _currentUser!['profile_image_url'] ?? '',
                            _currentUser!['full_name'] ?? _currentUser!['username'] ?? 'Unnamed',
                            isLoggedIn: true,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/user-profile',
                                arguments: {'userId': _currentUser!['id']},
                              );
                            },
                          ),
                        )
                      else if (!isLoggedIn)
                        _buildLoginCard(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                        )
                      else
                        _buildAddCard(
                          title: 'Add Profile',
                          icon: Icons.person_add_rounded,
                          onTap: () => Navigator.pushNamed(context, '/add-profile'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Store Profiles Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15326A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Color(0xFF15326A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Store Profiles',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Store profile content
                      if (!isLoggedIn)
                        _buildLoginCard(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                        )
                      else if (_storeProfiles.isEmpty)
                        _buildAddCard(
                          title: 'Add Store',
                          icon: Icons.add_business_rounded,
                          onTap: () => Navigator.pushNamed(context, '/register-toko'),
                          isStore: true,
                        )
                      else
                        Row(
                          children: [
                            _buildStoreCard(
                              _storeProfiles.first['store_image_url'] ?? '',
                              _storeProfiles.first['store_name'] ?? 'Unnamed Store',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoreManagementScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildAddCard(
                              title: 'Add Store',
                              icon: Icons.add_business_rounded,
                              onTap: () => Navigator.pushNamed(context, '/register-toko'),
                              isStore: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About Us Section
                _buildAboutUsSection(),

                const SizedBox(height: 40), // Space for bottom nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String imageUrl, String name, {
    required bool isLoggedIn,
    required VoidCallback onTap,
  }) {
    // Get the first letter of the name for the default avatar
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // Generate a consistent color based on the name
    final color = Colors.primaries[name.isEmpty ? 0 : name.hashCode % Colors.primaries.length];

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: imageUrl.isEmpty ? color.withOpacity(0.2) : Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              firstLetter,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoggedIn)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(String imageUrl, String name, {
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey.shade400,
                          );
                        },
                      )
                    : Icon(
                        icon ?? Icons.store,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMember(
      String imageUrl,
      String id,
      String name,
      String className,
      BuildContext context, {
        double imageWidth = 140,
        double imageHeight = 190,
      }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 248, 248, 1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background container (data)
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            margin: const EdgeInsets.only(right: 0),
            padding: const EdgeInsets.only(
              left: 20,
              right: 140, // Ruang untuk gambar
              top: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    id,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SF Pro Display',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBF0055).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    className,
                    style: const TextStyle(
                      color: Color(0xFFBF0055),
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating image (di kanan)
          Positioned(
            right: 10,
            top: -10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imageUrl,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tambahkan bagian About Us ke dalam build method setelah Store Profiles Section
  Widget _buildAboutUsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Us',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'SF Pro Display',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Kami adalah para sigma male, skibidi, rizz, +100000 aura',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          _buildAboutMember(
            'assets/images/aufa.png',
            '2307413014',
            'Aufa Kautsar\nAhmad',
            'TI 4 MSU',
            context,
            imageWidth: 140,
            imageHeight: 165,
          ),
          const SizedBox(height: 16),
          _buildAboutMember(
            'assets/images/cilok.png',
            '2307413003',
            'Rizqi Asan\nMasika',
            'TI 4 MSU',
            context,
            imageWidth: 140,
            imageHeight: 165,
          ),
          const SizedBox(height: 16),
          _buildAboutMember(
            'assets/images/ibnu.png',
            '2307413019',
            'Ibnu Dwito\nAbimanyu',
            'TI 4 MSU',
            context,
            imageWidth: 160,
            imageHeight: 165,
          ),
        ],
      ),
    );
  }
}
