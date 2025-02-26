class AttendanceRecord {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceRecord({this.checkInTime, this.checkOutTime});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      checkInTime: DateTime.tryParse(json['check_in_time'] ?? ''),
      checkOutTime: DateTime.tryParse(json['check_out_time'] ?? ''),
    );
  }
}
