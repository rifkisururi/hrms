import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendancePageState {
  bool backup = false;
  String location = 'Unknown';
  File? image;
  bool hasCheckedIn = false;

  Future<void> getCurrentLocation(
    void Function(void Function()) setState,
  ) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        print('Location permissions are denied');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        location = "${position.latitude}, ${position.longitude}";
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> takePicture(void Function(void Function()) setState) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });
    }
  }

  Future<void> checkIfUserHasCheckedIn(
    String? userId,
    void Function(void Function()) setState,
  ) async {
    if (userId == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existingAttendance =
        await Supabase.instance.client
            .from('attendances')
            .select()
            .eq('user_id', userId)
            .gte('check_in_time', today.toIso8601String())
            .lt('check_in_time', today.add(Duration(days: 1)).toIso8601String())
            .order('check_in_time', ascending: false)
            .limit(1)
            .single();

    setState(() {
      hasCheckedIn = existingAttendance != null;
    });
  }

  Future<void> submitAttendance(
    String status,
    String? userId,
    String location,
    bool backup,
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    try {
      if (userId == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final data = {"location": location, "backup": backup, "user_id": userId};

      if (status == 'Masuk') {
        data['check_in_time'] = now.toIso8601String();
        await Supabase.instance.client.from('attendances').insert(data);
        setState(() {
          hasCheckedIn = true; // Update state after check-in
        });
      } else if (status == 'Pulang') {
        // Check if an attendance record exists for today
        final existingAttendance =
            await Supabase.instance.client
                .from('attendances')
                .select()
                .eq('user_id', userId)
                .gte('check_in_time', today.toIso8601String())
                .lt(
                  'check_in_time',
                  today.add(Duration(days: 1)).toIso8601String(),
                )
                .order('check_in_time', ascending: false)
                .limit(1)
                .single();

        data['check_out_time'] = now.toIso8601String();

        if (existingAttendance != null) {
          // Update the existing record
          await Supabase.instance.client
              .from('attendances')
              .update(data)
              .eq('id', existingAttendance['id']);
        } else {
          // Create a new record (this should rarely happen)
          await Supabase.instance.client.from('attendances').insert(data);
        }
        setState(() {
          hasCheckedIn = false; // Update state after check-out
        });
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Attendance submitted successfully!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Error: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Unknown';
    }
  }
}
