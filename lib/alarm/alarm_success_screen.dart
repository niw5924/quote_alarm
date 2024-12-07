import 'dart:async';
import 'package:flutter/material.dart';

class AlarmSuccessScreen extends StatefulWidget {
  const AlarmSuccessScreen({super.key});

  @override
  _AlarmSuccessScreenState createState() => _AlarmSuccessScreenState();
}

class _AlarmSuccessScreenState extends State<AlarmSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // AnimationController 초기화
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // 애니메이션 지속 시간
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    // 2초 동안 애니메이션 실행 후 화면 닫기
    _controller.forward();
    Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _animation, // 페이드아웃 애니메이션
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '좋은 아침!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
