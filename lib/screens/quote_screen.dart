import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_puzzle_vcode/flutter_puzzle_vcode.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math';

import '../providers/auth_provider.dart';
import '../services/quote_service.dart';
import '../main.dart';

class QuoteScreen extends StatefulWidget {
  final Quote quote;
  final int alarmId;
  final AlarmCancelMode cancelMode;
  final double volume;
  final int alarmStartTime;

  const QuoteScreen({
    super.key,
    required this.quote,
    required this.alarmId,
    required this.cancelMode,
    required this.volume,
    required this.alarmStartTime,
  });

  @override
  _QuoteScreenState createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  double _sliderValue = 0;
  final FlutterTts _flutterTts = FlutterTts();
  late int _firstNumber;
  late int _secondNumber;
  final TextEditingController _answerController = TextEditingController();
  String? _errorMessage;
  bool _isMathProblemGenerated = false; // 수학 문제가 생성되었는지 확인하는 플래그
  final SpeechToText _speechToText = SpeechToText();
  late String _randomWord; // 랜덤 단어 필드
  bool _isListening = false;
  String _lastWords = ''; // 실시간으로 인식된 단어
  String _resultMessage = ''; // 최종 결과 메시지

  @override
  void initState() {
    super.initState();
    _speakQuote();
    if (widget.cancelMode == AlarmCancelMode.mathProblem) {
      _generateMathProblem();
    }
    if (widget.cancelMode == AlarmCancelMode.voiceRecognition) {
      _generateRandomWord();
    }
  }

  @override
  void dispose() {
    Alarm.stop(widget.alarmId);
    _flutterTts.stop();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _speakQuote() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(widget.volume);
    await _flutterTts.speak('"${widget.quote.content}" by ${widget.quote.author}');
  }

  Future<void> _generateMathProblem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String difficulty = prefs.getString('mathDifficulty') ?? 'easy';

