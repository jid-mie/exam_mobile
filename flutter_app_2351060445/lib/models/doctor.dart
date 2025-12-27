class DoctorSummary {
  DoctorSummary({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.rating,
    required this.consultationFee,
  });

  final int id;
  final String fullName;
  final String specialization;
  final double rating;
  final String consultationFee;

  factory DoctorSummary.fromJson(Map<String, dynamic> json) {
    return DoctorSummary(
      id: json['id'] as int,
      fullName: (json['full_name'] as String?) ?? '',
      specialization: (json['specialization'] as String?) ?? '',
      rating: double.tryParse((json['rating'] ?? '0').toString()) ?? 0,
      consultationFee: (json['consultation_fee'] ?? '').toString(),
    );
  }
}

class DoctorDetail {
  DoctorDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.specialization,
    required this.phoneNumber,
    required this.qualification,
    required this.experience,
    required this.consultationFee,
    required this.rating,
    required this.schedules,
  });

  final int id;
  final String fullName;
  final String email;
  final String specialization;
  final String? phoneNumber;
  final String? qualification;
  final int experience;
  final String consultationFee;
  final double rating;
  final List<DoctorSchedule> schedules;

  factory DoctorDetail.fromJson(Map<String, dynamic> json) {
    final schedulesJson = (json['doctor_schedules'] as List?) ?? const [];
    return DoctorDetail(
      id: json['id'] as int,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      specialization: (json['specialization'] as String?) ?? '',
      phoneNumber: json['phone_number'] as String?,
      qualification: json['qualification'] as String?,
      experience: (json['experience'] as int?) ?? 0,
      consultationFee: (json['consultation_fee'] ?? '').toString(),
      rating: double.tryParse((json['rating'] ?? '0').toString()) ?? 0,
      schedules: schedulesJson.map((e) => DoctorSchedule.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DoctorSchedule {
  DoctorSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: json['id'] as int,
      dayOfWeek: json['day_of_week'] as int,
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      isAvailable: (json['is_available'] as bool?) ?? true,
    );
  }
}
