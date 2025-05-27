import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 640 ? 52 : 20,
        vertical: 8,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(41),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15.2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 54),
        child: Column(
          children: [
            const Text(
              'Pilih Profile',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: MediaQuery.of(context).size.width > 640 ? 18 : 10,
              runSpacing: 10,
              children: [
                _buildProfileItem(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/d731f784af846d745bc04b642d192ff3f96c3e61',
                  'Asan',
                  isLoggedIn: true,
                  context: context,
                ),
                _buildProfileItem(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/80ab00a7b3d2c0b120014afe3dfdec5662a889f9',
                  'Abim',
                  isLoggedIn: false,
                  context: context,
                ),
                _buildProfileItem(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/1610b54627790fc73167fb03f1123b180e1769e1',
                  'Aufa',
                  isLoggedIn: false,
                  context: context,
                ),
                _buildAddProfileItem(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String imageUrl, String name, {required bool isLoggedIn, required BuildContext context}) {
    final double imageSize = MediaQuery.of(context).size.width > 640 ? 125 : 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isLoggedIn)
          const Text(
            'Logged in',
            style: TextStyle(
              color: Color(0xFFFF4698),
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildAddProfileItem(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(
          '''
          <svg width="60" height="60" viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M30 3.75C23.0642 3.83416 16.4362 6.62679 11.5315 11.5315C6.62679 16.4362 3.83416 23.0642 3.75 30C3.83416 36.9358 6.62679 43.5638 11.5315 48.4685C16.4362 53.3732 23.0642 56.1658 30 56.25C36.9358 56.1658 43.5638 53.3732 48.4685 48.4685C53.3732 43.5638 56.1658 36.9358 56.25 30C56.1658 23.0642 53.3732 16.4362 48.4685 11.5315C43.5638 6.62679 36.9358 3.83416 30 3.75ZM45 31.875H31.875V45H28.125V31.875H15V28.125H28.125V15H31.875V28.125H45V31.875Z" fill="white"></path>
          </svg>
          ''',
          width: 60,
          height: 60,
        ),
        const SizedBox(height: 6),
        const Text(
          'Add Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}