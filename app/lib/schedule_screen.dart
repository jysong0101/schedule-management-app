import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduleScreen extends StatefulWidget {
  final String userId;

  ScheduleScreen({required this.userId});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedulesForDate(DateTime.now());
  }

  Future<void> _fetchSchedulesForDate(DateTime date) async {
    final String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse(
            'http://172.30.1.12:8080/schedule?user_id=${widget.userId}&date=$formattedDate'),
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
                  // 큰 글씨로 일정 이름 표시
                  Text(
                    schedule['name'],
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // 각 정보들을 박스로 감싸서 표시
                  _buildInfoBox('설명', schedule['details'] ?? '없음'),
                  SizedBox(height: 16),
                  _buildInfoBox('시작 날짜', schedule['start_date']),
                  SizedBox(height: 16),
                  _buildInfoBox('종료 날짜', schedule['end_date']),
                  SizedBox(height: 24),

                  // 하단의 삭제 버튼
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteSchedule(schedule['id']);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('일정 삭제', style: TextStyle(fontSize: 16)),
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
        Uri.parse('http://172.30.1.12:8080/schedule/$scheduleId'),
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
                  bottom: MediaQuery.of(context).viewInsets.bottom, top: 16),
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
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            _addSchedule(
                              nameController.text,
                              startDate ?? DateTime.now(),
                              endDate ?? DateTime.now(),
                              detailsController.text,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Text('일정 추가'),
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
        Uri.parse('http://172.30.1.12:8080/schedule'),
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
        title: Text('Schedule for ${widget.userId}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
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
                titleCentered: true, // 타이틀 중앙 정렬
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
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 80.0,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: InkWell(
                              onTap: () => _showScheduleDetailsModal(schedule),
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
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
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
