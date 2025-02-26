import 'package:flutter/material.dart';
import '../attendance_history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'attendance_page_state.dart'; // Import the new file

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _attendancePageState = AttendancePageState();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkIfUserHasCheckedIn();
  }

  Future<void> _getCurrentLocation() async {
    await _attendancePageState.getCurrentLocation(setState);
  }

  Future<void> _takePicture() async {
    await _attendancePageState.takePicture(setState);
  }

  Future<void> _checkIfUserHasCheckedIn() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await _attendancePageState.checkIfUserHasCheckedIn(userId, setState);
  }

  Future<void> _submitAttendance(String status) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await _attendancePageState.submitAttendance(
      status,
      userId,
      _attendancePageState.location,
      _attendancePageState.backup,
      context,
      setState,
    );
  }

  String getMonthName(int month) {
    return _attendancePageState.getMonthName(month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder(
              stream: Stream.periodic(
                const Duration(seconds: 1),
                (_) => DateTime.now(),
              ),
              builder: (context, snapshot) {
                DateTime currentTime = snapshot.data ?? DateTime.now();
                return Text(
                  '${currentTime.day} ${getMonthName(currentTime.month)} ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text('Location:'),
            Text(
              '${_attendancePageState.location}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _attendancePageState.image == null ? _takePicture : null,
              child: const Text('Take Selfie'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            _attendancePageState.image == null
                ? const Text('No image selected.')
                : Image.file(_attendancePageState.image!),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Backup:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                const Text('Yes'),
                Radio<bool>(
                  value: true,
                  groupValue: _attendancePageState.backup,
                  onChanged: (value) {
                    setState(() {
                      _attendancePageState.backup = value!;
                    });
                  },
                ),
                const Text('No'),
                Radio<bool>(
                  value: false,
                  groupValue: _attendancePageState.backup,
                  onChanged: (value) {
                    setState(() {
                      _attendancePageState.backup = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _attendancePageState.hasCheckedIn
                      ? null
                      : () => _submitAttendance('Masuk'),
              child: const Text('Masuk'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  !_attendancePageState.hasCheckedIn
                      ? null
                      : () => _submitAttendance('Pulang'),
              child: const Text('Pulang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
