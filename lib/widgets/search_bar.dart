import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const CustomSearchBar({
    Key? key,
    this.hintText = 'Cari Barang di Petopia',
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.controller,
    this.suffixIcon,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isLocalController = true;
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      // Non-functional search bar (like the original)
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.greyColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.hintText,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: widget.suffixIcon ??
                      Image.asset(
                        'assets/images/icons/search_icon.png',
                        width: 20,
                        height: 20,
                        color: Colors.black,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.black,
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Functional search bar
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.greyColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: widget.suffixIcon ??
                  Image.asset(
                    'assets/images/icons/search_icon.png',
                    width: 20,
                    height: 20,
                    color: Colors.black,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.black,
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}