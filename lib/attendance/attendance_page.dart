import 'package:flutter/material.dart';
import 'package:hrms/attendance/attendance_history_page.dart';
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
        backgroundColor: Color(AppColors.primaryColor),
        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
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
      backgroundColor: Color(AppColors.backgroundColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: StreamBuilder(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => DateTime.now(),
                ),
                builder: (context, snapshot) {
                  DateTime currentTime = snapshot.data ?? DateTime.now();
                  return Text(
                    '${currentTime.day} ${getMonthName(currentTime.month)} ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(AppColors.textColor),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.textColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_attendancePageState.location}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(AppColors.secondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _attendancePageState.image == null ? _takePicture : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppColors.accentColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text(
                'Take Selfie',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            _attendancePageState.image == null
                ? const Text('No image selected.')
                : Image.file(_attendancePageState.image!),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Backup:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Yes',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  Radio<bool>(
                    value: true,
                    groupValue: _attendancePageState.backup,
                    onChanged: (value) {
                      setState(() {
                        _attendancePageState.backup = value!;
                      });
                    },
                    activeColor: Color(AppColors.primaryColor),
                  ),
                  Text(
                    'No',
                    style: TextStyle(color: Color(AppColors.textColor)),
                  ),
                  Radio<bool>(
                    value: false,
                    groupValue: _attendancePageState.backup,
                    onChanged: (value) {
                      setState(() {
                        _attendancePageState.backup = value!;
                      });
                    },
                    activeColor: const Color(AppColors.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Visibility(
              visible: !_attendancePageState.hasCheckedIn,
              child: SizedBox(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed:
                          _attendancePageState.hasCheckedIn
                              ? null
                              : () => _submitAttendance('Masuk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Visibility(
                      visible: _attendancePageState.isLoading,
                      child: const CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Visibility(
              visible: _attendancePageState.hasCheckedIn,
              child: SizedBox(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                          !_attendancePageState.hasCheckedIn
                              ? null
                              : () => _submitAttendance('Pulang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text(
                        'Pulang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Visibility(
                      visible: _attendancePageState.isLoading,
                      child: const CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
