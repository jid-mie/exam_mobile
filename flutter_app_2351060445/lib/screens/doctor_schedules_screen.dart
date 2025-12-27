import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api.dart';

class DoctorSchedulesScreen extends StatefulWidget {
  const DoctorSchedulesScreen({super.key, required this.api, required this.doctorId});

  final ApiClient api;
  final int doctorId;

  @override
  State<DoctorSchedulesScreen> createState() => _DoctorSchedulesScreenState();
}

class _DoctorSchedulesScreenState extends State<DoctorSchedulesScreen> {
  Future<List<DoctorSchedule>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchSchedules();
  }

  Future<List<DoctorSchedule>> _fetchSchedules() async {
    final resp = await widget.api.getJson('/api/doctors/${widget.doctorId}/schedules');
    final list = (resp['data'] as List).cast<Map<String, dynamic>>();
    return list.map(DoctorSchedule.fromJson).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchSchedules());
  }

  Future<void> _createSchedule() async {
    final data = await _showScheduleDialog();
    if (data == null) return;
    await widget.api.postJson('/api/doctors/${widget.doctorId}/schedules', auth: true, body: data);
    await _refresh();
  }

  Future<void> _updateSchedule(DoctorSchedule schedule) async {
    final data = await _showScheduleDialog(
      dayOfWeek: schedule.dayOfWeek,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      isAvailable: schedule.isAvailable,
    );
    if (data == null) return;
    await widget.api.putJson('/api/doctors/${widget.doctorId}/schedules/${schedule.id}', auth: true, body: data);
    await _refresh();
  }

  Future<void> _deleteSchedule(DoctorSchedule schedule) async {
    await widget.api.deleteJson('/api/doctors/${widget.doctorId}/schedules/${schedule.id}', auth: true);
    await _refresh();
  }

  Future<Map<String, dynamic>?> _showScheduleDialog({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) async {
    int selectedDay = dayOfWeek ?? 1;
    final startCtrl = TextEditingController(text: startTime ?? '09:00');
    final endCtrl = TextEditingController(text: endTime ?? '17:00');
    bool available = isAvailable ?? true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch làm việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedDay,
              decoration: const InputDecoration(labelText: 'Thứ'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Thứ 2')),
                DropdownMenuItem(value: 2, child: Text('Thứ 3')),
                DropdownMenuItem(value: 3, child: Text('Thứ 4')),
                DropdownMenuItem(value: 4, child: Text('Thứ 5')),
                DropdownMenuItem(value: 5, child: Text('Thứ 6')),
                DropdownMenuItem(value: 6, child: Text('Thứ 7')),
                DropdownMenuItem(value: 7, child: Text('Chủ nhật')),
              ],
              onChanged: (v) => selectedDay = v ?? 1,
            ),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Giờ bắt đầu (HH:mm)')),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Giờ kết thúc (HH:mm)')),
            SwitchListTile(
              value: available,
              onChanged: (v) => available = v,
              title: const Text('Đang mở'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'day_of_week': selectedDay,
                'start_time': startCtrl.text.trim(),
                'end_time': endCtrl.text.trim(),
                'is_available': available,
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Lịch làm việc')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSchedule,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<DoctorSchedule>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Chưa có lịch'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = items[index];
              return ListTile(
                title: Text('${_dayName(s.dayOfWeek)} • ${s.startTime} - ${s.endTime}'),
                subtitle: Text(s.isAvailable ? 'Đang mở' : 'Tạm nghỉ'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(onPressed: () => _updateSchedule(s), icon: const Icon(Icons.edit)),
                    IconButton(onPressed: () => _deleteSchedule(s), icon: const Icon(Icons.delete)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

