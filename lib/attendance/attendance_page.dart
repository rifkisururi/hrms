import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'attendance_history_page.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? _location;
  File? _image;
  bool _isBackup = false;
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getLastAttendanceRecord();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _location =
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });
    } catch (e) {
      setState(() {
        _location = "Error getting location: ${e.toString()}";
      });
    }
  }

  Future<void> _getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _checkIn() async {
    if (_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already checked in. Please check out first.'),
        ),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to check in.')),
        );
        return;
      }

      await supabase.from('attendances').insert({
        'user_id': user.id,
        'location_checkin': _location,
        'backup': _isBackup,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_out_time': null,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isCheckedIn = true;
        _checkInTime = DateTime.now();
        _checkOutTime = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-in successful!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkOut() async {
    if (!_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have not checked in yet.')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to check out.')),
        );
        return;
      }

      // Assuming you have a way to identify the correct attendance record
      // For example, you might store the attendance ID when checking in
      // Here, I'm assuming you only have one active attendance record
      final List<dynamic> attendanceList = await supabase
          .from('attendances')
          .select()
          .eq('user_id', user.id);

      if (attendanceList.isNotEmpty) {
        final attendance = attendanceList.first;
        if (attendance['id'] != null) {
          await supabase
              .from('attendances')
              .update({
                'check_out_time': DateTime.now().toIso8601String(),
                'location_checkout': _location,
              })
              .eq('id', attendance['id'].toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance record has a null ID.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active attendance record found.')),
        );
        return;
      }

      setState(() {
        _isCheckedIn = false;
        _checkOutTime = DateTime.now();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-out successful!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-out failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _getLastAttendanceRecord() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        // User is not logged in, or session expired
        setState(() {
          _isCheckedIn = false;
          _checkInTime = null;
          _checkOutTime = null;
        });
        return;
      }

      final List<dynamic> attendanceList = await supabase
          .from('attendances')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (attendanceList.isNotEmpty) {
        final attendance = attendanceList.first;
        final checkInTime =
            attendance['check_in_time'] != null
                ? DateTime.parse(attendance['check_in_time'])
                : null;
        final checkOutTime =
            attendance['check_out_time'] != null
                ? DateTime.parse(attendance['check_out_time'])
                : null;

        setState(() {
          _isCheckedIn = checkOutTime == null && checkInTime != null;
          _checkInTime = checkInTime;
          _checkOutTime = checkOutTime;
        });
      } else {
        // No attendance record found
        setState(() {
          _isCheckedIn = false;
          _checkInTime = null;
          _checkOutTime = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(AppColors.primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  controller: TextEditingController(text: _location),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getImage,
                  child: const Text('Upload Selfie'),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.file(_image!, height: 100),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Is Backup:'),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: _isBackup,
                      onChanged: (value) {
                        setState(() {
                          _isBackup = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isCheckedIn ? null : _checkIn,
                  child: const Text('Masuk'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: !_isCheckedIn ? null : _checkOut,
                  child: const Text('Pulang'),
                ),
                // const SizedBox(height: 16),
                // if (_checkInTime != null)
                //   Text('Check In Time: ${_checkInTime.toString()}'),
                // if (_checkOutTime != null)
                //   Text('Check Out Time: ${_checkOutTime.toString()}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
