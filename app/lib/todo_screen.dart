import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class TodoScreen extends StatefulWidget {
  final String userId;

  TodoScreen({required this.userId});

  // fetchTodos를 외부에서 호출할 수 있도록 public 메서드 추가
  Future<void> fetchTodos() async {
    final state = _TodoScreenState.currentState;
    if (state != null) {
      await state.fetchTodos();
    }
  }

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  String _selectedPeriod = 'today'; // 현재 선택된 기간 (today, week, month)
  List<Map<String, dynamic>> _todos = []; // 불러온 일정 데이터
  int _completedCount = 0; // 완료된 일정 개수
  int _totalCount = 0; // 전체 일정 개수
  static _TodoScreenState? currentState; // 현재 상태를 추적하기 위한 정적 변수
  @override
  void initState() {
    super.initState();
    currentState = this;
    fetchTodos();
  }

  @override
  void dispose() {
    currentState = null;
    super.dispose();
  }

  // API 데이터 호출 함수
  Future<void> fetchTodos() async {
    String endpoint;
    if (_selectedPeriod == 'today') {
      endpoint = '/todo/today';
    } else if (_selectedPeriod == 'week') {
      endpoint = '/todo/week';
    } else {
      endpoint = '/todo/month';
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          _todos = data;
          _completedCount =
              data.where((item) => item['completed'] == true).length;
          _totalCount = data.length;
        });
      } else {
        print('Failed to fetch todos. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching todos: $e');
    }
  }

  Future<void> _toggleCompletion(int scheduleId, bool isCompleted) async {
    try {
      print('Toggling completion for schedule ID: $scheduleId');

      final response = await http.patch(
        Uri.parse('$baseUrl/schedule/$scheduleId/toggle'), // 수정된 경로
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'completed': isCompleted}),
      );

      if (response.statusCode == 200) {
        print('Schedule completion toggled successfully.');
        // 로컬 상태 업데이트
        setState(() {
          final index = _todos.indexWhere((todo) => todo['id'] == scheduleId);
          if (index != -1) {
            _todos[index]['completed'] = isCompleted;
            _completedCount =
                _todos.where((todo) => todo['completed'] == true).length;
          }
        });
      } else if (response.statusCode == 404) {
        print('Schedule not found. ID: $scheduleId');
      } else {
        print(
            'Failed to toggle completion. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error toggling completion: $e');
    }
  }

  // 일정 상세 정보 표시
  void _showScheduleDetailsModal(Map<String, dynamic> todo) {
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
                    todo['name'],
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  _buildInfoBox('설명', todo['details'] ?? '없음'),
                  SizedBox(height: 16),
                  _buildInfoBox('시작 날짜', todo['start_date']),
                  SizedBox(height: 16),
                  _buildInfoBox('종료 날짜', todo['end_date']),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('닫기', style: TextStyle(fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    double completionRate =
        _totalCount > 0 ? _completedCount / _totalCount : 0.0;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ToDo List',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildPeriodButton('D', 'today'),
                    SizedBox(width: 8),
                    _buildPeriodButton('W', 'week'),
                    SizedBox(width: 8),
                    _buildPeriodButton('M', 'month'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completionRate,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${(completionRate * 100).floor()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: _todos.isEmpty
                  ? Center(
                      child: Text(
                        'No todos found for this period.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            onTap: () => _showScheduleDetailsModal(todo),
                            leading: Checkbox(
                              value: todo['completed'],
                              onChanged: (bool? value) {
                                if (value != null) {
                                  // 로컬 상태 즉시 업데이트
                                  setState(() {
                                    todo['completed'] = value;
                                  });

                                  // 서버로 상태 전송
                                  _toggleCompletion(todo['id'], value);
                                }
                              },
                            ),
                            title: Text(todo['name']),
                            subtitle: Text(todo['end_date']),
                            trailing: IconButton(
                              icon: Icon(Icons.timer, color: Colors.orange),
                              onPressed: () {
                                // 시계 아이콘 상호작용 (추후 구현)
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
          fetchTodos(); // 데이터 새로고침
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor:
            _selectedPeriod == period ? Colors.white : Colors.black,
        backgroundColor:
            _selectedPeriod == period ? Colors.blue : Colors.grey[300],
        shape: CircleBorder(),
        padding: EdgeInsets.all(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 14)),
    );
  }
}
