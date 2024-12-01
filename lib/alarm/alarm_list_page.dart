import 'package:flutter/material.dart';

import '../main.dart';

class AlarmListPage extends StatelessWidget {
  final List<AlarmItem> alarms;
  final bool isDarkTheme;
  final Function(int, AlarmItem) onDeleteAlarm;
  final Function(AlarmItem) onToggleAlarm;
  final Function(int) onTapAlarm;

  const AlarmListPage({
    super.key,
    required this.alarms,
    required this.isDarkTheme,
    required this.onDeleteAlarm,
    required this.onToggleAlarm,
    required this.onTapAlarm,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarmItem = alarms[index];
        final dateTime = alarmItem.settings.dateTime;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');

        return Dismissible(
          key: UniqueKey(),
          background: Container(
            color: Colors.red,
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
          onDismissed: (direction) {
            onDeleteAlarm(index, alarmItem);
          },
          child: Opacity(
            opacity: alarmItem.isEnabled ? 1.0 : 0.5, // 알람이 꺼져있으면 투명도 0.5, 켜져있으면 1.0
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 리스트 항목 간 간격 추가
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.grey[850] : const Color(0xFFFCFCFC),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  '알람 시간: $hour:$minute',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 24,
                  ),
                ),
                subtitle: Text(
                  alarmItem.settings.notificationBody.isEmpty ? '' : alarmItem.settings.notificationBody,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: alarmItem.isEnabled,
                  onChanged: (value) {
                    onToggleAlarm(alarmItem);
                  },
                ),
                onTap: () {
                  onTapAlarm(index);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
