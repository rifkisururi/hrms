class AttendanceRecord {
  final DateTime? timeIn;
  final DateTime? timeOut;

  AttendanceRecord({this.timeIn, this.timeOut});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      timeIn: DateTime.tryParse(json['time_in'] ?? ''),
      timeOut: DateTime.tryParse(json['time_out'] ?? ''),
    );
  }
}
