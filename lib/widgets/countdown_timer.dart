import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final int hours;
  final int minutes;
  final int seconds;
  final VoidCallback? onTick;

  const CountdownTimer({
    Key? key,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.onTick,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> with TickerProviderStateMixin {
  late int _totalSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.hours * 3600 + widget.minutes * 60 + widget.seconds;
    _initializeAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    // Pulse animation for when time is running low
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Scale animation for seconds
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_totalSeconds > 0) {
            _totalSeconds--;

            // Trigger scale animation on seconds
            _scaleController.forward().then((_) {
              _scaleController.reverse();
            });

            // Start pulsing when less than 5 minutes remaining
            if (_totalSeconds <= 300 && _totalSeconds > 0) {
              if (!_pulseController.isAnimating) {
                _pulseController.repeat(reverse: true);
              }
            } else {
              _pulseController.stop();
            }

            widget.onTick?.call();
          } else {
            _timer?.cancel();
            _pulseController.stop();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

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

  Color get _timerColor {
    if (_totalSeconds <= 300) return Colors.red[300]!; // Red when < 5 min
    if (_totalSeconds <= 1800) return Colors.orange[300]!; // Orange when < 30 min
    return Colors.white; // White otherwise
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _totalSeconds <= 300 ? _pulseAnimation.value : 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours unit
                  Expanded(
                    flex: 1,
                    child: _buildTimeUnit(_hoursString, 'JAM'),
                  ),

                  _buildSeparator(),

                  // Minutes unit
                  Expanded(
                    flex: 1,
                    child: _buildTimeUnit(_minutesString, 'MENIT'),
                  ),

                  _buildSeparator(),

                  // Seconds unit with scale animation
                  Expanded(
                    flex: 1,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: _buildTimeUnit(_secondsString, 'DETIK', isHighlighted: true),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeUnit(String value, String label, {bool isHighlighted = false}) {
    return Column(
      children: [
        // Time value inside a modern container
        Container(
          height: 48,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _timerColor,
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
            fontSize: 9,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Center(
        child: Text(
          ':',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}