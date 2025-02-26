import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms/attendance/attendance_record.dart';
import 'package:hrms/config.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecord> attendanceRecords = [];
  int _offset = 0;
  final int _limit = 5;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _offset = 0;
      attendanceRecords.clear();
    });
    await _fetchAttendanceData();
  }

  Future<void> _loadMoreData() async {
    setState(() {
      _isLoading = true;
    });
    _offset += _limit;
    await _fetchAttendanceData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAttendanceData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('User not logged in');
      return;
    }

    final userId = user.id;

    try {
      final response = await supabase
          .from('attendances')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final List<dynamic> data = response;
      setState(() {
        attendanceRecords.addAll(
          data.map((e) => AttendanceRecord.fromJson(e)).toList(),
        );
      });
    } catch (error) {
      print('Error fetching attendance data: $error');
      print('Error type: ${error.runtimeType}');
      if (error is PostgrestException) {
        print('Postgrest error: ${error.message}');
        print('Postgrest error details: ${error.details}');
        print('Postgrest error hint: ${error.hint}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: attendanceRecords.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < attendanceRecords.length) {
            final record = attendanceRecords[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTimeRow('Date & Time In', record.checkInTime),
                    const SizedBox(height: 8),
                    _buildTimeRow('Date & Time Out', record.checkOutTime),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
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
