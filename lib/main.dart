import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_alarm_app_2/providers/auth_provider.dart';
import 'package:flutter_alarm_app_2/alarm/alarm_list_page.dart';
import 'package:flutter_alarm_app_2/settings/settings_page.dart';
import 'package:flutter_alarm_app_2/statistics/statistics_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_alarm_app_2/alarm/alarm_edit_page.dart';
import 'package:flutter_alarm_app_2/alarm/quote_screen.dart';
import 'package:flutter_alarm_app_2/services/quote_service.dart';

enum AlarmCancelMode {
  slider,
  mathProblem,
  puzzle,
  voiceRecognition,
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Alarm.init();

  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('isDarkTheme') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // AuthProvider 추가
      ],
      child: MyApp(isDarkTheme: isDarkTheme),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isDarkTheme;

  const MyApp({super.key, required this.isDarkTheme});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    _isDarkTheme = widget.isDarkTheme;
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkTheme = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkTheme
          ? ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF101317),
        scaffoldBackgroundColor: const Color(0xFF101317),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151922),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF151922),
          selectedItemColor: const Color(0xFFDDDDDD),
          unselectedItemColor: Colors.grey[700],
        ),
      )
          : ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFFFBEA),
        scaffoldBackgroundColor: const Color(0xFFFFFBEA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8EDD8),
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFFF8EDD8),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[700],
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 20),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: AlarmHomePage(onThemeToggle: _toggleTheme, isDarkTheme: _isDarkTheme),
    );
  }
}

class AlarmHomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkTheme;

  const AlarmHomePage({super.key, required this.onThemeToggle, required this.isDarkTheme});

  @override
  _AlarmHomePageState createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  List<AlarmItem> _alarms = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAlarms();

    // 알람이 울릴 때 QuoteScreen으로 이동
    Alarm.ringStream.stream.listen((alarmSettings) async {
      if (alarmSettings != null) {
        final matchingAlarm = _alarms.firstWhere(
              (alarm) => alarm.settings.id == alarmSettings.id,
          orElse: () => AlarmItem(alarmSettings, false, cancelMode: AlarmCancelMode.slider, volume: 1.0),
        );

        if (matchingAlarm.isEnabled) {
          final int startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;  // 알람 시작 시간 (초 단위)

          // 명언 가져오는 서비스
          await _showQuoteScreen(matchingAlarm.settings.id, matchingAlarm.cancelMode, matchingAlarm.volume, startTime);
        } else {
          await Alarm.stop(alarmSettings.id); // 알람 중지
        }
      }
    });
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmList = _alarms.map((alarm) {
      return '${alarm.settings.id}|${alarm.settings.dateTime.toIso8601String()}|${alarm.isEnabled}|${alarm.cancelMode.index}|${alarm.volume}|${alarm.settings.assetAudioPath}|${alarm.settings.notificationBody}';
    }).toList();
    prefs.setStringList('alarms', alarmList);
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmList = prefs.getStringList('alarms');
    if (alarmList != null) {
      setState(() {
        _alarms = alarmList.map((alarmString) {
          final parts = alarmString.split('|');
          final alarmSettings = AlarmSettings(
            id: int.parse(parts[0]),
            dateTime: DateTime.parse(parts[1]),
            assetAudioPath: parts[5],
            loopAudio: true,
            vibrate: true,
            notificationTitle: '알람',
            notificationBody: parts.length > 6 ? parts[6] : '',
            enableNotificationOnKill: true,
          );
          final isEnabled = parts[2] == 'true';
          final cancelMode = AlarmCancelMode.values[int.parse(parts[3])];
          final volume = double.parse(parts[4]); // volume 추가
          return AlarmItem(alarmSettings, isEnabled, cancelMode: cancelMode, volume: volume);
        }).toList();
      });
    }
  }

  // QuoteScreen으로 이동하는 메서드 수정 (alarmStartTime 추가)
  Future<void> _showQuoteScreen(int alarmId, AlarmCancelMode cancelMode, double volume, int alarmStartTime) async {
    final quoteService = QuoteService();
    try {
      final quote = await quoteService.fetchRandomQuote();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteScreen(
              quote: quote,
              alarmId: alarmId,
              cancelMode: cancelMode,
              volume: volume,
              alarmStartTime: alarmStartTime, // 알람 시작 시간 전달
            ),
          ),
        );
      }
    } catch (e) {
      print('명언을 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _addAlarm() async {
    final int newId = (_alarms.isNotEmpty)
        ? _alarms.map((alarm) => alarm.settings.id).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    final AlarmSettings newAlarmSettings = AlarmSettings(
      id: newId,
      dateTime: DateTime.now(),
      assetAudioPath: 'assets/sound/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      notificationTitle: '알람',
      notificationBody: '',
      enableNotificationOnKill: true,
    );

    final updatedAlarmItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditPage(alarmSettings: newAlarmSettings, cancelMode: AlarmCancelMode.slider, volume: 1.0), // volume 추가
      ),
    );

    if (updatedAlarmItem != null) {
      setState(() {
        _alarms.add(updatedAlarmItem);
      });
      _saveAlarms();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('울림소리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              widget.onThemeToggle(!widget.isDarkTheme);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAlarm,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? AlarmListPage(
        alarms: _alarms,
        isDarkTheme: widget.isDarkTheme,
        onDeleteAlarm: deleteAlarm,
        onToggleAlarm: _toggleAlarm,
        onTapAlarm: (index) async {
          final updatedAlarmItem = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlarmEditPage(
                alarmSettings: _alarms[index].settings,
                cancelMode: _alarms[index].cancelMode,
                volume: _alarms[index].volume,
              ),
            ),
          );

          if (updatedAlarmItem != null) {
            setState(() {
              _alarms[index] = updatedAlarmItem;
              _saveAlarms();
            });
          }
        },
      )
          : _selectedIndex == 1
          ? const StatisticsPage() // 통계 페이지 추가
          : SettingsPage(isDarkTheme: widget.isDarkTheme),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: '알람',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), // 통계 아이콘 추가
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _toggleAlarm(AlarmItem alarmItem) {
    setState(() {
      alarmItem.isEnabled = !alarmItem.isEnabled;
      _saveAlarms();
    });
  }

  void deleteAlarm(int index, AlarmItem alarmItem) async {
    await Alarm.stop(alarmItem.settings.id);
    setState(() {
      _alarms.removeAt(index);
    });
    _saveAlarms();
  }
}

class AlarmItem {
  AlarmSettings settings;
  bool isEnabled;
  AlarmCancelMode cancelMode;
  double volume;

  AlarmItem(this.settings, this.isEnabled, {this.cancelMode = AlarmCancelMode.slider, this.volume = 1.0});
}
