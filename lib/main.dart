import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/splashscreen.dart';
import 'screen/home_page.dart';
import 'screen/article_screen.dart';
import 'screen/cart.dart';
import 'screen/transaction_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/onboarding_screen.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/product_detail_screen.dart';
import 'screen/payment.dart';
import 'screen/payment_berhasil.dart';
import 'screen/wishlist_screen.dart';
import 'screen/promo_screen.dart';
import 'screen/orderdetail_screen.dart';
import 'screen/checkout.dart';
import 'screen/rating_screen.dart';
import 'screen/user_profile.dart';
import 'screen/toko_profile.dart';
import 'screen/daftar_alamat_screen.dart';
import 'screen/data_alamat_screen.dart';
import 'screen/article_detail_screen.dart';
import 'screen/search_screen.dart'; // Import search screen
import 'widgets/bottom_nav_bar.dart';
import 'screen/register_toko.dart';
import 'screen/complaint_screen.dart';
import 'screen/notif_screen.dart';
import 'screen/category_product_screen.dart';
import 'services/supabase_config.dart';
import 'models/address_model.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Set preferred orientations (portrait only)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petopia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFBF0055),
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFBF0055),
          secondary: const Color(0xFFBF0055),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePageWrapper(),
        '/search': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return SearchScreen(
            initialQuery: args?['query'] as String?,
          );
        },
        '/product-detail': (context) => const ProductDetailPage(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CheckoutScreen(
            selectedItems: args['selectedItems'] as List<Map<String, dynamic>>,
          );
        },
        '/payment': (context) => const PaymentScreen(),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/wishlist': (context) => const WishlistScreen(),
        '/promos': (context) => const PromosOffersScreen(),
        '/order-detail': (context) => const OrderDetailScreen(),
        '/rating': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RatingScreen(
            productId: args['productId'],
            orderId: args['orderId'],
          );
        },
        '/user-profile': (context) => const UserProfile(),
        '/store-profile': (context) => const StoreProfile(),
        '/address-list': (context) => const AddressListScreen(),
        '/address-edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return AddressFormScreen(address: args is AddressModel ? args : null);
        },
        '/article-detail': (context) => const ArticleDetailPage(),
        '/register-toko': (context) => const RegisterTokoScreen(),
        '/complaint': (context) => const ComplaintScreen(),
        '/notif': (context) => const NotifScreen(),
        '/category-products': (context) => const CategoryProductsPage(),
      },
    );
  }
}

// Wrapper for HomePage with navigation state management
class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({Key? key}) : super(key: key);

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomePage(),
    const ArticlePage(),
    const CartScreen(),
    const TransactionScreen(),
    const ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we received a tab index argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int) {
      setState(() {
        _currentIndex = args;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}