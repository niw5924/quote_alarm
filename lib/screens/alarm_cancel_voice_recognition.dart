import 'package:flutter/material.dart';

class AlarmCancelVoiceRecognition extends StatelessWidget {
  final String randomWord;
  final bool isListening;
  final String lastWords;
  final String resultMessage;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const AlarmCancelVoiceRecognition({
    super.key,
    required this.randomWord,
    required this.isListening,
    required this.lastWords,
    required this.resultMessage,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "랜덤 단어: $randomWord",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isListening ? onStopListening : onStartListening,
          icon: Icon(
            isListening ? Icons.mic_off : Icons.mic,
            color: Colors.black,
          ),
          label: Text(
            isListening ? '그만하기' : '말하기',
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
          "들린 단어: $lastWords",
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (resultMessage.isNotEmpty)
          Text(
            resultMessage,
            style: TextStyle(
              fontSize: 18,
              color: (resultMessage == '정답입니다!') ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}
