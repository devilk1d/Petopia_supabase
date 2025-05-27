import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigasi ke HomePage setelah 3 detik
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 640;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotated cat image
            Positioned(
              top: isSmallScreen ? 230 : 250, // Adjust the position based on screen size
              child: Transform.rotate(
                angle: -37.652 * (math.pi / 5000), // Convert degrees to radians
                child: Image.asset(
                  'assets/images/cat lies on open books.png', // Adjust the image path
                  width: isSmallScreen ? 280 : 358,
                  height: isSmallScreen ? 260 : 340,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isSmallScreen ? 280 : 358,
                      height: isSmallScreen ? 260 : 340,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Image not available'),
                      ),
                    );
                  },
                ),
              ),
            ),

            // PETOPIA text
            Positioned(
              bottom: isSmallScreen ? 400 : 300, // Adjust text position
              child: Text(
                'PETOPIA',
                style: TextStyle(
                  color: const Color(0xFFBF0055),
                  fontFamily: 'Notable',
                  fontSize: isSmallScreen ? 40 : 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}