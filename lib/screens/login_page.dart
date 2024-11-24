import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // 현재 테마 모드 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black; // 다크 모드일 때는 흰색, 라이트 모드일 때는 검은색

    void signIn() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.signIn(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        // 로그인 성공 시 페이지 닫기
        Navigator.pop(context);
      } catch (e) {
        // 로그인 실패 처리
        print('로그인 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/image/gear.gif', // gear.gif 이미지 추가
              ),
              Text(
                'LOGIN',
                style: TextStyle(
                  color: textColor, // 테마에 맞는 텍스트 색상 적용
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                style: TextStyle(color: textColor), // 테마에 맞는 텍스트 색상 적용
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: textColor), // 테마에 맞는 아이콘 색상 적용
                  labelText: 'Email ID',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)), // 테마에 맞는 라벨 색상 적용
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05), // 다크/라이트 모드에 맞는 필 컬러 적용
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: textColor), // 테마에 맞는 텍스트 색상 적용
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: textColor), // 테마에 맞는 아이콘 색상 적용
                  labelText: 'Password',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)), // 테마에 맞는 라벨 색상 적용
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05), // 다크/라이트 모드에 맞는 필 컬러 적용
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6BF3B1), // 버튼 배경색
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(
                    color: Color(0xFF00796B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignupPage()),
                  );
                },
                child: Text(
                  'Sign Up', // 회원가입을 영어로 변경
                  style: TextStyle(
                    color: textColor.withOpacity(0.7), // 테마에 맞는 색상 적용
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
