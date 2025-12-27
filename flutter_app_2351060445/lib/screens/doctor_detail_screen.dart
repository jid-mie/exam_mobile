import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key, required this.api, required this.doctorId});

  final ApiClient api;
  final int doctorId;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late Future<DoctorDetail> _future;
  String? _role;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadRole();
  }

  Future<DoctorDetail> _load() async {
    final resp = await widget.api.getJson('/api/doctors/${widget.doctorId}');
    final data = resp['data'] as Map<String, dynamic>;
    return DoctorDetail.fromJson(data);
  }

  Future<void> _loadRole() async {
    final role = await widget.api.getRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  Future<void> _book(DoctorDetail doctor) async {
    final role = await widget.api.getRole();
    if (!mounted) return;
    if (role != 'patient') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ patient mới đặt lịch')));
      return;
    }

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (time == null || !mounted) return;

    final reasonCtrl = TextEditingController(text: 'Khám sức khỏe định kỳ');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lịch'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Lý do')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    bool isAvailable = false;
    for (final s in doctor.schedules) {
      if (!s.isAvailable || s.dayOfWeek != date.weekday) continue;
      final startParts = s.startTime.split(':');
      final endParts = s.endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) continue;
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final selectedMinutes = time.hour * 60 + time.minute;
      if (selectedMinutes >= startMinutes && selectedMinutes < endMinutes) {
        isAvailable = true;
        break;
      }
    }
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bác sĩ không làm việc ngày/giờ này')));
      return;
    }

    try {
      await widget.api.postJson(
        '/api/appointments',
        auth: true,
        body: {
          'doctor_id': doctor.id,
          'appointment_date': dateStr,
          'appointment_time': timeStr,
          'reason': reasonCtrl.text.trim().isEmpty ? 'Khám' : reasonCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt lịch thành công')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _dayName(int day) {
    switch (day) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bác sĩ')),
      body: FutureBuilder<DoctorDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final d = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(d.fullName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${d.specialization} • Rating: ${d.rating.toStringAsFixed(1)}'),
              const SizedBox(height: 6),
              Text('Phí khám: ${d.consultationFee}đ'),
              if (d.phoneNumber != null) ...[
                const SizedBox(height: 6),
                Text('SĐT: ${d.phoneNumber}'),
              ],
              const SizedBox(height: 16),
              Text('Lịch làm việc', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...d.schedules.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_dayName(s.dayOfWeek)),
                  subtitle: Text('${s.startTime} - ${s.endTime}'),
                  trailing: Icon(
                    s.isAvailable ? Icons.check_circle : Icons.cancel,
                    color: s.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _role == null || _role == 'patient' ? () => _book(d) : null,
                  child: const Text('Đặt lịch'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
