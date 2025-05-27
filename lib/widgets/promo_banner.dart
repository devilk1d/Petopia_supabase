import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final Color backgroundColor;
  final String imagePath;

  const PromoBanner({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.backgroundColor,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Customize gradient based on banner type
    LinearGradient getGradient() {
      if (backgroundColor == AppColors.purpleBanner) {
        // Purple banner (cat banner)
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor,
            const Color(0xFF9340B8), // Slightly darker purple
          ],
        );
      } else if (backgroundColor == AppColors.orangeBanner) {
        // Orange banner (free shipping)
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor,
            const Color(0xFFECA42F), // Slightly different orange
          ],
        );
      } else if (backgroundColor == AppColors.greenBanner) {
        // Green banner (flash sale)
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor,
            const Color(0xFF5BD090), // Lighter green
          ],
        );
      } else {
        // Red banner (bonus points)
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            backgroundColor,
            const Color(0xFFFF686B), // Lighter red
          ],
        );
      }
    }

    // Different layout for different banner types
    Widget buildContent() {
      // Modified display for cat banner to properly split text
      if (imagePath.contains('cat_banner')) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nested Column for tightly spaced text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Use minimum space
                children: [
                  const Text(
                    'Diskon Spesial',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2, // Tighter line height
                    ),
                  ),
                  const Text(
                    'Pakan Kucing',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2, // Tighter line height
                    ),
                  ),
                  const Text(
                    '50%',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2, // Tighter line height
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5), // Small space before description
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6), // Space before button
              // Adjusted button size and padding to match design
              Container(
                height: 35, // Reduced height
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: backgroundColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12, // Smaller font size
                      fontWeight: FontWeight.w700,
                      color: backgroundColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Default layout for other banners
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: backgroundColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // Take only 80% of width
      height: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: getGradient(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow content to overflow
        children: [
          // Add background circular gradient for images
          if (!imagePath.contains('cat_banner') && !imagePath.contains('percent_icon'))
            Positioned(
              right: 20,
              bottom: 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

          // Content
          buildContent(),

          // Images with overflow - adjusted positioning to match design
          if (imagePath.contains('cat_banner'))
            Positioned(
              right: -30, // Adjusted position
              bottom: -30, // Adjusted position
              child: Image.asset(
                imagePath,
                height: 170, // Adjusted height
                fit: BoxFit.contain,
              ),
            )
          else if (imagePath.contains('clock_truck_icon'))
            Positioned(
              right: -25,
              bottom: 10,
              child: Image.asset(
                imagePath,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          else if (imagePath.contains('money_icon'))
              Positioned(
                right: -10,
                bottom: 10,
                child: Image.asset(
                  imagePath,
                  height: 170,
                  fit: BoxFit.contain,
                ),
              )
            else if (imagePath.contains('percent_icon'))
                Positioned(
                  right: -15,
                  bottom: -5,
                  child: Image.asset(
                    imagePath,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
        ],
      ),
    );
  }
}