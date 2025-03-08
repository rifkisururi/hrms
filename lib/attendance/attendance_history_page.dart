import 'package:flutter/material.dart';
import 'package:hrms/attendance/attendance_record.dart';
import 'package:hrms/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String attendanceHistoryRouteName = '/attendance_history';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecord> attendanceRecords = [];
  int _offset = 0;
  final int _limit = 5;
  bool _isLoading = false;
  bool _hasMoreData = true;
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
    if (_isLoading || !_hasMoreData) return;

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
    setState(() {
      _isLoading = true;
    });
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
        _hasMoreData = data.length == _limit;
      });
    } catch (error) {
      print('Error fetching attendance data: $error');
      print('Error type: ${error.runtimeType}');
      if (error is PostgrestException) {
        print('Postgrest error: ${error.message}');
        print('Postgrest error details: ${error.details}');
        print('Postgrest error hint: ${error.hint}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppColors.primaryColor),
        title: const Text(
          'Attendance History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(AppColors.backgroundColor),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                return Card(
                  elevation: 3,
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
              },
            ),
          ),
          if (_hasMoreData && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _loadMoreData,
                child: const Text('Load More'),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime? time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textColor),
          ),
        ),
        Text(
          time != null ? "${time.toLocal()}".split('.')[0] : 'N/A',
          style: TextStyle(color: Color(AppColors.textColor)),
        ),
      ],
    );
  }
}
