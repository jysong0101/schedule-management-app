import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'todo_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class ScheduleScreen extends StatefulWidget {
  final String userId;

  ScheduleScreen({required this.userId});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _schedules = [];
  late TodoScreen todoScreen;

  @override
  void initState() {
    super.initState();
    todoScreen = TodoScreen(userId: widget.userId);
    _fetchSchedulesForDate(DateTime.now());
  }

  Future<void> _toggleCompletion(int scheduleId, bool isCompleted) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/schedule/$scheduleId/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'completed': isCompleted}),
      );

      if (response.statusCode == 200) {
        print('Schedule completion toggled successfully.');
      } else {
        print(
            'Failed to toggle schedule completion. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling schedule completion: $e');
    }
  }

  void _showMenuModal() async {
    int achievement = await _fetchAchievement();
    List<Map<String, dynamic>> priorities = await _fetchPriorities();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Achievement",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: achievement / 100,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    '$achievement%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Priorities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...priorities
                    .where((priority) => !(priority['completed'] ?? false))
                    .map((priority) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(priority['name'],
                              style: TextStyle(fontSize: 16)),
                          Text(priority['end_date'],
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(userId: widget.userId),
                        ),
                      );
                    },
                    child: Text('Settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _fetchAchievement() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/todo/today?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        int completedCount =
            data.where((item) => item['completed'] == true).length;
        return ((completedCount / data.length) * 100).floor();
      } else {
        print('Failed to fetch achievement.');
        return 0;
      }
    } catch (e) {
      print('Error fetching achievement: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPriorities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int priorityRange = prefs.getInt('selectedPriorityRange') ?? 3;
      priorityRange--;

      final response = await http.get(
        Uri.parse(
            '$baseUrl/priorities?user_id=${widget.userId}&x=$priorityRange'),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        print('Failed to fetch priorities.');
        return [];
      }
    } catch (e) {
      print('Error fetching priorities: $e');
      return [];
    }
  }

  Future<void> _fetchSchedulesForDate(DateTime date) async {
    final String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/schedule?user_id=${widget.userId}&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _schedules = data.map((item) {
            return {
              'id': item['id'],
              'name': item['name'],
              'details': item['details'],
              'start_date': item['start_date'],
              'end_date': item['end_date'],
              'completed': item['completed'],
            };
          }).toList();
        });
      } else {
        print('Failed to load schedules. Status code: ${response.statusCode}');
        setState(() {
          _schedules = [];
        });
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      setState(() {
        _schedules = [];
      });
    }
  }

  void _showScheduleDetailsModal(Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule['name'],
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  _buildInfoBox('설명', schedule['details'] ?? '없음'),
                  SizedBox(height: 16),
                  _buildInfoBox('시작 날짜', schedule['start_date']),
                  SizedBox(height: 16),
                  _buildInfoBox('종료 날짜', schedule['end_date']),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteSchedule(schedule['id']);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 214, 70, 59),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      child: Text(
                        '일정 삭제',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildInfoBox(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedule/$scheduleId'),
      );

      if (response.statusCode == 200) {
        print('Schedule deleted successfully');
        _fetchSchedulesForDate(_selectedDay ?? _focusedDay);
      } else {
        print('Failed to delete schedule. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting schedule: $e');
    }
  }

  void _showAddScheduleModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    DateTime? startDate = _selectedDay ?? _focusedDay;
    DateTime? endDate = _selectedDay ?? _focusedDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '일정 추가',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: '일정 이름'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: detailsController,
                        decoration: InputDecoration(labelText: '설명'),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '시작 날짜',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${startDate?.toLocal()}".split(' ')[0],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '종료 날짜',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${endDate?.toLocal()}".split(' ')[0],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isNotEmpty) {
                              await _addSchedule(
                                nameController.text,
                                startDate ?? DateTime.now(),
                                endDate ?? DateTime.now(),
                                detailsController.text,
                              );
                              // ToDoScreen 상태 새로고침
                              await todoScreen
                                  .fetchTodos(); // todoScreen의 fetchTodos 호출
                              Navigator.pop(context);
                            }
                          },
                          child: Text('일정 추가'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addSchedule(
      String name, DateTime startDate, DateTime endDate, String details) async {
    try {
      // 날짜만 저장하도록 포맷 변경
      String formattedStartDate =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      String formattedEndDate =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'name': name,
          'start_date': formattedStartDate,
          'end_date': formattedEndDate,
          'details': details,
          'completed': false,
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully added schedule');
        _fetchSchedulesForDate(_selectedDay ?? _focusedDay);
      } else {
        print('Failed to add schedule. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: _showMenuModal,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cached, color: Colors.black),
            onPressed: () async {
              // 화면 전환 시 ToDo 화면 새로고침
              if (_currentIndex == 0) {
                await todoScreen.fetchTodos(); // 기존 TodoScreen에서 fetchTodos 호출
              } else {
                await _fetchSchedulesForDate(_selectedDay ?? _focusedDay);
              }

              setState(() {
                _currentIndex = 1 - _currentIndex; // 화면 전환 (0 <-> 1)
              });
            },
          ),
        ],
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 첫 번째 화면: Schedule 화면
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _fetchSchedulesForDate(selectedDay);
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
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Schedules',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _schedules.isEmpty
                    ? Center(
                        child: Text(
                          'No schedules for the selected date.',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _schedules[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: 80.0,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.black),
                              ),
                              child: InkWell(
                                onTap: () =>
                                    _showScheduleDetailsModal(schedule),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(
                                        schedule['name'],
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ),
                                    Checkbox(
                                      value: schedule['completed'],
                                      onChanged: (value) {
                                        setState(() {
                                          schedule['completed'] = value!;
                                        });
                                        _toggleCompletion(
                                            schedule['id'], value!);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // 두 번째 화면: ToDo 화면
          todoScreen, // IndexedStack에 todoScreen 추가
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleModal,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
