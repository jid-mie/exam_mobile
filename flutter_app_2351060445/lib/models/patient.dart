class PatientItem {
  PatientItem({required this.id, required this.fullName, required this.email, required this.phone});

  final int id;
  final String fullName;
  final String email;
  final String? phone;

  factory PatientItem.fromJson(Map<String, dynamic> json) {
    return PatientItem(
      id: json['id'] as int,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone_number'] as String?,
    );
  }
}

