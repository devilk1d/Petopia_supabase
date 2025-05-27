import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image
                Stack(
                  children: [
                    // Article image
                    SizedBox(
                      width: double.infinity,
                      height: 350,
                      child: Image.network(
                        'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.green[300]);
                        },
                      ),
                    ),

                    // White curved overlay at the bottom of the image
                    Positioned(
                      bottom: -7,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Category pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Cat',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Article title
                const Padding(
                  padding: EdgeInsets.fromLTRB(30, 15, 30, 10),
                  child: Text(
                    'Kucing: Hewan Peliharaan yang Menggemaskan',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ),

                // Author information
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      // Author avatar
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=rizqi'),
                      ),
                      SizedBox(width: 8),
                      // Author name
                      Text(
                        'Rizqi Asan',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Article content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Introduction
                      const Text(
                        'Kucing adalah salah satu hewan peliharaan paling populer di dunia. Mereka memiliki sifat unik, mulai dari pemalu hingga aktif dan penuh rasa ingin tahu.',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Cat breeds section
                      const Text(
                        'Jenis Kucing',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Beberapa ras kucing yang terkenal meliputi:',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Bullet points for cat breeds
                      _buildBulletPoint('Persia – Bulu panjang, wajah datar.'),
                      _buildBulletPoint('Maine Coon – Besar, berbulu tebal.'),
                      _buildBulletPoint('Siamese – Ramping, bermata biru.'),

                      const SizedBox(height: 20),

                      // Cat care section
                      const Text(
                        'Perawatan Kucing',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Untuk menjaga kesehatan dan kebahagiaan kucing:',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Bullet points for cat care
                      _buildBulletPoint('Berikan makanan bernutrisi.'),
                      _buildBulletPoint('Jaga kebersihan tempat tinggalnya.'),
                      _buildBulletPoint('Periksakan ke dokter hewan secara rutin.'),
                      _buildBulletPoint('Ajak bermain agar tidak stres.'),

                      const SizedBox(height: 20),

                      // Conclusion
                      const Text(
                        'Kucing adalah teman setia yang membawa kebahagiaan bagi pemiliknya. Dengan perawatan yang baik, mereka bisa hidup sehat dan bahagia.',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back button - top left corner with safe area consideration
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}