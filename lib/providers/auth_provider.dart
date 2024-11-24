import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _checkAuthStatus();
  }

  // Firebase 인증 상태 확인
  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      print("Auth State Changed: $user"); // 디버그 메시지
      notifyListeners();
    });
  }

  // 로그인
  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = FirebaseAuth.instance.currentUser;
    print("로그인 성공");
    print(_user);
    notifyListeners(); // 로그인 후 UI에 알림
  }

  // 로그아웃
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  // 회원가입 (데이터 저장 구조 수정)
  Future<void> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'createdAt': DateTime.now(),
        'alarmDismissals': {},  // 알람 해제 기록을 저장할 필드
      });

      // 현재 사용자를 저장
      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      print('회원가입 실패: $e');
      rethrow;
    }
  }
}
