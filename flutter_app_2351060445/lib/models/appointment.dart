class AppointmentItem {
  AppointmentItem({
    required this.id,
    required this.status,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.reason,
    required this.patientName,
    required this.doctorName,
  });

  final int id;
  final String status;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String reason;
  final String? patientName;
  final String? doctorName;

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    final doctor = json['doctor'] as Map<String, dynamic>?;
    return AppointmentItem(
      id: json['id'] as int,
      status: (json['status'] as String?) ?? '',
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: (json['appointment_time'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      patientName: patient != null ? patient['full_name'] as String? : null,
      doctorName: doctor != null ? doctor['full_name'] as String? : null,
    );
  }
}

