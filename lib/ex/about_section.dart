import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          const Text(
            'About Us',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'SF Pro Display',
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildMemberCard(
            'https://cdn.builder.io/api/v1/image/assets/TEMP/b2e3edb95f23e5a6755caf96df69e28349062711',
            '2307413003',
            'Rizqi Asan Masika',
            'TI 4 MSU',
            context,
          ),
          const SizedBox(height: 20),
          _buildMemberCard(
            'https://cdn.builder.io/api/v1/image/assets/TEMP/ff1447aa9ab2af460d9ed2a8fa25a443c54cfae4',
            '2307413014',
            'Aufa Kautsar Ahmad',
            'TI 4 MSU',
            context,
          ),
          const SizedBox(height: 20),
          _buildMemberCard(
            'https://cdn.builder.io/api/v1/image/assets/TEMP/8ff9cf60d59042266b39dcadb35230fbb1590600',
            '2307413019',
            'Ibnu Dwito Abimanyu',
            'TI 4 MSU',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      String imageUrl,
      String id,
      String name,
      String className,
      BuildContext context,
      ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 640 ? 47 : 20,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(170, 170, 170, 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.network(
            imageUrl,
            width: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SF Pro Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}