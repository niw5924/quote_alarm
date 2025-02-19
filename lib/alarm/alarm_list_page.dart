import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_app_2/alarm/alarm_delete_popup.dart';
import 'package:flutter_alarm_app_2/home/home_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class AlarmListPage extends StatelessWidget {
  final List<AlarmItem> alarms;
  final bool isDarkTheme;
  final Function(AlarmItem) onToggleAlarm;
  final Function(int, AlarmItem) onDeleteAlarm;
  final Function(int) onTapAlarm;

  const AlarmListPage({
    super.key,
    required this.alarms,
    required this.isDarkTheme,
    required this.onToggleAlarm,
    required this.onDeleteAlarm,
    required this.onTapAlarm,
  });

  // 알람 해제 유형을 텍스트로 변환
  String _getCancelModeText(AlarmCancelMode cancelMode) {
    switch (cancelMode) {
      case AlarmCancelMode.slider:
        return '슬라이더';
      case AlarmCancelMode.mathProblem:
        return '수학 문제';
      case AlarmCancelMode.puzzle:
        return '퍼즐';
      case AlarmCancelMode.voiceRecognition:
        return '음성 인식';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarmItem = alarms[index];
        final dateTime = alarmItem.settings.dateTime;

        // 시간 표시 포맷팅
        final formattedTime = DateFormat('a h:mm')
            .format(dateTime)
            .replaceAll('AM', '오전')
            .replaceAll('PM', '오후');

        // 알람 해제 유형 텍스트 변환
        final cancelModeText = _getCancelModeText(alarmItem.cancelMode);

        return Dismissible(
          key: UniqueKey(),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            final shouldDelete = await AlarmDeletePopup.show(context);
            return shouldDelete ?? false; // null이면 삭제 취소
          },
          onDismissed: (direction) {
            onDeleteAlarm(index, alarmItem);
          },
          child: Opacity(
            opacity: alarmItem.isEnabled ? 1.0 : 0.5,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: isDarkTheme ? Colors.grey[850] : const Color(0xFFFCFCFC),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  onTapAlarm(index);
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${formattedTime.split(' ')[0]} ',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: formattedTime.split(' ')[1],
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancelModeText,
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white70 : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        alarmItem.settings.notificationBody.isEmpty
                            ? '메모 없음'
                            : alarmItem.settings.notificationBody,
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white70 : Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: alarmItem.isEnabled,
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      onToggleAlarm(alarmItem);

                      if (value) {
                        final now = DateTime.now();
                        final alarmTime = alarmItem.settings.dateTime;

                        if (alarmTime.isAfter(now)) {
                          final difference = alarmTime.difference(now);
                          final totalMinutes =
                              (difference.inSeconds / 60).ceil();
                          final hours = totalMinutes ~/ 60;
                          final minutes = totalMinutes % 60;

                          Fluttertoast.showToast(
                            msg: hours > 0
                                ? '알람이 약 $hours시간 $minutes분 후에 울립니다.'
                                : '알람이 약 $minutes분 후에 울립니다.',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.8),
                            textColor: Colors.white,
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg: '알람 시간이 현재 시간보다 이전입니다.',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor:
                                Colors.redAccent.withValues(alpha: 0.8),
                            textColor: Colors.white,
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
