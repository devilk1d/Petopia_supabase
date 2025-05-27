import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final int hours;
  final int minutes;
  final int seconds;

  const CountdownTimer({
    Key? key,
    required this.hours,
    required this.minutes,
    required this.seconds,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.hours * 3600 + widget.minutes * 60 + widget.seconds;

    // Set up pulse animation for seconds
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_totalSeconds > 0) {
          _totalSeconds--;
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Get time units for display
  String get _hoursString {
    final hours = _totalSeconds ~/ 3600;
    return hours.toString().padLeft(2, '0');
  }

  String get _minutesString {
    final minutes = (_totalSeconds % 3600) ~/ 60;
    return minutes.toString().padLeft(2, '0');
  }

  String get _secondsString {
    final seconds = _totalSeconds % 60;
    return seconds.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hours unit
          Expanded(
            flex: 1,
            child: _buildTimeUnit(_hoursString, 'Jam'),
          ),

          _buildSeparator(),

          // Minutes unit
          Expanded(
            flex: 1,
            child: _buildTimeUnit(_minutesString, 'Menit'),
          ),

          _buildSeparator(),

          // Seconds unit with pulse animation
          Expanded(
            flex: 1,  // Equal flex to ensure same width as other units
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildTimeUnit(_secondsString, 'Detik', isHighlighted: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label, {bool isHighlighted = false}) {
    return Column(
      children: [
        // Time value inside a decorative container
        Container(
          height: 60,
          width: double.infinity,  // Take full width of parent
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: isHighlighted ? 0.5 : 0,
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Label below time value
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Center(
        child: Text(
          ':',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}