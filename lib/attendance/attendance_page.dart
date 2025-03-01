import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:hrms/attendance/attendance_history_page.dart';
import '../config.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Import dart:io for File

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

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
      context, // Pass context
      setState,
    );
  }

  String getMonthName(int month) {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
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
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryPage(),
                  ),
                ),
          ),
        ],
      ),
      backgroundColor: Color(AppColors.backgroundColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateTimeCard(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildSelfieSection(),
            const SizedBox(height: 16),
            _buildBackupSelector(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: _commonBoxShadow,
      ),
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, snapshot) {
          final now = DateTime.now();
          return Text(
            '${now.day} ${getMonthName(now.month)} '
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}:'
            '${now.second.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 16, color: Color(AppColors.textColor)),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
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
              _attendancePageState.location,
              style: TextStyle(
                fontSize: 16,
                color: Color(AppColors.secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed:
              _attendancePageState.image == null
                  ? () async {
                    await _attendancePageState.takePicture(setState);
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(AppColors.accentColor),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text(
            'Take Selfie',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const SizedBox(height: 16),
        _attendancePageState.image != null
            ? Image.file(
              File(_attendancePageState.image!.path),
            ) // Convert XFile to File
            : Text(
              'No image selected',
              style: TextStyle(color: Color(AppColors.textColor)),
            ),
      ],
    );
  }

  Widget _buildBackupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: _commonBoxShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Backup:',
            style: TextStyle(fontSize: 16, color: Color(AppColors.textColor)),
          ),
          const SizedBox(width: 10),
          ..._buildBackupRadioButtons(),
        ],
      ),
    );
  }

  List<Widget> _buildBackupRadioButtons() {
    return ['Yes', 'No'].map((text) {
      final value = text == 'Yes';
      return Row(
        children: [
          Text(text),
          Radio<bool>(
            value: value,
            groupValue: _attendancePageState.backup,
            onChanged:
                (bool? v) => setState(() => _attendancePageState.backup = v!),
            activeColor: Color(AppColors.primaryColor),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_attendancePageState.hasCheckedIn) _buildAttendanceButton('Masuk'),
        if (_attendancePageState.hasCheckedIn) _buildAttendanceButton('Pulang'),
      ],
    );
  }

  Widget _buildAttendanceButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ElevatedButton(
            onPressed:
                _attendancePageState.isLoading
                    ? null
                    : () => _attendancePageState.submitAttendance(
                      label.toLowerCase(),
                      Supabase.instance.client.auth.currentUser?.id,
                      context,
                      setState,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          if (_attendancePageState.isLoading) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  final _commonBoxShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.3),
      spreadRadius: 2,
      blurRadius: 5,
      offset: const Offset(0, 3),
    ),
  ];
}

class AttendancePageState {
  String location = '-6.200000,106.816666';
  bool backup = true;
  bool hasCheckedIn = false;
  bool isLoading = false;
  XFile? image;

  Future<void> getCurrentLocation(
    void Function(void Function()) setState,
  ) async {
    try {
      // Implementasi get location sebenarnya
      setState(() => location = '-6.200000,106.816666');
    } catch (e) {
      print('Error getting location: $e');
      setState(() => location = '-6.200000,106.816666');
    }
  }

  Future<void> takePicture(void Function(void Function()) setState) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        image = XFile(pickedImage.path);
      });
    }
  }

  Future<void> checkIfUserHasCheckedIn(
    String? userId,
    void Function(void Function()) setState,
  ) async {
    // Implementasi check status attendance
  }

  Future<void> submitAttendance(
    String status,
    String? userId,
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    setState(() => isLoading = true);
    try {
      // Implementasi submit ke Supabase
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        hasCheckedIn = status == 'masuk';
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attendance $status successful')));
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
