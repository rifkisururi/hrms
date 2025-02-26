import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms/attendance_record.dart';
import 'package:hrms/config.dart';
import 'package:http/http.dart' as http;

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecord> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    final response = await http.get(Uri.parse(attendanceHistoryUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        attendanceRecords =
            data.map((e) => AttendanceRecord.fromJson(e)).toList();
      });
    } else {
      // Handle error
      print('Failed to load attendance data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = attendanceRecords[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTimeRow('Date & Time In', record.timeIn),
                  const SizedBox(height: 8),
                  _buildTimeRow('Date & Time Out', record.timeOut),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime? time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(time != null ? "${time.toLocal()}".split('.')[0] : 'N/A'),
      ],
    );
  }
}
