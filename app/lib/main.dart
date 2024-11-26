import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.blue),
          onPressed: () {
            // 메뉴 버튼 클릭 시 하단 메뉴 표시
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
              ),
              builder: (BuildContext context) {
                return _buildMenuPage();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 표시 및 캘린더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.grey),
                  onPressed: () {},
                ),
                Text(
                  '${_focusedDay.year}. ${_focusedDay.month.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // 캘린더 UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // Update focusedDay
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerVisible: false, // 상단 헤더 숨김
            ),
          ),
          // 스케줄 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ScheduleItem(
                  title: '과제 3 제출',
                  isCompleted: true,
                  onToggle: (value) {},
                ),
                ScheduleItem(
                  title: '과제 4 제출',
                  isCompleted: false,
                  onToggle: (value) {},
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  // 하단 메뉴 페이지 구성
  Widget _buildMenuPage() {
    return Container(
      height: 900,
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.blue),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // 추가적인 페이지 이동 처리 가능
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: Colors.green),
            title: Text('About'),
            onTap: () {
              Navigator.pop(context);
              // 추가적인 페이지 이동 처리 가능
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // 추가적인 로그아웃 처리 가능
            },
          ),
        ],
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final ValueChanged<bool?> onToggle;

  ScheduleItem({
    required this.title,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: onToggle,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