    final random = Random();
    setState(() {
      switch (difficulty) {
        case 'easy':
          _firstNumber = 1 + random.nextInt(10); // 한 자리수 덧셈
          _secondNumber = 1 + random.nextInt(10);
          break;
        case 'medium':
          _firstNumber = 10 + random.nextInt(90); // 두 자리수 덧셈
          _secondNumber = 10 + random.nextInt(90);
          break;
        case 'hard':
          _firstNumber = 100 + random.nextInt(900); // 세 자리수 덧셈
          _secondNumber = 100 + random.nextInt(900);
          break;
      }
      _isMathProblemGenerated = true;
    });
  }

  void _validateAnswer() {
    final answer = int.tryParse(_answerController.text);
    if (answer == _firstNumber + _secondNumber) {
      cancelAlarm();
    } else {
      setState(() {
        _errorMessage = "틀렸습니다. 다시 시도하세요!";
      });
    }
  }

  // 랜덤 단어 생성 메서드
  void _generateRandomWord() {
    const wordList = ['happy', 'nice', 'good', 'smile', 'love'];
    final random = Random();
    _randomWord = wordList[random.nextInt(wordList.length)];
  }

  // 말하기 버튼 누르기
  void _startListening() async {
    bool hasPermission = await _speechToText.initialize();
    if (!hasPermission) {
      return;
    }

    setState(() {
      _lastWords = ""; // 초기화
      _resultMessage = ""; // 결과 메시지 초기화
      _isListening = true; // 마이크 활성화 상태
    });

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() {
          _lastWords = result.recognizedWords; // 실시간으로 텍스트 업데이트
        });
      },
      listenOptions: SpeechListenOptions(
        partialResults: true, // 부분 결과 반환
      ),
      localeId: 'en-US', // 언어 설정
    );
  }

  // 그만하기 버튼 누르기
  void _stopListening() async {
    // 음성 인식 종료
    await _speechToText.stop();

    setState(() {
      _isListening = false; // 마이크 비활성화 상태
    });

    // 결과 비교
    if (_lastWords.toLowerCase() == _randomWord.toLowerCase()) {
      // 정답인 경우
      setState(() {
        _resultMessage = '정답입니다!'; // 결과 메시지 업데이트
      });

      // 1초 딜레이 후 알람 해제
      Future.delayed(const Duration(seconds: 1), () {
        cancelAlarm();
      });
    } else {
      // 틀린 경우
      setState(() {
        _resultMessage = '틀렸습니다. 다시 시도하세요.';
      });
    }
  }

  // Firebase에 알람 해제 기록을 저장하는 메서드
  Future<void> _saveAlarmDismissalRecord() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (uid != null) {
      final int endTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int duration = endTime - widget.alarmStartTime;

      // 날짜를 'yyyy-MM-dd' 형식으로 포맷팅
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'alarmDismissals': {
          formattedDate: {
            '${widget.alarmId}': {
              'cancelMode': widget.cancelMode.toString().split('.').last,
              'duration': duration,
            }
          }
        }
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 명언'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 화면을 터치하면 키보드가 닫히도록 설정
        child: Center( // Center 위젯으로 전체 Column을 감싸기
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Column의 크기를 자식 요소 크기에 맞추기
              children: [
                Text(
                  '"${widget.quote.content}"',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '- ${widget.quote.author}',
                  style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 32),
                _buildCancelModeUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelModeUI() {
    switch (widget.cancelMode) {
      case AlarmCancelMode.slider:
        return _buildSliderUI();
      case AlarmCancelMode.mathProblem:
        return _isMathProblemGenerated
            ? _buildMathProblemUI()
            : const CircularProgressIndicator();
      case AlarmCancelMode.puzzle:
        return _buildPuzzleUI();
      case AlarmCancelMode.voiceRecognition:
        return _buildVoiceRecognitionUI();
    }
  }

  Widget _buildSliderUI() {
    return Column(
      children: [
        const Text(
          'Slide to Cancel Alarm',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 150,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 50.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 30.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 30.0,
              ),
              thumbColor: Colors.white,
              activeTrackColor: const Color(0xFF6BF3B1),
              inactiveTrackColor: Colors.grey,
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 1,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });

                if (_sliderValue == 1) {
                  cancelAlarm();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMathProblemUI() {
    return Column(
      children: [
        Text(
          '$_firstNumber + $_secondNumber = ?',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            hintText: '정답을 입력하세요',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            errorText: _errorMessage,
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _validateAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6BF3B1),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '확인',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleUI() {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: true, // 다이얼로그 바깥을 터치해도 닫히지 않게 설정
          builder: (BuildContext context) {
            return FlutterPuzzleVCode(
              onSuccess: () {
                print('퍼즐 성공!');
                cancelAlarm(); // 알람 해제 로직 호출
                Navigator.pop(context); // 퍼즐 성공 후 다이얼로그 닫기
              },
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6BF3B1),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        '퍼즐 해제',
        style: TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVoiceRecognitionUI() {
    return Column(
      children: [
        Text(
          "랜덤 단어: $_randomWord", // 랜덤 단어 표시
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isListening ? _stopListening : _startListening,
          icon: Icon(
            _isListening ? Icons.mic_off : Icons.mic,
            color: Colors.black,
          ),
          label: Text(
            _isListening ? '그만하기' : '말하기',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6BF3B1),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "들린 단어: $_lastWords", // 실시간으로 들린 단어 표시
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (_resultMessage.isNotEmpty)
          Text(
            _resultMessage,
            style: TextStyle(
              fontSize: 18,
              color: (_resultMessage == '정답입니다!') ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }

  Future<void> cancelAlarm() async {
    await _saveAlarmDismissalRecord(); // 해제 기록 저장
    await Alarm.stop(widget.alarmId);
    await _flutterTts.stop();
    print('알람이 취소되었습니다.');
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
